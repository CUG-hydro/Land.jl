#######################################################################################################################################################################################################
#
# Changes to the function
# General
#     2022-May-24: migrate function to version v0.3
#     2022-May-24: rename the function to xylem_pressure
#
#######################################################################################################################################################################################################
"""
This function returns the xylem water pressure from pressure volume curve. The supported methods are

$(METHODLIST)

"""
function xylem_pressure end


#######################################################################################################################################################################################################
#
# Changes to the method
# General
#     2022-May-24: add method for LinearPVCurve
#
#######################################################################################################################################################################################################
"""

    xylem_pressure(pv::LinearPVCurve{FT}, rvol::FT, T::FT) where {FT<:AbstractFloat}

Return the xylem water pressure in MPa, given
- `pv` `LinearPVCurve` type pressure volume curve
- `rvol` Relative volume (relative to maximum)
- `T` Temperature
"""
xylem_pressure(pv::LinearPVCurve{FT}, rvol::FT, T::FT) where {FT<:AbstractFloat} = (rvol - 1) / pv.SLOPE;


#######################################################################################################################################################################################################
#
# Changes to the method
# General
#     2022-May-24: add method for SegmentedPVCurve
#
#######################################################################################################################################################################################################
"""

    xylem_pressure(pv::SegmentedPVCurve{FT}, rvol::FT, T::FT) where {FT<:AbstractFloat}

Return the xylem water pressure in MPa, given
- `pv` `SegmentedPVCurve` type pressure volume curve
- `rvol` Relative volume (relative to maximum)
- `T` Temperature
"""
xylem_pressure(pv::SegmentedPVCurve{FT}, rvol::FT, T::FT) where {FT<:AbstractFloat} = (
    @unpack C_ALL, RWC_APO, RWC_TLP, Ε_BULK = pv;

    if rvol > RWC_TLP
        return -C_ALL * GAS_R(FT) * T / (rvol - RWC_APO) * FT(1e-6) + Ε_BULK * (rvol - RWC_TLP)
    elseif rvol > RWC_APO
        return -C_ALL * GAS_R(FT) * T / (rvol - RWC_APO) * FT(1e-6)
    else
        return FT(-100)
    end
);


#######################################################################################################################################################################################################
#
# Changes to the function
# General
#     2022-May-27: migrate function to version v0.3
#     2022-May-27: rename the function to capacitance_buffer
#     2022-May-31: add documentation
#
#######################################################################################################################################################################################################
"""
This function returns the xylem water buffer rate from pressure volume curve. The supported methods are

$(METHODLIST)

"""
function capacitance_buffer end


#######################################################################################################################################################################################################
#
# Changes to the method
# General
#     2022-May-27: add method for LinearPVCurve
#     2022-May-31: add documentation
#
#######################################################################################################################################################################################################
"""

    capacitance_buffer(pvc::LinearPVCurve{FT}) where {FT<:AbstractFloat}

Return the relative capacictance buffer rate, given
- `pv` `LinearPVCurve` type pressure volume curve
"""
capacitance_buffer(pvc::LinearPVCurve{FT}) where {FT<:AbstractFloat} = pvc.K_REFILL;


#######################################################################################################################################################################################################
#
# Changes to the method
# General
#     2022-May-27: add method for LinearPVCurve
#     2022-May-31: add documentation
#     2022-May-31: fix documentation
#
#######################################################################################################################################################################################################
"""

    capacitance_buffer(pvc::SegmentedPVCurve{FT}) where {FT<:AbstractFloat}

Return the relative capacictance buffer rate, given
- `pv` `SegmentedPVCurve` type pressure volume curve
"""
capacitance_buffer(pvc::SegmentedPVCurve{FT}) where {FT<:AbstractFloat} = pvc.K_REFILL * (1 - pvc.RWC_APO);
