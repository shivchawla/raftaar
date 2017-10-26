__precompile__(true)
module Optimizer

using JuMP
using Ipopt
using Logger
using Utilities

USE_SYSTEM_BLAS=0

type Constraints
    minpositionsize::Float64
    maxpositionsize::Float64
    maxturnover::Float64 
    tradelimit::Float64
    minleverage::Float64
    maxleverage::Float64
    minlongexposure::Float64
    maxlongexposure::Float64
    minshortexposure::Float64
    maxshortexposure::Float64
end

Constraints(;minpositionsize::Float64 = 0.0, 
        maxpositionsize::Float64 = 0.2, 
        maxturnover::Float64 = 2.0, 
        tradelimit::Float64 = 1.0,
        minleverage::Float64 = 0.95,
        maxleverage::Float64 = 1.05,
        minlongexposure::Float64 = 0.0,
        maxlongexposure::Float64 = 1.0,
        minshortexposure::Float64 = 0.0,
        maxshortexposure::Float64 = 0.0) = 
            Constraints(minpositionsize, maxpositionsize, maxturnover, tradelimit,
                        minleverage, maxleverage, minlongexposure, maxlongexposure,
                        minshortexposure, maxshortexposure)


@enum Transform Linear CubeRoot

function uniformportfolio(symbols::Vector{String})

    nstocks = length(symbols)
    if nstocks == 0
        Logger.warn("zero stocks sepcified for portfolio construction")
        return Vector{Float64}()
    end

    return ones(nstocks)/nstocks 
end


function weightedportfolio(stocks::Vector{Any}, weights::Vector{Float64}, tranform::Transform=Transform(Linear))
    nstocks = length(stocks)
    nweights = length(weights)

    if nstocks == 0
        Logger.warn("zero stocks sepcified for portfolio construction")
        return Vector{Float64}()
    elseif nweights == 0
        Logger.warn("weight vector specified for portfolio construction is empty")
        return zeros(nstocks)
    elseif nstocks != nweights
        Logger.warn("size of weight vector and number of stocks is different")
        return zeros(nstocks)
    else
        transformedweights = modifyvariable(weights, transform)
        hasnegativeweights = length(transformedweights < 0.0) > 0 

        if hasnegativeweights
            Logger.warn("negative weights are specfied. Only positive weights are allowed")
            return zeros(nstocks)
        end

        arealllweightszero = length(transformedweights == 0.0) == nweights

        if arealllweightszero
            Logger.warn("All weights are zero. Please specify positive weights")
            return zeros(nstocks)
        end

        return transformedweights/sum(transformedweights)

    end    
end


function modifyvariable(vec::Vector{Float64}, transform::Transform)
    if transform == Transform(Linear)
        return vec
    elseif transform == Transform(CubeRoot)
        return cbrt(vec)
    elseif transform == Transform(Logorithm)
        return log(vec)
    end
end


function weightedportfolio_bymcap(symbols::Vector{Any}, maxweight::Float64 = 1.0)
    weights = ones(length(symbols))
    weightedportfolio(symbols, weights)
end


function weightedportfolio_bycuberootmcap(symbols::Vector{Any}, maxweight::Float64 = 1.0)
    weights = ones(length(symbols))
    weightedportfolio(symbols, weights, Transform(CubeRoot))
end


function weightedportfolio_byreversevolatility(symbols::Vector{Any}, window::Int = 22, maxweight::Float64 = 1.0)
    weights = ones(length(symbols))
    weightedportfolio(symbols, weights)
end


function getreturns(symbols::Vector{String}, date::DateTime, window::Int = 22)
    nstocks = length(symbols)
    randn(window, nstocks) 
end    

