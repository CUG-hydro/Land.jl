#######################################################################################################################################################################################################
#
# Changes to the function
# General
#     2022-May-27: add function to extract flow rate
#     2022-May-31: add method to extract flow rate from steady state flow to use with upstream flow
#     2022-May-31: add method to extract flow rate from non-steady state flow to use with upstream flow
#     2022-May-31: add method to extract flow rate from hydraulic system
#     2022-May-31: add method to extract flow rate from organ
#     2022-May-31: add method to extract flow rate from leaves
#     2022-May-31: add method to extract flow rate from branches
#     2022-Jun-30: add method to extract flow rate from Leaves1D
#     2022-Jun-30: add support for Leaves2D
#     2022-Jun-30: rename Leaf to Leaves2D to support ML*SPAC
#     2022-Jul-08: deflate documentations
#
#######################################################################################################################################################################################################
"""

    xylem_flow(organ::Union{Leaf{FT}, Leaves2D{FT}, Root{FT}, Stem{FT}}) where {FT<:AbstractFloat}
    xylem_flow(organ::Leaves1D{FT}) where {FT<:AbstractFloat}
    xylem_flow(organs::Vector{Leaves2D{FT}}) where {FT<:AbstractFloat}
    xylem_flow(organs::Vector{Stem{FT}}) where {FT<:AbstractFloat}

Return the flow rate, given
- `organ` `Leaf`, `Leaves1D`, `Leaves2D`, `Root`, or `Stem` type struct
- `organs` Vector of `Leaves2D` or `Stem` type struct

"""
function xylem_flow end

xylem_flow(organ::Union{Leaf{FT}, Leaves2D{FT}, Root{FT}, Stem{FT}}) where {FT<:AbstractFloat} = xylem_flow(organ.HS.FLOW);

xylem_flow(organ::Leaves1D{FT}) where {FT<:AbstractFloat} = (xylem_flow(organ.HS.FLOW), xylem_flow(organ.HS2.FLOW));

xylem_flow(organs::Vector{Leaves2D{FT}}) where {FT<:AbstractFloat} = (
    _f_sum::FT = 0;
    for _i in eachindex(organs)
        _f_sum += xylem_flow(organs[_i]) * organs[_i].HS.AREA;
    end;

    return _f_sum
);

xylem_flow(organs::Vector{Stem{FT}}) where {FT<:AbstractFloat} = (
    _f_sum::FT = 0;
    for _i in eachindex(organs)
        _f_sum += xylem_flow(organs[_i]);
    end;

    return _f_sum
);

xylem_flow(hs::Union{LeafHydraulics{FT}, RootHydraulics{FT}, StemHydraulics{FT}}) where {FT<:AbstractFloat} = xylem_flow(hs.FLOW);

xylem_flow(mode::SteadyStateFlow{FT}) where {FT<:AbstractFloat} = mode.flow;

xylem_flow(mode::NonSteadyStateFlow{FT}) where {FT<:AbstractFloat} = mode.f_in;


#######################################################################################################################################################################################################
#
# Changes to the function
# General
#     2022-Jul-12: add method for SteadyStateFlow mode
#     2022-Jul-12: add method for NonSteadyStateFlow mode
#     2022-Jul-12: add method for LeafHydraulics, StemHydraulics, RootHydraulics
#     2022-Jul-12: add function to update the flow rate in a hydraulic organ
#
#######################################################################################################################################################################################################
"""

    xylem_flow!(organ::Union{Leaf{FT}, Leaves2D{FT}, Root{FT}, Stem{FT}}, f::FT) where {FT<:AbstractFloat}

Return the flow rate, given
- `organ` `Leaf`, `Leaves2D`, `Root`, or `Stem` type struct

"""
function xylem_flow! end

xylem_flow!(organ::Union{Leaf{FT}, Leaves2D{FT}, Root{FT}, Stem{FT}}, f::FT) where {FT<:AbstractFloat} = xylem_flow!(organ.HS.FLOW, f);

xylem_flow!(hs::Union{LeafHydraulics{FT}, RootHydraulics{FT}, StemHydraulics{FT}}, f::FT) where {FT<:AbstractFloat} = xylem_flow!(hs.FLOW, f);

