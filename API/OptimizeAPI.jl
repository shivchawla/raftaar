
__precompile__(true)
module OptimizeAPI

using API
using Optimizer

import Optimizer: optimize, Constraints, LinearRestriction,
    meanvariance, meanvariance2, minimumvolatility,
    minimumabsolutedeviation, minimumabsolutesemideviation, minimumloss, 
    minimumnorm


optimize(symbols; 
            method::String="minvol",
            targetret::Float64=0.2,
            nfactors::Int=10,
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
            returnsforecast::Vector{Float64}=Vector{Float64}(),
            cholesky=false,
            riskaversion=1.0) = 
    Optimizer.optimize(symbols,
            getcurrentdatetime(),
            method, 
            window;
            targetret=targetret, 
            nfactors=nfactors,
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions,
            returnsforecast=returnsforecast,
            cholesky=cholesky,
            riskaversion=riskaversion)

meanvariance(symbols; 
            targetret::Float64=0.2,
            nfactors::Int=10,
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
            returnsforecast::Vector{Float64}=Vector{Float64}(),
            cholesky=false) = 

        Optimizer.meanvariance(symbols,
            getcurrentdatetime(), 
            targetret=targetret,
            nfactors=nfactors,
            window=window,
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions,
            returnsforecast=returnsforecast,
            cholesky=cholesky)

meanvariance2(symbols; 
            nfactors::Int=10,
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
            returnsforecast::Vector{Float64}=Vector{Float64}(),
            cholesky=false,
            riskaversion=1.0) = 

        Optimizer.meanvariance2(symbols,
            getcurrentdatetime(),
            nfactors=nfactors,
            window=window,
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions,
            returnsforecast=returnsforecast,
            cholesky=cholesky,
            riskaversion=riskaversion)


minimumvolatility(symbols; 
            nfactors::Int=10,
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
            cholesky=false) = 
        
        Optimizer.minimumvolatility(symbols,
            getcurrentdatetime(), 
            nfactors=nfactors,
            window=window,
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions,
            cholesky=cholesky)

minimumabsolutedeviation(symbols;
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[]) = 
        
        Optimizer.minimumabsolutedeviation(symbols,
            getcurrentdatetime(), 
            window=window,
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions)

minimumabsolutesemideviation(symbols;
                window::Int=22,
                constraints::Constraints=Constraints(),
                initialportfolio::Vector{Float64}=Vector{Float64}(),
                linearrestrictions::Vector{LinearRestriction}=LinearRestriction[]) = 
        
        Optimizer.minimumabsolutesemideviation(symbols,
            getcurrentdatetime(), 
            window=window,
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions)

minimumloss(symbols; 
            window::Int=22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[]) =
        
        Optimizer.minimumloss(symbols,
            getcurrentdatetime(), 
            window=window,
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions)

minimumnorm(symbols; 
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}(),
            linearrestrictions::Vector{LinearRestriction}=LinearRestriction[]) = 

        Optimizer.minimumnorm(symbols,
            getcurrentdatetime(), 
            constraints=constraints,
            initialportfolio=initialportfolio,
            linearrestrictions=linearrestrictions)


export Constraints, LinearRestriction

end

