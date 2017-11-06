__precompile__(true)
module Optimizer

using JuMP
using Ipopt
using Logger
using Utilities
using MultivariateStats

import MultivariateStats: FactorAnalysis

include("setup.jl")
include("absolutedeviation.jl")
include("minloss.jl")
include("minvol.jl")
include("meanvar.jl")
include("minnorm.jl")

#Generic optimize function
function optimize(symbols, 
                    method::String="minvol", 
                    window::Int=22;
                    targeret::Float64=0.2,
                    nfactors::Int=10,
                    date::DateTime=getcurrentdatetime(), 
                    constraints::Constraints=Constraints(),
                    initialportfolio::Vector{Float64}=Vector{Float64}(),
                    linearrestrictions::Vector{LinearRestriction}=LinearRestriction[])
                    
    
    println("LOL")

    if method=="minvol2"
        minimumvolatility_raw(symbols, 
                            window=window, 
                            date=date, 
                            constraints=constraints, 
                            initialportfolio=initialportfolio,
                            linearrestrictions=linearrestrictions)
    elseif method=="minvol"
        minimumvolatility(symbols, 
                            window=window, 
                            nfactors=nfactors,
                            date=date, 
                            constraints=constraints, 
                            initialportfolio=initialportfolio,
                            linearrestrictions=linearrestrictions)
    elseif method=="mad"
        minimumabsolutedeviation(symbols, 
                                    window=window, 
                                    date=date, 
                                    constraints=constraints, 
                                    initialportfolio=initialportfolio,
                                    linearrestrictions=linearrestrictions)
    elseif method=="masd"
        minimumabsolutesemideviation(symbols, 
                                    window=window, 
                                    date=date, 
                                    constraints=constraints, 
                                    initialportfolio=initialportfolio,
                                    linearrestrictions=linearrestrictions)
    elseif method=="minloss"
        minimumloss(symbols, 
                            window=window, 
                            date=date, 
                            constraints=constraints, 
                            initialportfolio=initialportfolio,
                            linearrestrictions=linearrestrictions)
    elseif method=="meanvar"
        meanvariance(symbols, 
                        targeret=targeret,
                        window=window, 
                        date=date, 
                        constraints=constraints, 
                        initialportfolio=initialportfolio,
                        linearrestrictions=linearrestrictions)
    elseif method=="meanvar2"
        meanvariance2(symbols, 
                        targeret=targeret,
                        window=window, 
                        date=date, 
                        constraints=constraints, 
                        initialportfolio=initialportfolio,
                        linearrestrictions=linearrestrictions)
    elseif method=="norm"
        minimumnorm(symbols,  
                        constraints=constraints, 
                        initialportfolio=initialportfolio,
                        linearrestrictions=linearrestrictions)
    else 
        return (0.0, [(symbol, 0.0) for symbol in symbols], :Unavailable)
    end
end



end # end of module
