
__precompile__(true)
module OptimizeAPI

using API
using Optimizer

import Optimizer: optimize, Constraints, LinearRestriction

optimize(symbols; 
            method::String="minvol",
            targetret::Float64=0.2,
            nfactors::Int=10,
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
            cholesky=false,
            riskaversion=1.0) = 
    Optimizer.optimize(symbols,
                method, 
                window;
                targetret=targetret, 
                nfactors=nfactors,
                date=getcurrentdatetime(), 
                constraints=constraints,
                initialportfolio=initialportfolio,
                linearrestrictions=linearrestrictions,
                cholesky=cholesky,
                riskaversion=riskaversion)

export Constraints, LinearRestriction

end