xylem_flow!(mode::SteadyStateFlow{FT}, flow::FT) where {FT<:AbstractFloat} = (mode.flow = flow; return nothing);

xylem_flow!(mode::NonSteadyStateFlow{FT}, f_in::FT) where {FT<:AbstractFloat} = (mode.f_in = f_in; return nothing);


#######################################################################################################################################################################################################
#
# Changes to the function
# General
#     2022-May-27: migrate function to new version
#     2022-May-27: add method for steady flow mode
#     2022-May-27: add method for non-steady flow mode
#     2022-May-27: add method for root hydraulic system
#     2022-May-31: add documentation
#     2022-Jul-08: add method for root organ
#     2022-Jul-08: deflate documentations
#
#######################################################################################################################################################################################################
"""

    root_pk(root::Root{FT}) where {FT<:AbstractFloat}

Return the root end pressre and total hydraulic conductance to find solution of flow rates in all roots, given
- `root` `Root` type struct

"""
function root_pk end

root_pk(root::Root{FT}) where {FT<:AbstractFloat} = root_pk(root.HS, root.t);

root_pk(hs::RootHydraulics{FT}, T::FT) where {FT<:AbstractFloat} = root_pk(hs, hs.FLOW, T);

root_pk(hs::RootHydraulics{FT}, mode::SteadyStateFlow{FT}, T::FT) where {FT<:AbstractFloat} = (
    @unpack K_MAX, K_RHIZ, N, SH, VC, ΔH = hs;

    _f_st = relative_surface_tension(T);
    _f_vis = relative_viscosity(T);
    _p_end::FT = hs.p_ups;
    _r_all::FT = 0;

    # convert pressure to that at 25 °C to compute soil water content
    _p_25 = _p_end / _f_st;

    # divide the rhizosphere component based on the conductance (each ring has the same maximum conductance)
    for _i in 1:10
        _k = relative_hydraulic_conductance(SH, true, _p_25) * K_RHIZ * 10 / _f_vis;
        _p_25 -= mode.flow / _k;
        _r_all += 1 / _k;
    end;

    # convert the end pressure back to that at liquid pressure to be matric potential
    _p_end = _p_25 * _f_st + hs.ψ_osm * T / T_25(FT);

    # compute k from temperature, history, and gravity, then update pressure
    for _i in eachindex(hs.k_history)
        _p_mem = hs.p_history[_i];
        _k_mem = hs.k_history[_i];

        _p_25 = _p_end / _f_st;
        if _p_25 < _p_mem
            _kr = relative_hydraulic_conductance(hs.VC, _p_25);
            _k = _kr / _f_vis * K_MAX * N;
        else
            _k = _k_mem / _f_vis * K_MAX * N;
        end;

        _p_end -= mode.flow / _k + ρg_MPa(FT) * ΔH / N;
        _r_all += 1 / _k;
    end;

    return _p_end, 1/_r_all
);

root_pk(hs::RootHydraulics{FT}, mode::NonSteadyStateFlow{FT}, T::FT) where {FT<:AbstractFloat} = (
    @unpack K_MAX, K_RHIZ, N, SH, VC, ΔH = hs;

    _f_st = relative_surface_tension(T);
    _f_vis = relative_viscosity(T);
    _p_end::FT = hs.p_ups;
    _r_all::FT = 0;

    # convert pressure to that at 25 °C to compute soil water content
    _p_25 = _p_end / _f_st;

    # divide the rhizosphere component based on the conductance (each ring has the same maximum conductance)
    for _i in 1:10
        _k = relative_hydraulic_conductance(SH, true, _p_25) * K_RHIZ * 10 / _f_vis;
        _p_25 -= mode.f_in / _k;
        _r_all += 1 / _k;
    end;

    # convert the end pressure back to that at liquid pressure to be matric potential
    _p_end = _p_25 * _f_st + hs.ψ_osm * T / T_25(FT);

    # compute k from temperature, history, and gravity, then update pressure
    for _i in eachindex(hs.k_history)
        _p_mem = hs.p_history[_i];
        _k_mem = hs.k_history[_i];

        _p_25 = _p_end / _f_st;
        if _p_25 < _p_mem
            _kr = relative_hydraulic_conductance(hs.VC, _p_25);
            _k = _kr / _f_vis * K_MAX * N;
        else
            _k = _k_mem / _f_vis * K_MAX * N;
        end;

        _p_end -= mode.f_element[_i] / _k + ρg_MPa(FT) * ΔH / N;
        _r_all += 1 / _k;
    end;

    return _p_end, 1/_r_all
);


