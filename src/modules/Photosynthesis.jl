module Photosynthesis

using PkgUtility: lower_quadratic, upper_quadratic
using UnPack: @unpack

using ..EmeraldConstants: F_O₂, GAS_R
using ..ClimaCache: CytochromeReactionCenter, VJPReactionCenter, VanDerTolFluorescenceModel
using ..ClimaCache: Arrhenius, ArrheniusPeak, C3VJPModel, C3CytochromeModel, C4VJPModel, GCO₂Mode, PCO₂Mode, Q10, Q10Peak
using ..ClimaCache: MinimumColimit, QuadraticColimit, SerialColimit, SquareColimit
using ..ClimaCache: AndereggSM, BallBerrySM, BetaFunction, BetaParameterG1, BetaParameterVcmax, EllerSM, GentineSM, LeuningSM, MedlynSM, SperrySM, WangSM, Wang2SM
using ..ClimaCache: AirLayer, Leaf, Leaves1D, Leaves2D
using ..ClimaCache: MonoElementSPAC, MonoMLGrassSPAC, MonoMLPalmSPAC, MonoMLTreeSPAC


include("../../packages/Photosynthesis.jl/src/colimit.jl"        )
include("../../packages/Photosynthesis.jl/src/etr.jl"            )
include("../../packages/Photosynthesis.jl/src/fluorescence.jl"   )
include("../../packages/Photosynthesis.jl/src/light_limited.jl"  )
include("../../packages/Photosynthesis.jl/src/model.jl"          )
include("../../packages/Photosynthesis.jl/src/product_limited.jl")
include("../../packages/Photosynthesis.jl/src/rubisco_limited.jl")
include("../../packages/Photosynthesis.jl/src/temperature.jl"    )


end # module
