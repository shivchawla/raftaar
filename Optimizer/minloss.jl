#Minimize Loss
function minimumloss(symbols, 
                        date::DateTime;
                        window::Int = 22,
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