#######################################################################################################################################################################################################
#
# Changes to the function
# General
#     2022-May-27: migrate function to new version
#     2022-May-27: rename the functions (flow_profile! and update_PVF!) to xylem_flow_profile!
#     2022-May-27: add method to set up root flow rate at steady state mode (this function is used to solve for steady state solution)
#     2022-May-27: add method to set up root flow rate at non-steady state mode (this function is used to solve for steady state solution)
#     2022-May-27: add method for leaf, root, and stem at steady state mode
#     2022-May-27: add method for leaf at non-steady state mode
#     2022-May-27: add method for root and stem at non-steady state mode
#     2022-May-27: add method for leaf, root, and stem hydraulic system at steady and non-steady state mode (for dispatching purpose)
#     2022-May-27: add method for leaf, root, and stem organ at steady and non-steady state mode (for dispatching purpose)
#     2022-May-27: add method to solve root flow rate partition at both steady and non-steady state modes
#     2022-May-27: add method for MonoElementSPAC (blank)
#     2022-May-31: add documentation
#     2022-May-31: remove hydraulic system from input variables, thus supporting leaf and stem
#     2022-May-31: use reformulate methods for setting up flow rate
#     2022-May-31: set up the flow rate profile using the network
#     2022-May-31: add method for MonoGrassSPAC
#     2022-May-31: add method for MonoPalmSPAC
#     2022-May-31: add method for MonoTreeSPAC
#     2022-Jun-29: rename SPAC to ML*SPAC to be more accurate
#     2022-Jun-30: add support to Leaves2D
#     2022-Jun-30: add method for Leaves1D
#     2022-Jun-30: fix documentation
#     2022-Jul-08: deflate documentations
#
#######################################################################################################################################################################################################
"""
This function is designed to serve the following functionalities:
- Update flow profile in different organs
- Partition root flow rates at different layers
- Update flow profile for entire SPAC

"""
function xylem_flow_profile! end


"""

    xylem_flow_profile!(organ::Union{Leaf{FT}, Leaves2D{FT}, Root{FT}, Stem{FT}}, Δt::FT) where {FT<:AbstractFloat}
    xylem_flow_profile!(organ::Leaves1D{FT}, Δt::FT) where {FT<:AbstractFloat}

Update organ flow rate profile after setting up the flow rate out, given
- `organ` `Leaf`, `Leaves1D`, `Leaves2D`, `Root`, or `Stem` type struct
- `Δt` Time step length

"""
xylem_flow_profile!(organ::Union{Leaf{FT}, Leaves2D{FT}, Root{FT}, Stem{FT}}, Δt::FT) where {FT<:AbstractFloat} = xylem_flow_profile!(organ.HS, organ.t, Δt);

xylem_flow_profile!(organ::Leaves1D{FT}, Δt::FT) where {FT<:AbstractFloat} = (
    @unpack HS, HS2 = organ;

    xylem_flow_profile!(HS, organ.t[1], Δt);
    xylem_flow_profile!(HS2, organ.t[2], Δt);

    return nothing
);

xylem_flow_profile!(hs::Union{LeafHydraulics{FT}, RootHydraulics{FT}, StemHydraulics{FT}}, T::FT, Δt::FT) where {FT<:AbstractFloat} = xylem_flow_profile!(hs, hs.FLOW, T, Δt);

xylem_flow_profile!(hs::Union{LeafHydraulics{FT}, RootHydraulics{FT}, StemHydraulics{FT}}, mode::SteadyStateFlow{FT}, T::FT, Δt::FT) where {FT<:AbstractFloat} = nothing;

