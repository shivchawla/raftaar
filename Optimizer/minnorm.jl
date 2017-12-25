#Minimize Loss
function minimumnorm(symbols,
                        date::DateTime; 
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
       
    # Minimize the norm
    @objective(m, Min, sum((x_l+x_s-initialportfolio).*(x_l+x_s-initialportfolio)))
 
    status = solve(m)

    for restriction in linearrestrictions
        println("Restriction Value: $(sum(restriction.coeff.*(getvalue(x_l) + getvalue(x_s))))")
    end

    __handleoutput(symbols, (m,x_l,x_s), status, (0.0, initialportfolio))     
end