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
    minpositionsizesecurity::Vector{Float64}
    maxpositionsizesecurity::Vector{Float64}
    tradelimitsecurity::Vector{Float64}
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
        maxshortexposure::Float64 = 0.0,
        minpositionsizesecurity::Vector{Float64} = Vector{Float64}(),
        maxpositionsizesecurity::Vector{Float64} = Vector{Float64}(),
        tradelimitsecurity::Vector{Float64} = Vector{Float64}()) = 
            Constraints(minpositionsize, maxpositionsize, maxturnover, tradelimit,
                        minleverage, maxleverage, minlongexposure, maxlongexposure,
                        minshortexposure, maxshortexposure, 
                        minpositionsizesecurity, maxpositionsizesecurity,
                        tradelimitsecurity)


type LinearRestriction
    coeff::Vector{Float64}
    lower::Float64
    upper::Float64
end


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

function __setupmodel(constraints::Constraints, nstocks::Int, initialportfolio::Vector{Float64}, restrictions::Vector{LinearRestriction})
    
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
    minpositionsizesecurity = constraints.minpositionsizesecurity
    maxpositionsizesecurity = constraints.maxpositionsizesecurity
    tradelimitsecurity = constraints.tradelimitsecurity
  
    if length(initialportfolio) != nstocks
        error("Length of initial portfolio = $(length(initialportfolio)) is not the  same as num. of stocks = $(nstocks)")
    end

    #Initialize a model
    #m = Model(solver=ClpSolver())
    m = Model(solver=IpoptSolver())
    
    #Implementing maximum position size
    @variable(m, x_l[1:nstocks] >= 0)
    if (length(maxpositionsizesecurity) == nstocks)
        maxpositionsizesecurity = min.(maxpositionsizesecurity, maxpositionsize) 
    else
        maxpositionsizesecurity = maxpositionsize*ones(nstocks)
    end
    @constraint(m, x_l .<= maxpositionsizesecurity)

    @variable(m, x_s[1:nstocks] <= 0)
    #Implementing minimum position size   
    if (length(minpositionsizesecurity) == nstocks)
        minpositionsizesecurity = max.(minpositionsizesecurity, minpositionsize) 
    else
        minpositionsizesecurity = minpositionsize*ones(nstocks)
    end
    @constraint(m, x_s .>=  minpositionsizesecurity)
    
    #Implementing Turnover restriction
    #Variable y to implement turnover restriction
    #y = |x_l+x_s - initialportfolio|
    @variable(m, y[1:nstocks] >= 0)
    @constraint(m, y - (x_l + x_s - initialportfolio) .>= 0)
    @constraint(m, y + (x_l + x_s - initialportfolio) .>= 0)
    
    #Implementing Trade size restrictions
    if (length(tradelimitsecurity) !=0 && length(tradelimitsecurity) == nstocks)
        tradelimitsecurity = min.(tradelimitsecurity, tradelimit)
    else
        tradelimitsecurity = tradelimit*ones(nstocks)
    end
    @constraint(m, y .<= tradelimitsecurity)
       
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


    #Add Linear restrictions
    for restriction in restrictions
        coeff = restriction.coeff
        lower = restriction.lower
        upper = restriction.upper

        #allow only non NaN coefficients
        coeff[isnan.(coeff)] = 0.0
        @constraint(m, lower <= sum(coeff.*(x_l+x_s)) <= upper)
    end

    return (m, x_l, x_s)
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