function __setupmodel(constraints::Constraints, nstocks::Int, initialportfolio::Vector{Float64})
    minpositionsize = constraints.minpositionsize
    maxpositionsize = constraints.maxpositionsize
    maxturnover = constraints.maxturnover
    tradelimit = constraints.tradelimit
    minleverage = constraints.minleverage
    maxleverage = constraints.maxleverage
    minlongexposure = constraints.minlongexposure
    maxlongexposure = constraints.maxlongexposure
    minshortexposure = constraints.minshortexposure
    maxshortexposure = constraints.maxshortexposure
  

    if length(initialportfolio) != nstocks
        error("Length of initial portfolio = $(length(initialportfolio)) is not the  same as num. of stocks = $(nstocks)")
    end

    #Initialize a model
    #m = Model(solver=ClpSolver())
    m = Model(solver=IpoptSolver())
    
    #Implementing maximum position size
    @variable(m, 0<= x_l[1:nstocks] <= maxpositionsize)
    #Implementing minimum position size   
    @variable(m, minpositionsize <= x_s[1:nstocks] <= 0)
    
    #Implementing Turnover restriction
    #Variable y to implement turnover restriction
    
    #y = |x_l+x_s - initialportfolio|
    @variable(m, y[1:nstocks] >= 0)
    @constraint(m, y - (x_l + x_s - initialportfolio) .>= 0)
    @constraint(m, y + (x_l + x_s - initialportfolio) .>= 0)
    
    #Implementing Trade size restrictions
    @constraint(m, y .<= tradelimit)
    
    #Turnover constraint 
    @constraint(m, sum(y) <= maxturnover)
    
    
    if maxlongexposure > 0.0
        @constraint(m, sum(x_l) <= maxlongexposure)
    end

    if minlongexposure > 0.0
        @constraint(m, sum(x_l) >= minlongexposure)
    end

    if maxshortexposure < 0.0
        @constraint(m, sum(x_s) >= maxshortexposure)
    end
      
    if minshortexposure < 0.0
        @constraint(m, sum(x_s) <= minshortexposure)
    end

    # Binary condition to force non-zero on either x_l or x_s
    #=if maxshortexposure < 0 && maxlongexposure > 0
        @variable(m, bin[1:nstocks], Bin)
        @constraint(m, x_l .<= bin)
        @constraint(m, x_s .>= -(1 - bin))
    end=# 

    # Leverage restrictions
    # minleverage <= sum(x_l) - sum(x_s) <=maxleverage
    
    @constraint(m, sum(x_l) - sum(x_s) <= maxleverage)
    @constraint(m, sum(x_l) - sum(x_s) >= minleverage)

    return (m, x_l, x_s)
end

#Minimize Absolute Deviation
function minimumabsolutedeviation(symbols;
                                    window::Int = 22,
                                    date::DateTime = getcurrentdatetime(), 
                                    constraints::Constraints = Constraints(),
                                    initialportfolio::Vector{Float64}=Vector{Float64}())
    
    #__IllegalDate(date)

    #Retrieve the standard deviation over window
    nstocks = length(symbols)

    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end
    
    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio)

    returns = price_returns(symbols, "Close", :Day, window, date)
    returns = values(returns)
    returns[isnan.(returns)] = 0.0
   
    (nrows, ncols) = size(returns)

    if(nrows == 0)
        Logger.warn("No returns provided")
        Logger.warn("Exiting Optimizer")
        return
    end

    #Returns window is one less than price
    window -= 1
    if nrows != window
        Logger.warn("Return window of $nrows days is shorter than given window of $window days")
        window = nrows 
    end

    #Objective function to minimze the absolute deviation
    #Implementing positivity of objective function components
    #Variable u_plus and u_minus to implement absolute objective function
    
    @variable(m, up[1:window] >= 0)    
    @variable(m, ul[1:window] >= 0)

    @constraint(m, up - ul - returns * (x_l + x_s) + (1.0/window) * sum(returns * (x_l + x_s)) .>= 0)
    @constraint(m, up - ul - returns * (x_l + x_s) + (1.0/window) * sum(returns * (x_l + x_s)) .>= 0)
     
    @objective(m, Min, sum(up+ul))
    
    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))
         
end


#Minimize Absolute Semi-Deviation
function minimumabsolutesemideviation(symbols; 
                                        window::Int = 22,
                                        date::DateTime = getcurrentdatetime(), 
                                        constraints::Constraints=Constraints(),
                                        initialportfolio::Vector{Float64}=Vector{Float64}())
    
    #__IllegalDate(date)

    #Retrieve the standard deviation over window
    nstocks = length(symbols)
    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end

    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio)
    
    returns = values(price_returns(symbols, "Close", :Day, window, date))
    # For Semi-Deviation , we consder just the negative returns
    returns[isnan(returns)] = 0.0
    returns[returns.>0] = 0.0

    (nrows, ncols) = size(returns)

    if(nrows == 0)
        Logger.warn("No returns provided")
        Logger.warn("Exiting Optimizer")
        return
    end

    #Returns window is one less than price
    window -= 1
    if nrows != window
        Logger.warn("Return window of $nrows days is shorter than given window of $window days")
        window = nrows 
    end

    #Objective function to minimze the absolute deviation
    #Implementing positivity of objective function components
    #Variable u_plus and u_minus to implement absolute objective function
    @variable(m, up[1:window] >= 0)    
    @variable(m, ul[1:window] >= 0)
    
    @constraint(m, up - ul - returns * (x_l + x_s) + (1.0/window) * sum(returns * (x_l + x_s)) .>= 0)
    @constraint(m, up - ul - returns * (x_l + x_s) + (1.0/window) * sum(returns * (x_l + x_s)) .>= 0)
     
    @objective(m, Min, sum(up+ul))
    
    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))    
