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
    if(order.quantity == 0)
        Logger.warn("Can't place order with 0 quantity for $(order.securitysymbol.ticker)")
        return
    end

    if !ispartofuniverse(order.securitysymbol)
        Logger.warn("Security: $(order.securitysymbol.id)/$(order.securitysymbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return
    end

    # Set the time for the order
    if !algorithm.tradeenv.livemode
        order.datetime = getcurrentdatetime()
    else 
        order.datetime = now()
    end
    

    Logger.info("Placing order: $(order.securitysymbol.ticker)/$(order.quantity)/$(order.ordertype)")
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

# Order function to set holdings to a specific level in pct/value/shares
function setholdingpct(ticker::String, target::Float64)
    setholdingpct(getsecurity(ticker), target)
end

function setholdingpct(security::Security, target::Float64)
    setholdingpct(security.symbol, target)
end

function setholdingpct(symbol::SecuritySymbol, target::Float64)
    
    if !ispartofuniverse(symbol)
        Logger.warn("Security: $(symbol.id)/$(symbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return
    end


    initialshares = getposition(symbol).quantity
    
    if target == 0 && abs(initialshares) > 0
        placeorder(symbol, -initialshares)
        return
    end

    latestprice = getlatestprice(symbol)

    if latestprice <= 0.00001
        Logger.warn("Price not available for $(symbol.ticker)")
        return
    end

    currentvalue = initialshares * latestprice
    
    valuetobeinvested = getportfoliovalue() * target - currentvalue

    roundedshares = round(Int, valuetobeinvested/latestprice)

    if abs(roundedshares) > 0
        placeorder(symbol, roundedshares)
    end

end

function setholdingvalue(ticker::String, target::Float64)
    setholdingvalue(getsecurity(ticker), target)
end

function setholdingvalue(security::Security, target::Float64)
    setholdingvalue(security.symbol, target)
end

function setholdingvalue(symbol::SecuritySymbol, target::Float64)
    
    if !ispartofuniverse(symbol)
        Logger.warn("Security: $(symbol.id)/$(symbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return
    end

    initialshares = getposition(symbol).quantity
    
    if target == 0 && abs(initialshares) > 0
        placeorder(symbol, -initialshares)
        return
    end

    latestprice = getlatestprice(symbol)

    if latestprice <= 0.00001
        Logger.warn("Price not available for $(symbol.ticker)")
        return
    end

    currentvalue = initialshares * latestprice
    
    valuetobeinvested = target - currentvalue

    roundedshares = round(Int, valuetobeinvested/latestprice)

    if abs(roundedshares) > 0
        placeorder(symbol, roundedshares)
    end
    
end

function setholdingshares(ticker::String, target::Float64)
    setholdingshares(getsecurity(ticker), target)
end

function setholdingshares(security::Security, target::Int64)
    setholdingshares(security.symbol, target)
end

function setholdingshares(symbol::SecuritySymbol, target::Int64)
    
    if !ispartofuniverse(symbol)
        Logger.warn("Security: $(symbol.id)/$(symbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return
    end

    initialshares = getposition(symbol).quantity
    
    if target == 0 && abs(initialshares) > 0
        placeorder(symbol, -initialshares)
        return
    end

    #get current hares
    latestprice = getlatestprice(symbol)

    if latestprice <= 0.00001
        Logger.warn("Price not available for $(symbol.ticker)")
        return
    end
    
    sharestobeinvested = target - initialshares
    
    if abs(sharestobeinvested) > 0
        placeorder(symbol, sharestobeinvested)
    end

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