
#Markowitz - 1
function meanvariance(symbols; 
                        nfactors=10,
                        targetret::Float64 = 0.2,    
                        window::Int = 22,
                        date::DateTime = getcurrentdatetime(), 
                        constraints::Constraints=Constraints(),
                        initialportfolio::Vector{Float64}=Vector{Float64}(),
                        linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
                        cholesky = false)
    
    #Retrieve the standard deviation over window
    nstocks = length(symbols)

    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end
    
    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio, linearrestrictions)
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
    
    if(cholesky)
        try
            cl = cholfact(Symmetric(cov(returns)), Val{true})
       
            L = convert(Array{Float64,2}, cl[:L]) 
            @variable(m, zeta[1:nstocks])
            @constraint(m, zeta - L*(x_l + x_s) .== 0)
            
            @objective(m, Min, sum(zeta.*zeta))

            #Add returns constraints
            # 1. Convrt returns to year units
            returns*= 252/window
            @constraint(m, sum(returns * (x_l + x_s)) >= targetret)  
        catch err
            Logger.error("Error in computing cholesky")
            rethrow(err)
            return
        end
    else
        try
            (r,c) = size(returns)

            # method= :cm doesn't work with positive SEMI-definite matrix
            # so usign mehod = :em, DON'T really know the difference
            nfactors = min(c-1, nfactors)
            M = fit(FactorAnalysis, returns'; method=:em, maxoutdim=nfactors) 

            @variable(m, zeta[1:nfactors])
            L = loadings(M) #(nstocks X nfactors)
            
            L[isnan.(L)] = 0.0
            @constraint(m, zeta - L'*(x_l+x_s) .== 0)
            
            diagonal = diag(cov(M))
            diagonal[isnan.(diagonal)]=0.0

            # Minimize sum of systematic + idiosycratic risk
            # systematic = risk computed using factors
            # idiosycratic  = risk from error terms variance [cov(M): primarily diagonal]
            @objective(m, Min, sum(zeta.*zeta) + sum(diagonal.*(x_l+x_s).*(x_l+x_s)))
            
               #Add returns constraints
            # 1. Convrt returns to year units
            returns*= 252/window
            @constraint(m, sum(returns * (x_l + x_s)) >= targetret)

        catch err
            println(err)
            rethrow(err)
            return
        end
    end

    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))     
end

#Markowitz - 1
function meanvariance2(symbols;
                        nfactors=10, 
                        targetret::Float64 = 0.2,    
                        window::Int = 22,
                        date::DateTime = getcurrentdatetime(), 
                        constraints::Constraints=Constraints(),
                        initialportfolio::Vector{Float64}=Vector{Float64}(),
                        linearrestrictions::Vector{LinearRestriction}=LinearRestriction[],
                        cholesky = false,
                        riskaversion = 1.0)
    
    #__IllegalDate(date)

    #Retrieve the standard deviation over window
    nstocks = length(symbols)

    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end
    
    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio, linearrestrictions)
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
    
    if(cholesky)
        try
            cl = cholfact(Symmetric(cov(returns)), Val{true})
       
            L = convert(Array{Float64,2}, cl[:L]) 
            @variable(m, zeta[1:nstocks])
            @constraint(m, zeta - L*(x_l + x_s) .== 0)
            
            @objective(m, Max, sum(returns * (x_l + x_s)) - 0.5*riskaversion*sum(zeta.*zeta))
           
        catch err
            Logger.error("Error in computing cholesky")
            rethrow(err)
            return
        end
    else
        try
            (r,c) = size(returns)

            # method= :cm doesn't work with positive SEMI-definite matrix
            # so usign mehod = :em, DON'T really know the difference
            nfactors = min(c-1, nfactors)
            M = fit(FactorAnalysis, returns'; method=:em, maxoutdim=nfactors) 

            @variable(m, zeta[1:nfactors])
            L = loadings(M) #(nstocks X nfactors)
            
            L[isnan.(L)] = 0.0
            @constraint(m, zeta - L'*(x_l+x_s) .== 0)
            
            diagonal = diag(cov(M))
            diagonal[isnan.(diagonal)]=0.0

            # Minimize sum of systematic + idiosycratic risk
            # systematic = risk computed using factors
            # idiosycratic  = risk from error terms variance [cov(M): primarily diagonal]
            @objective(m, Max, sum(returns * (x_l + x_s)) - 0.5*riskaversion*(sum(zeta.*zeta) - sum(diagonal.*(x_l+x_s).*(x_l+x_s))))
        catch err
            println(err)
            rethrow(err)
            return
        end
    end

    status = solve(m)

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))     
end