end

#Minimize Loss
function minimumloss(symbols; 
                        window::Int = 22,
                        date::DateTime = getcurrentdatetime(), 
                        constraints::Constraints=Constraints(),
                        initialportfolio::Vector{Float64}=Vector{Float64}())

    #__IllegalDate(date)

    #Retrieve the standard deviation over window
    nstocks = length(symbols)
    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end
      
    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio)
    returns = values(price_returns(symbols, "Close", :Day, window, date))
    returns[isnan(returns)] = 0.0 

    (nrows, ncols) = size(returns)

    if(nrows == 0)
        Logger.warn("No returns provided")
        Logger.warn("Exiting Optimizer")
        return
    end

    #Returns window is one less than price
    window -= 1
    if nrows != window
        Logger.warn("Return window of $nrows days is shorter than given window of $window days")
        window = nrows 
    end
       
    # Define the loss variable
    @variable(m, loss)
    # Add constraints. Loss is greater than negative of calculated loss everydays 
    # Minimize the loss (Minimzing the "maximum" loss)    
    @constraint(m, -(returns*(x_l + x_s))[1:window] - loss .<= 0)

    @objective(m, Min, loss)
    
    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))     
end

#Minimize Volatility
function minimumvolatility(symbols; 
                            window::Int = 22,
                            date::DateTime = getcurrentdatetime(), 
                            constraints::Constraints=Constraints(),
                            initialportfolio::Vector{Float64}=Vector{Float64}())
    
    #__IllegalDate(date)
    #Retrieve the standard deviation over window
    nstocks = length(symbols)

    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end
    
    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio)
    returns = values(price_returns(symbols, "Close", :Day, window, date))
    returns[isnan(returns)] = 0.0  

    (nrows, ncols) = size(returns)

    if(nrows == 0)
        Logger.warn("No returns provided")
        Logger.warn("Exiting Optimizer")
        return
    end

    #Returns window is one less than price
    window -= 1
    if nrows != window
        Logger.warn("Return window of $nrows days is shorter than given window of $window days")
        window = nrows 
    end
    
    try
        cl = cholfact(Symmetric(cov(returns)), Val{true})
   
        L = convert(Array{Float64,2}, cl[:L]) 
        @variable(m, zeta[1:nstocks])
        @constraint(m, zeta - L*(x_l + x_s) .== 0)
        
        @objective(m, Min, sum(zeta.*zeta))
    catch err
        Logger.error("Error in computing cholesky")
        rethrow(err)
        return
    end

    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))     
end


#Markowitz - 1
function meanvariance(symbols; 
                        targeret::Float64 = 0.2,    
                        window::Int = 22,
                        date::DateTime = getcurrentdatetime(), 
                        constraints::Constraints=Constraints(),
                        initialportfolio::Vector{Float64}=Vector{Float64}())
    
    #__IllegalDate(date)

    #Retrieve the standard deviation over window
    nstocks = length(symbols)

    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end
    
    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio)
    returns = values(price_returns(symbols, "Close", :Day, window, date))
    returns[isnan(returns)] = 0.0  

    (nrows, ncols) = size(returns)

    if(nrows == 0)
        Logger.warn("No returns provided")
        Logger.warn("Exiting Optimizer")
        return
    end

    #Returns window is one less than price
    window -= 1
    if nrows != window
        Logger.warn("Return window of $nrows days is shorter than given window of $window days")
        window = nrows 
    end
    
    try
        cl = cholfact(Symmetric(cov(returns)), Val{true})
   
        L = convert(Array{Float64,2}, cl[:L]) 
        @variable(m, zeta[1:nstocks])
        @constraint(m, zeta - L*(x_l + x_s) .== 0)
        
        @objective(m, Min, sum(zeta.*zeta))


        #Add returns constraints
        # 1. Convrt returns to year units
        returns*= 252/window
        @constraint(m, sum(returns * (x_l + x_s)) >= targeret)  
    catch err
        Logger.error("Error in computing cholesky")
        rethrow(err)
        return
    end

    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))     