xylem_flow_profile!(hs::LeafHydraulics{FT}, mode::NonSteadyStateFlow{FT}, T::FT, Δt::FT) where {FT<:AbstractFloat} = (
    @unpack PVC, V_MAXIMUM = hs;

    _f_vis = relative_viscosity(T);

    # compute the flow rate from capacitance buffer
    mode.f_buffer[1] = (hs.p_storage - hs.p_leaf) * capacitance_buffer(PVC) / _f_vis * V_MAXIMUM;

    # make sure the buffer rate does not drain or overflow the capacictance
    if (mode.f_buffer[1] > 0) && (hs.v_storage <= mode.f_buffer[1] * Δt)
        mode.f_buffer[1] = (hs.v_storage - eps(FT)) / Δt;
    end;

    # update storage and the tissue pressure (p_storage)
    hs.v_storage -= mode.f_buffer[1] * Δt;
    hs.p_storage = xylem_pressure(PVC, hs.v_storage/V_MAXIMUM, T);

    # update flow into the tissue
    mode.f_in = mode.f_out - mode.f_buffer[1];

    return nothing
);

xylem_flow_profile!(hs::Union{RootHydraulics{FT}, StemHydraulics{FT}}, mode::NonSteadyStateFlow{FT}, T::FT, Δt::FT) where {FT<:AbstractFloat} = (
    @unpack N, PVC, V_MAXIMUM = hs;

    _f_vis = relative_viscosity(T);

    # update storage volume and pressure per slice
    _f_sum::FT = 0;
    for _i in N:-1:1
        mode.f_buffer[_i] = (hs.p_storage[_i] - hs.p_element[_i]) * capacitance_buffer(PVC) / _f_vis * V_MAXIMUM[_i];

        # make sure the buffer rate does not drain or overflow the capacictance
        if (mode.f_buffer[_i] > 0) && (hs.v_storage[_i] <= mode.f_buffer[_i] * Δt)
            mode.f_buffer[_i] = hs.v_storage[_i] / Δt;
        end;

        mode.f_sum[_i] = _f_sum;
        hs.v_storage[_i] -= mode.f_buffer[_i] * Δt;
        hs.p_storage[_i] = xylem_pressure(PVC, hs.v_storage[_i]/V_MAXIMUM[_i], T);
        mode.f_element[_i] = mode.f_out - _f_sum;
        _f_sum += mode.f_buffer[_i];
    end;

    # update flow into the tissue
    mode.f_in = mode.f_out - _f_sum;

    return nothing
);


"""

    xylem_flow_profile!(roots::Vector{Root{FT}}, cache_f::Vector{FT}, cache_k::Vector{FT}, cache_p::Vector{FT}, f_sum::FT, Δt::FT) where {FT<:AbstractFloat}

Partition root flow rates at different layers for known total flow rate out, given
- `roots` Vector of `Root` in a multiple roots system
- `cache_f` Flow rate cache into each root
- `cache_k` Total conductance cache of each root
- `cache_p` Root xylem end pressure cache of each root
- `f_sum` Total flow rate out of the roots
- `Δt` Time step length

"""
xylem_flow_profile!(roots::Vector{Root{FT}}, cache_f::Vector{FT}, cache_k::Vector{FT}, cache_p::Vector{FT}, f_sum::FT, Δt::FT) where {FT<:AbstractFloat} = (
    # update root buffer rates to get an initial guess (flow rate not changing now as time step is set to 0)
    xylem_flow_profile!.(roots, FT(0));

    # recalculate the flow profiles to make sure sum are the same as f_sum
    _count = 0;
    while _count < 20
        # sync the values to ks, ps, and qs
        for _i in eachindex(roots)
            _root = roots[_i];
            xylem_flow_profile!(roots[_i].HS.FLOW, cache_f[_i]);
            cache_p[_i],cache_k[_i] = root_pk(_root);
        end;

        # use ps and ks to compute the Δf to adjust
        _pm = mean(cache_p);
        for _i in eachindex(roots)
            cache_f[_i] -= (_pm - cache_p[_i]) * cache_k[_i];
        end;

        # adjust the fs so that sum(fs) = f_sum
        _f_diff = sum(cache_f) - f_sum;
        if (abs(_f_diff) < FT(1e-6)) && (maximum(cache_p) - minimum(cache_p) < 1e-4)
            break
        end;
        _k_sum  = sum(cache_k);
        for _i in eachindex(roots)
            cache_f[_i] -= _f_diff * cache_k[1] / _k_sum;
        end;
    end;

    # update root buffer rates again
    for _i in eachindex(roots)
        xylem_flow_profile!(roots[_i].HS.FLOW, cache_f[_i]);
    end;
    xylem_flow_profile!.(roots, Δt);

    return nothing
);

