
__precompile__(true)

module OptimizeAPI

using API
using Optimizer

import Optimizer: optimize, Constraints

optimize(symbols; 
            method="minvol", 
            window::Int = 22,
            constraints::Constraints=Constraints(),
            initialportfolio::Vector{Float64}=Vector{Float64}()) = 
    Optimizer.optimize(symbols,
                method, 
                window,
                date=getcurrentdatetime(), 
                constraints=constraints,
                initialportfolio=initialportfolio)

end