end

#Markowitz - 1
function meanvariance2(symbols; 
                        targeret::Float64 = 0.2,    
                        window::Int = 22,
                        date::DateTime = getcurrentdatetime(), 
                        constraints::Constraints=Constraints(),
                        initialportfolio::Vector{Float64}=Vector{Float64}())
    
    #__IllegalDate(date)

    #Retrieve the standard deviation over window
    nstocks = length(symbols)

    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end
    
    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio)
    returns = values(price_returns(symbols, "Close", :Day, window, date))
    returns[isnan(returns)] = 0.0  

    (nrows, ncols) = size(returns)

    if(nrows == 0)
        Logger.warn("No returns provided")
        Logger.warn("Exiting Optimizer")
        return
    end

    #Returns window is one less than price
    window -= 1
    if nrows != window
        Logger.warn("Return window of $nrows days is shorter than given window of $window days")
        window = nrows 
    end
    
    try
        cl = cholfact(Symmetric(cov(returns)), Val{true})
   
        L = convert(Array{Float64,2}, cl[:L]) 
        @variable(m, zeta[1:nstocks])
        @constraint(m, zeta - L*(x_l + x_s) .== 0)
        
        annreturns= returns*252/window
        @constraint(m, sum(annreturns * (x_l + x_s)) >= targeret)

        @objective(m, Max, sum(returns * (x_l + x_s)) - sum(zeta.*zeta))
       
    catch err
        Logger.error("Error in computing cholesky")
        rethrow(err)
        return
    end

    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))     
end


#Generic optimize function
function optimize(symbols, 
                    method="minvol", 
                    window::Int = 22;
                    targeret::Float64 = 0.2,
                    date::DateTime = getcurrentdatetime(), 
                    constraints::Constraints=Constraints(),
                    initialportfolio::Vector{Float64}=Vector{Float64}())

    if method=="minvol"
        minimumvolatility(symbols, 
                            window=window, 
                            date=date, 
                            constraints=constraints, 
                            initialportfolio=initialportfolio)
    elseif method=="mad"
        minimumabsolutedeviation(symbols, 
                                    window=window, 
                                    date=date, 
                                    constraints=constraints, 
                                    initialportfolio=initialportfolio)
    elseif method=="masd"
        minimumabsolutesemideviation(symbols, 
                                    window=window, 
                                    date=date, 
                                    constraints=constraints, 
                                    initialportfolio=initialportfolio)
    elseif method=="minloss"
        minimumvolatility(symbols, 
                            window=window, 
                            date=date, 
                            constraints=constraints, 
                            initialportfolio=initialportfolio)
    elseif method=="meanvar"
        meanvariance(symbols, 
                        targeret=targeret,
                        window=window, 
                        date=date, 
                        constraints=constraints, 
                        initialportfolio=initialportfolio)
    elseif method=="meanvar2"
        meanvariance2(symbols, 
                        targeret=targeret,
                        window=window, 
                        date=date, 
                        constraints=constraints, 
                        initialportfolio=initialportfolio)
    #=else 
        return (0.0, zeros(length(symbols)))=#
    end
end


function __handleoutput(symbols, t, status, default)
    
    m=t[1]
    x_l=t[2]
    x_s=t[3]

    nstocks = length(symbols)

    if status == :Optimal
        println("Problem solved successfully")
        wts = getvalue(x_l) + getvalue(x_s)

        port = [(symbols[i], wts[i]) for i = 1:nstocks]
        return (getobjectivevalue(m), port, status)
    else 
        __handlestatus(status)
        port = [(symbols[i], default[2][i]) for i in 1:nstocks]
        return (default[1], port, status)
    end
end

function __handlestatus(status::Symbol)
    
    if status==:Unbounded  
        println("Problem is unbounded")
    elseif status==:Infeasible 
        println("Problem is infeasible")
    elseif status==:UserLimit  
        println("Iteration limit or timeout")
    elseif status==:Error
        println("Solver exited with an error")
    elseif status==:NotSolved  
        println("Model built in memory but not optimized")
    end
end

end # end of module
