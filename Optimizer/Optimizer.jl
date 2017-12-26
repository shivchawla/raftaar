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
                    date::DateTime,  
                    method::String="minvol", 
                    window::Int=22;
                    targetret::Float64=0.2,
                    nfactors::Int=10,
                    constraints::Constraints=Constraints(),
                    initialportfolio::Vector{Float64}=Vector{Float64}(),
                    linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
                    cholesky=false,
                    riskaversion=1.0,
                    returnsforecast::Vector{Float64}=Vector{Float64})
                    
    if method=="minvol2"
        minimumvolatility_raw(symbols,
                            date, 
                            window=window, 
                            constraints=constraints, 
                            initialportfolio=initialportfolio,
                            linearrestrictions=linearrestrictions)
    elseif method=="minvol"
        minimumvolatility(symbols,
                            date,  
                            window=window, 
                            nfactors=nfactors,
                            constraints=constraints, 
                            initialportfolio=initialportfolio,
                            linearrestrictions=linearrestrictions,
                            cholesky=cholesky)
    elseif method=="min_mad"
        minimumabsolutedeviation(symbols,
                                    date, 
                                    window=window, 
                                    constraints=constraints, 
                                    initialportfolio=initialportfolio,
                                    linearrestrictions=linearrestrictions)
    elseif method=="min_msad"
        minimumabsolutesemideviation(symbols,
                                    date, 
                                    window=window, 
                                    constraints=constraints, 
                                    initialportfolio=initialportfolio,
                                    linearrestrictions=linearrestrictions)
    elseif method=="minloss"
        minimumloss(symbols, 
                    date,
                    window=window, 
                    constraints=constraints, 
                    initialportfolio=initialportfolio,
                    linearrestrictions=linearrestrictions)
    elseif method=="meanvar"
        meanvariance(symbols, 
                        date,
                        targetret=targetret,
                        window=window, 
                        constraints=constraints, 
                        initialportfolio=initialportfolio,
                        linearrestrictions=linearrestrictions,
                        returnsforecast=returnsforecast,
                        cholesky=cholesky)
    elseif method=="meanvar2"
        meanvariance2(symbols,
                        date, 
                        window=window, 
                        constraints=constraints, 
                        initialportfolio=initialportfolio,
                        linearrestrictions=linearrestrictions,
                        returnsforecast=returnsforecast,
                        cholesky=cholesky,
                        riskaversion=riskaversion)
    elseif method=="minnorm"
        minimumnorm(symbols,
                        date,  
                        constraints=constraints, 
                        initialportfolio=initialportfolio,
                        linearrestrictions=linearrestrictions)
    else 
        return (0.0, [(symbol, 0.0) for symbol in symbols], :Unavailable)
    end
end

export minimumabsolutesemideviation, minimumabsolutedeviation, minimumvolatility,
    minimumnorm, minimumvolatility, meanvariance, meanvariance2


end # end of module
