module Land

using DiffEqOperators
using OrdinaryDiffEq

using WaterPhysics: TraceGasAir, TraceGasCO₂, diffusive_coefficient


# include types
include("Land/Types.jl"    )
include("Land/AirLayers.jl")


end # module
