#######################################################################################################################################################################################################
#
# Changes to this function
# General
#     2022-Jun-13: add function to interpolate the spectrum
#
#######################################################################################################################################################################################################
"""
This function interpolate the spectrum to give values at the target wavelength bin(s). The supported methods include

$(METHODLIST)

"""
function read_spectrum end


#######################################################################################################################################################################################################
#
# Changes to this method
# General
#     2022-Jun-13: add method to interpolate the spectrum
#
#######################################################################################################################################################################################################
"""

    read_spectrum(x::Vector{FT}, y::Vector{FT}, target::FT) where {FT<:AbstractFloat}

Return the spectrum value at target wavelength bin, given
- `x` X-axis of the spectrum
- `y` Y-axis of the spectrum
- `target` Target x value
"""
read_spectrum(x::Vector{FT}, y::Vector{FT}, target::FT) where {FT<:AbstractFloat} = (
    @assert length(x) == length(y) "Dimensions of provided spectrum x and y must match!";
    @assert x[1] <= target <= x[end] "Target wavelength must be within the range provided spectum!";

    # iterate through the spectrum and find the index
    _ind = 0;
    for _i in 1:length(x)-1
        if x[_i] <= target <= x[_i+1]
            _ind = _i;
            break;
        end;
    end;

    return ((x[_ind+1] - target) * y[_ind] + (target - x[_ind]) * y[_ind+1]) / (x[_ind+1] - x[_ind])
);


#######################################################################################################################################################################################################
#
# Changes to this method
# General
#     2022-Jun-13: add method to interpolate the spectrum via multiple steps
#
#######################################################################################################################################################################################################
"""

    read_spectrum(x::Vector{FT}, y::Vector{FT}, x₁::FT, x₂::FT; steps::Int = 2) where {FT<:AbstractFloat}

Return the spectrum value at target wavelength bin, given
- `x` X-axis of the spectrum
- `y` Y-axis of the spectrum
- `x₁` Lower x boundary
- `x₂` Upper x boundary
- `steps` The incremental Δx is `(x₂ - x₁) / steps`
"""
read_spectrum(x::Vector{FT}, y::Vector{FT}, x₁::FT, x₂::FT; steps::Int = 2) where {FT<:AbstractFloat} = (
    _xs = collect(FT,range(x₁, x₂; length=steps+1));
    _ys = read_spectrum.([x], [y], _xs);

    return mean(_ys)
);


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute MODIS EVI
#
#######################################################################################################################################################################################################
"""

    MODIS_EVI(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return EVI for MODIS setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function MODIS_EVI(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    _blue = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_3[1]), FT(MODIS_BAND_3[2]); steps=4);
    _red  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_1[1]), FT(MODIS_BAND_1[2]); steps=6);
    _nir  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_2[1]), FT(MODIS_BAND_2[2]); steps=6);

    return FT(2.5) * (_nir - _red) / (_nir + 6 * _red - FT(7.5) * _blue + 1)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute MODIS EVI2#     2022-Jun-13: add function to compute MODIS EVI

#
#######################################################################################################################################################################################################
"""

    MODIS_EVI2(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return EVI2 for MODIS setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function MODIS_EVI2(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    _red  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_1[1]), FT(MODIS_BAND_1[2]); steps=6);
    _nir  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_2[1]), FT(MODIS_BAND_2[2]); steps=6);

    return FT(2.5) * (_nir - _red) / (_nir + FT(2.4) * _red + 1)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute MODIS LSWI
#
#######################################################################################################################################################################################################
"""

    MODIS_LSWI(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return LSWI for MODIS setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function MODIS_LSWI(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    _nir  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_2[1]), FT(MODIS_BAND_2[2]); steps=5);
    _swir = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_7[1]), FT(MODIS_BAND_7[2]); steps=5);

    return (_nir - _swir) / (_nir + _swir)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute MODIS NDVI
#
#######################################################################################################################################################################################################
"""

    MODIS_NDVI(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return NDVI for MODIS setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function MODIS_NDVI(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    _red  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_1[1]), FT(MODIS_BAND_1[2]); steps=6);
    _nir  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_2[1]), FT(MODIS_BAND_2[2]); steps=6);

    return (_nir - _red) / (_nir + _red)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute MODIS NIRv
#
#######################################################################################################################################################################################################
"""

    MODIS_NIRv(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return NIRv for MODIS setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function MODIS_NIRv(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    _red  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_1[1]), FT(MODIS_BAND_1[2]); steps=6);
    _nir  = read_spectrum(WLSET.Λ, RADIATION.albedo, FT(MODIS_BAND_2[1]), FT(MODIS_BAND_2[2]); steps=6);

    return (_nir - _red) / (_nir + _red) * _nir
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute OCO2 SIF @ 758.7 nm
#
#######################################################################################################################################################################################################
"""

    OCO2_SIF759(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 759 nm for OCO2 setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function OCO2_SIF759(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(OCO2_SIF_759[1]), FT(OCO2_SIF_759[2]); steps=4)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute OCO2 SIF @ 770.0 nm
#
#######################################################################################################################################################################################################
"""

    OCO2_SIF770(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 770 nm for OCO2 setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function OCO2_SIF770(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(OCO2_SIF_770[1]), FT(OCO2_SIF_770[2]); steps=4)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute OCO3 SIF @ 758.8 nm
#
#######################################################################################################################################################################################################
"""

    OCO3_SIF759(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 759 nm for OCO3 setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function OCO3_SIF759(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(OCO3_SIF_759[1]), FT(OCO3_SIF_759[2]); steps=4)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute OCO3 SIF @ 770.0 nm
#
#######################################################################################################################################################################################################
"""

    OCO3_SIF770(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 770 nm for OCO3 setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function OCO3_SIF770(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(OCO3_SIF_770[1]), FT(OCO3_SIF_770[2]); steps=4)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute TROPOMI SIF @ 682.5 nm
#     2022-Jun-13: change the default steps
#
#######################################################################################################################################################################################################
"""

    TROPOMI_SIF683(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 682.5 nm for TROPOMI setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function TROPOMI_SIF683(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(TROPOMI_SIF_683[1]), FT(TROPOMI_SIF_683[2]); steps=5)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute TROPOMI SIF @ 740.0 nm
#
#######################################################################################################################################################################################################
"""

    TROPOMI_SIF740(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 740 nm for TROPOMI setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function TROPOMI_SIF740(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(740))
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute TROPOMI SIF @ 746.5 nm
#     2022-Jun-13: change the default steps
#
#######################################################################################################################################################################################################
"""

    TROPOMI_SIF747(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 746.5 nm for TROPOMI setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function TROPOMI_SIF747(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(TROPOMI_SIF_747[1]), FT(TROPOMI_SIF_747[2]); steps=8)
end


#######################################################################################################################################################################################################
#
# Changes to these functions
# General
#     2022-Jun-13: add function to compute TROPOMI SIF @ 750.5 nm
#     2022-Jun-13: change the default steps
#
#######################################################################################################################################################################################################
"""

    TROPOMI_SIF751(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}

Return SIF @ 750.5 nm for TROPOMI setup, given
- `can` `HyperspectralMLCanopy` type canopy
"""
function TROPOMI_SIF751(can::HyperspectralMLCanopy{FT}) where {FT<:AbstractFloat}
    @unpack RADIATION, WLSET = can;

    return read_spectrum(WLSET.Λ_SIF, RADIATION.sif_obs, FT(TROPOMI_SIF_751[1]), FT(TROPOMI_SIF_751[2]); steps=5)
end