xylem_flow_profile!(mode::SteadyStateFlow, flow::FT) where {FT<:AbstractFloat} = (mode.flow = flow; return nothing);

xylem_flow_profile!(mode::NonSteadyStateFlow, f_out::FT) where {FT<:AbstractFloat} = (mode.f_out = f_out; mode.f_element .= f_out .- mode.f_sum; return nothing);


"""

    xylem_flow_profile!(spac::MonoElementSPAC{FT}, Δt::FT) where {FT<:AbstractFloat}
    xylem_flow_profile!(spac::MonoMLGrassSPAC{FT}, Δt::FT) where {FT<:AbstractFloat}
    xylem_flow_profile!(spac::MonoMLPalmSPAC{FT}, Δt::FT) where {FT<:AbstractFloat}
    xylem_flow_profile!(spac::MonoMLTreeSPAC{FT}, Δt::FT) where {FT<:AbstractFloat}

Update flow profiles for the soil-plant-air continuum (after setting up leaf flow rate), given
- `spac` `MonoElementSPAC`, `MonoMLGrassSPAC`, `MonoMLPalmSPAC`, or `MonoMLTreeSPAC` type SPAC system
- `Δt` Time step length

"""
xylem_flow_profile!(spac::MonoElementSPAC{FT}, Δt::FT) where {FT<:AbstractFloat} = (
    @unpack LEAF, ROOT, STEM = spac;

    # 1. update the leaf flow profile
    xylem_flow_profile!(LEAF, Δt);

    # 2. set up stem flow rate and profile
    xylem_flow_profile!(STEM.HS.FLOW, xylem_flow(LEAF) * LEAF.HS.AREA);
    xylem_flow_profile!(STEM, Δt);

    # 3. set up root flow rate and profile
    xylem_flow_profile!(ROOT.HS.FLOW, xylem_flow(STEM));
    xylem_flow_profile!(STEM, Δt);

    return nothing
);

xylem_flow_profile!(spac::MonoMLGrassSPAC{FT}, Δt::FT) where {FT<:AbstractFloat} = (
    @unpack LEAVES, ROOTS = spac;

    # 1. update the leaf flow profile
    xylem_flow_profile!.(LEAVES, Δt);

    # 2. set up root flow rate and profile
    _f_sum = xylem_flow(LEAVES);
    xylem_flow_profile!(ROOTS, spac._fs, spac._ks, spac._ps, _f_sum, Δt);

    return nothing
);

xylem_flow_profile!(spac::MonoMLPalmSPAC{FT}, Δt::FT) where {FT<:AbstractFloat} = (
    @unpack LEAVES, ROOTS, TRUNK = spac;

    # 1. update the leaf flow profile
    xylem_flow_profile!.(LEAVES, Δt);

    # 2. set up trunk flow rate and profile
    xylem_flow_profile!(TRUNK.HS.FLOW, xylem_flow(LEAVES));
    xylem_flow_profile!(TRUNK, Δt);

    # 3. set up root flow rate and profile
    xylem_flow_profile!(ROOTS, spac._fs, spac._ks, spac._ps, xylem_flow(TRUNK), Δt);

    return nothing
);

xylem_flow_profile!(spac::MonoMLTreeSPAC{FT}, Δt::FT) where {FT<:AbstractFloat} = (
    @unpack BRANCHES, LEAVES, ROOTS, TRUNK = spac;

    # 1. update the leaf flow profile
    xylem_flow_profile!.(LEAVES, Δt);

    # 2. set up branch flow rate and profile
    for _i in eachindex(LEAVES)
        xylem_flow_profile!(BRANCHES[_i].HS.FLOW, xylem_flow(LEAVES[_i]) * LEAVES[_i].HS.AREA);
    end;
    xylem_flow_profile!.(BRANCHES, Δt);

    # 3. set up trunk flow rate and profile
    xylem_flow_profile!(TRUNK.HS.FLOW, xylem_flow(BRANCHES));
    xylem_flow_profile!(TRUNK, Δt);

    # 4. set up root flow rate and profile
    xylem_flow_profile!(ROOTS, spac._fs, spac._ks, spac._ps, xylem_flow(TRUNK), Δt);

    return nothing
);
