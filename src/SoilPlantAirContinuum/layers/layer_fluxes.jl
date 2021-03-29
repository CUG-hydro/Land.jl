###############################################################################
#
# Update carbon and water fluxes
#
# TODO: work more to make this function more customized
#
###############################################################################
"""
    layer_fluxes!(
                node::SPACMono{FT};
                updating::Bool = false
    ) where {FT<:AbstractFloat}

Run carbon, water, energy, and SIF fluxes for all canopy layers, given
- `node` [`SPACMono`](@ref) type struct
- `updating` If true, update cavitation history
"""
function layer_fluxes!(
            node::SPACMono{FT};
            updating::Bool = false
) where {FT<:AbstractFloat}
    # 0.1 unpack data
    @unpack angles, can_opt, can_rad, canopy_rt, envirs, f_SL, ga, in_rad,
            leaves_rt, n_canopy, photo_set, plant_hs, plant_ps, rt_con, rt_dim,
            soil_opt, stomata_model, wl_set = node;
    @unpack nAzi, nIncl = canopy_rt;
    nSL = nAzi * nIncl;

    canopy_geometry!(canopy_rt, angles, can_opt, rt_con);
    canopy_matrices!(leaves_rt, can_opt);
    short_wave!(canopy_rt, can_opt, can_rad, in_rad, soil_opt, rt_con);
    canopy_fluxes!(canopy_rt, can_opt, can_rad, in_rad, soil_opt, leaves_rt,
                   wl_set, rt_con);

    #
    f_H₂O = 0;
    f_GPP = 0;
    f_NPP = 0;
    for i_can in 1:n_canopy
        iEN = envirs[i_can];
        iHS = plant_hs.leaves[i_can];
        iPS = plant_ps[i_can];
        iRT = n_canopy + 1 - i_can;

        iPS.T = can_rad.T_sun[i_can];
        update_leaf_TP!(photo_set, iPS, iHS, iEN);
        temperature_effects!(iHS, iPS.T);

        # calculate the fraction of sunlit and shaded leaves
        f_view = (can_opt.Ps[iRT] + can_opt.Ps[iRT+1]) / 2;
        for iLF in 1:nSL
            iPS.APAR[iLF] = can_rad.absPAR_sunCab[(iRT-1)*nSL+iLF] * FT(1e6);
            iPS.LAIx[iLF] = f_view * f_SL[iLF];
        end
        iPS.APAR[end] = can_rad.absPAR_shadeCab[iRT] * FT(1e6);
        iPS.LAIx[end] = 1 - f_view;

        # iterate for N times until sum(iPS.Ag) does not change any more
        sum_ag_last = sum(iPS.Ag);
        count       = 0;
        while true
            # calculate the photosynthetic rates
            count += 1;
            gas_exchange!(photo_set, iPS, iEN, GswDrive());
            if typeof(stomata_model) <: EmpiricalStomatalModel
                #
                #
                #
                #
                # also need to determine which β function is used
                #     to tune g1
                #     to tune Vcmax
                #
                #
                #
                #
                prognostic_gsw!(iPS, iEN, stomata_model, FT(1), FT(120));
            else
                prognostic_gsw!(photo_set, iPS, iHS, iEN, stomata_model,
                                FT(120));
            end
            gsw_control!(photo_set, iPS, iEN);
            sum_ag_curr = sum(iPS.Ag);
            if (abs(sum_ag_curr - sum_ag_last) < 0.01) || count > 1000
                break
            else
                sum_ag_last = sum_ag_curr;
            end
        end

        # update the fluorescence quantum yield from leaf level calculation
        can_rad.ϕ_sun[:,:,iRT] .= reshape(view(iPS.ϕs,1:nSL), nIncl, nAzi);
        can_rad.ϕ_shade[iRT] = iPS.ϕs[end];

        # update the flow rates
        for iLF in 1:(nSL+1)
            f_GPP += iPS.Ag[iLF] * iPS.LAIx[iLF] * iPS.LA;
            f_NPP += iPS.An[iLF] * iPS.LAIx[iLF] * iPS.LA;
            f_H₂O += iPS.g_lw[iLF] * (iPS.p_sat - iEN.p_H₂O) / iEN.p_atm *
                     iPS.LAIx[iLF] * iPS.LA;
        end
    end

    # do SIF simulation
    SIF_fluxes!(leaves_rt, can_opt, can_rad, canopy_rt, soil_opt,
                wl_set, rt_con, rt_dim);

    # update flow profile and pressure history along the tree
    if updating
        for i_can in 1:n_canopy
            iEN = envirs[i_can];
            iLF = plant_hs.leaves[i_can];
            iPS = plant_ps[i_can];
            iST = plant_hs.branch[i_can];
            iLF.flow = sum(iPS.g_lw .* iPS.LAIx) *
                       (iPS.p_sat - iEN.p_H₂O) / iEN.p_atm;
            iST.flow = iLF.flow * iPS.LA;
        end
        plant_hs.trunk.flow = sum([iST.flow for iST in plant_hs.branch]);
        for iRT in plant_hs.roots
            iRT.flow = plant_hs.trunk.flow / length(plant_hs.roots);
        end
        pressure_profile!(plant_hs, SteadyStateMode(); update=true);
    end

    # update the flows in SPACMono
    node.f_gpp = f_GPP / ga;
    node.f_npp = f_NPP / ga;
    node.f_H₂O = f_H₂O / ga;

    return nothing
end
