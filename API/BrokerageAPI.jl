"""
Functions to expose brokerage API
""" 
function setcancelpolicy(cancelpolicy::CancelPolicy)
    #checkforparent(:setcancelpolicy, :initialize)
    setcancelpolicy!(algorithm.brokerage, CancelPolicy(EOD))
end

function setcommission(commission::Commission)
    #checkforparent(:setcommission, :initialize)
    setcommission!(algorithm.brokerage, commission)
end

function setslippage(slippage::Slippage)
    #checkforparent(:setslippage, :initialize)
    setslippage!(algorithm.brokerage, slippage)
end

function setparticipationrate(participationrate::Float64)
    setparticipationrate!(algorithm.brokerage, participationrate)
end

function placeorder(security::Security, quantity::Int64)
    placeorder(security.symbol, quantity)
end 

function placeorder(symbol::SecuritySymbol, quantity::Int64)
    placeorder(Order(symbol, quantity))
end

function placeorder(order::Order)
    if !algorithm.tradeenv.livemode
        order.datetime = getcurrentdatetime()
    else 
        order.datetime = now()
    end
    placeorder!(algorithm.brokerage, order)  
end

function liquidate(symbol::SecuritySymbol)
    setholdingshares(symbol, 0)  
end

function liquidateportfolio()
    for security in getuniverse()
        liquidate(security)
    end
end

#order function to set holdings to a specific level in pct/value/shares
function setholdingpct(symbol::SecuritySymbol, target::Float64)
    
    if !isvalid(symbol)
        Logger.warn("No a valid security: $(symbol.id)/$(symbol.ticker)")
        return
    end


    initialshares = getposition(symbol).quantity
    
    if target == 0 && abs(initialshares) > 0
        placeorder(symbol, -initialshares)
    end

    latestprice = getlatestprice(symbol)

    if latestprice < 0
        Logger.warn("Negative price of $(symbol.ticker)")
        return
    end

    currentvalue = initialshares * latestprice
    
    valuetobeinvested = getportfoliovalue() * target - currentvalue

    
    roundedshares = round(Int, valuetobeinvested/latestprice)
    placeorder(symbol, roundedshares)

end

function setholdingvalue(symbol::SecuritySymbol, target::Float64)
    
    if !isvalid(symbol)
        Logger.warn("No a valid ticker:$(symbol)")
        return
    end

    initialshares = getposition(symbol).quantity
    
    if target == 0 && abs(initialshares) > 0
        placeorder(symbol, -initialshares)
        return
    end

    latestprice = getlatestprice(symbol)

    if latestprice < 0
        Logger.warn("Negative price of $(symbol.ticker)")
        return
    end
    
    currentvalue = initialshares * latestprice
    
    valuetobeinvested = target - currentvalue

    roundedshares = round(Int, valuetobeinvested/latestprice)
    placeorder(symbol, roundedshares)

end

function setholdingshares(symbol::SecuritySymbol, target::Int64)
    
    if !isvalid(symbol)
        Logger.warn("No a valid security: $(symbol.id)/$(symbol.ticker)")
        return
    end

    initialshares = getposition(symbol).quantity
    
    if target == 0 && abs(initialshares) > 0
        placeorder(symbol, -initialshares)
        return
    end

    #get current hares
    latestprice = getlatestprice(symbol)

    if latestprice < 0
        Logger.warn("Negative price of $(symbol.ticker)")
        return
    end
    
    sharestobeinvested = target - initialshares
 
    placeorder(symbol, sharestobeinvested)

end

function hedgeportfolio()
end

function getopenorders()
    deepcopy(getopenorders(algorithm.brokerage))
end

function cancelallorders(symbol::SecuritySymbol)
    cancelallorders(algorithm.brokerage, symbol)
end

function cancelallorders()
    cancelallorders(algorithm.brokerage)    
end