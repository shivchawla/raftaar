#Minimize Absolute Deviation
function minimumabsolutedeviation(symbols;
                                    window::Int = 22,
                                    date::DateTime = getcurrentdatetime(), 
                                    constraints::Constraints = Constraints(),
                                    initialportfolio::Vector{Float64}=Vector{Float64}(),
                                    linearrestrictions::Vector{LinearRestriction}=LinearRestriction[])
    
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
                                        initialportfolio::Vector{Float64}=Vector{Float64}(),
                                        linearrestrictions::Vector{LinearRestriction}=LinearRestriction[])
    
    #__IllegalDate(date)

    #Retrieve the standard deviation over window
    nstocks = length(symbols)
    if initialportfolio == []
        initialportfolio = zeros(nstocks)
    end

    (m, x_l, x_s) = __setupmodel(constraints, nstocks, initialportfolio, linearrestrictions)
    
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
