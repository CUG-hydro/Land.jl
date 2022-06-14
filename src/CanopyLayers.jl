module CanopyLayers

using LazyArtifacts

using ClimaCache: HyperspectralRadiation, LeafBiophysics, SunSensorGeometry
using ConstrainedRootSolvers: ReduceStepMethodND, SolutionToleranceND, find_peak
using DocStringExtensions: TYPEDFIELDS, TYPEDEF
using LinearAlgebra: mul!, pinv
using MAT: matread
using PkgUtility: AVOGADRO, H_PLANCK, K_STEFAN, LIGHT_SPEED, T_25, numerical∫, read_csv
using QuadGK: quadgk
using SpecialFunctions: expint
using Statistics: mean
using UnPack: @unpack




# define the constants
const FILE_SUN  = artifact"land_model_spectrum_V1" * "/sun.mat";
const OPTI_2017 = artifact"land_model_spectrum_V1" * "/Optipar2017_ProspectD.mat";
const OPTI_2021 = artifact"land_model_spectrum_V1" * "/Optipar2021_ProspectPRO_CX.mat";
const SOIL_BNDS = [0.36 0.61 0.25 0.50;
                   0.34 0.57 0.23 0.46;
                   0.32 0.53 0.21 0.42;
                   0.31 0.51 0.20 0.40;
                   0.30 0.49 0.19 0.38;
                   0.29 0.48 0.18 0.36;
                   0.28 0.45 0.17 0.34;
                   0.27 0.43 0.16 0.32;
                   0.26 0.41 0.15 0.30;
                   0.25 0.39 0.14 0.28;
                   0.24 0.37 0.13 0.26;
                   0.23 0.35 0.12 0.24;
                   0.22 0.33 0.11 0.22;
                   0.20 0.31 0.10 0.20;
                   0.18 0.29 0.09 0.18;
                   0.16 0.27 0.08 0.16;
                   0.14 0.25 0.07 0.14;
                   0.12 0.23 0.06 0.12;
                   0.10 0.21 0.05 0.10;
                   0.08 0.16 0.04 0.08];
const SOIL_GSV  = artifact"land_model_spectrum_V1" * "/GSV.csv";




# export public types
export Canopy4RT, CanopyOpticals, CanopyRads, RTCache, RTDimensions, SoilOpticals, WaveLengths

# export public functions
export big_leaf_partition

# Vegetation indices
export BLUE, EVI, EVI2, LSWI, NDVI, NIR, NIRv, NIRvES, RED, REF_WL, SIF_683, SIF_740, SIF_757, SIF_771, SIF_WL, SWIR


include("utils/e2phot.jl")

include("types/canopy4rt.jl"     )
include("types/canopyopticals.jl")
include("types/canopyrads.jl"    )
include("types/caches.jl"        )
include("types/rtdims.jl"        )
include("types/wavelength.jl"    )
include("types/soilopticals.jl"  )

include("bigleaf/bigleaf.jl")

include("layers/indicies.jl")
include("layers/soil.jl"    )




end # module
