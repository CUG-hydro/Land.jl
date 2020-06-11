#### Use Julia Plots package and switch to plotly js option:
using Plots
using StatsPlots
pyplot()

##----------------------------------------------------------------------------

# First, we include Revise (good for debugging) and Parameters (tools for structures)

##using Revise
using Parameters
using Statistics
using CSV
using DataStructures

##----------------------------------------------------------------------------
using LinearAlgebra

# The hyperspectral wavelengths
WVL = 400:10:2501
# The general spectral vectors derived in the manuscript
GSV = [CSV.read("DryVec.csv"; header=false);CSV.read("SMVec.csv"; header=false)]
# The test hyperspectral data
hyper = CSV.read("TestSpectrum_v1.csv";header=false)
# The wavelengths of multispectral data
wvl = [450,550,650,850,1650,2150]
# The test multispectral data sliced from hyperspectral data
indices = []

for i in wvl
    push!(indices, findall(x -> x==i, WVL)[1])
end

multi = hyper[:,indices]


# Step 1: slice GSV according to the wavelengths of multispectral data
gsv = GSV[:,indices]

# Step 2: fit multispectral soil reflectance and reconstruct multispectral soil reflectance
X=convert(Matrix,multi)
V=convert(Matrix,gsv)
C = X * LinearAlgebra.pinv(V)
R = C * V
R[R.<0] .= 0
R[R.>1] .= 1

scatter(X,R,label="")
plot!([0,0.4],[0,0.4],label="")
ylabel!("Simulations")
xlabel!("Measurements")

# Step 3: reconstruct hyperspectral soil reflectance using coefficients fitted from multispectral data
X = convert(Matrix,hyper)
V = convert(Matrix,GSV)
R = C * V
R[R.<0] .= 0
R[R.>1] .= 1

scatter(X,R,label="")
plot!([0,0.4],[0,0.4],label="")
ylabel!("Simulations")
xlabel!("Measurements")

# Compare measured multispectral data and hyperspectral data with reconstructed ones
plot(WVL,transpose(convert(Matrix,hyper)),label="Actual hyperspectral reflectance")
scatter!(wvl,transpose(Matrix(multi)),label="Observed multispectral reflectance")
plot!(WVL,transpose(R),label="Simulated hyperspectral reflectance\nfitted from multispectral reflectance")
ylabel!("Soil albedo")
xlabel!("wl (nm)")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

