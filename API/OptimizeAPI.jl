
__precompile__(true)
module OptimizeAPI

using API
using Optimizer

import Optimizer: optimize, Constraints, LinearRestriction

optimize(symbols; 
            method::String="minvol",
            nfactors::Int=10,
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[]) = 
    Optimizer.optimize(symbols,
                method, 
                window;
                nfactors=nfactors, 
                date=getcurrentdatetime(), 
                constraints=constraints,
                initialportfolio=initialportfolio,
                linearrestrictions=linearrestrictions)

export Constraints, LinearRestriction

end

