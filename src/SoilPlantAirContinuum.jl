module SoilPlantAirContinuumNew

using CanopyRadiativeTransfer: canopy_radiation!
using ClimaCache: AirLayer, GCO₂Mode, MonoMLTreeSPAC
using Photosynthesis: leaf_photosynthesis!
using PlantHydraulics: xylem_flow_profile!, xylem_pressure_profile!
using StomataModels: stomatal_conductance!
using WaterPhysics: saturation_vapor_pressure


include("model.jl" )
include("update.jl")


end # module
