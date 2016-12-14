"""
Functions to expose brokerage API
""" 
function setcancelpolicy(cancelpolicy::CancelPolicy)
    checkforparent([:initialize,:_init])
    setcancelpolicy!(algorithm.brokerage, CancelPolicy(EOD))
end

function setcancelpolicy(cancelpolicy::String)
    checkforparent([:initialize,:_init])
    setcancelpolicy!(algorithm.brokerage, cancelpolicy)
end

function setcommission(commission::Tuple{String, Float64})
    checkforparent([:initialize,:_init])
    setcommission!(algorithm.brokerage, commission)
end

function setcommission(commission::Commission)
    checkforparent([:initialize,:_init])
    setcommission!(algorithm.brokerage, commission)
end

function setslippage(slippage::Slippage)
    checkforparent([:initialize,:_init])
    setslippage!(algorithm.brokerage, slippage)
end

function setslippage(slippage::Tuple{String, Float64})
    checkforparent([:initialize,:_init])
    setslippage!(algorithm.brokerage, slippage)
end

function setparticipationrate(participationrate::Float64)
    checkforparent([:initialize,:_init])
    setparticipationrate!(algorithm.brokerage, participationrate)
end
export setparticipationrate

function placeorder(security::Security, quantity::Int64)
    checkforparent([:ondata, :beforeclose])
    placeorder(security.symbol, quantity)
end 


function placeorder(symbol::SecuritySymbol, quantity::Int64)
    checkforparent([:ondata, :beforeclose])
    placeorder(Order(symbol, quantity))
end

function placeorder(order::Order)
    checkforparent([:ondata, :beforeclose])
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
export placeorder

function liquidate(symbol::SecuritySymbol)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(symbol, 0)  
end

function liquidate(ticker::String)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(ticker, 0)  
end

function liquidate(security::Security)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(security, 0)  
end
export liquidate

function liquidateportfolio()
    checkforparent([:ondata, :beforeclose])
    for security in getuniverse()
        liquidate(security)
    end
end
export liquidateportfolio


# Order function to set holdings to a specific level in pct/value/shares
function setholdingpct(ticker::String, target::Float64)
    checkforparent([:ondata, :beforeclose])
    setholdingpct(getsecurity(ticker), target)
end

function setholdingpct(security::Security, target::Float64)
    checkforparent([:ondata, :beforeclose])
    setholdingpct(security.symbol, target)
end

function setholdingpct(symbol::SecuritySymbol, target::Float64)
    checkforparent([:ondata, :beforeclose])
    
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
    roundedshares = valuetobeinvested > 0 ? floor(Int, valuetobeinvested/latestprice) : -ceil(Int, abs(valuetobeinvested)/latestprice)

    if abs(roundedshares) > 0
        placeorder(symbol, roundedshares)
    end

end

export setholdingpct

function setholdingvalue(ticker::String, target::Float64)
    checkforparent([:ondata, :beforeclose])
    setholdingvalue(getsecurity(ticker), target)
end

function setholdingvalue(security::Security, target::Float64)
    checkforparent([:ondata, :beforeclose])
    setholdingvalue(security.symbol, target)
end

function setholdingvalue(symbol::SecuritySymbol, target::Float64)
    checkforparent([:ondata, :beforeclose])
    
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
    roundedshares = valuetobeinvested > 0 ? floor(Int, valuetobeinvested/latestprice) : -ceil(Int, abs(valuetobeinvested)/latestprice)

    if abs(roundedshares) > 0
        placeorder(symbol, roundedshares)
    end
    
end
export setholdingvalue

function setholdingshares(ticker::String, target::Float64)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(getsecurity(ticker), target)
end

function setholdingshares(security::Security, target::Int64)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(security.symbol, target)
end

function setholdingshares(symbol::SecuritySymbol, target::Int64)
    checkforparent([:ondata, :beforeclose])
    
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
export setholdingshares

function hedgeportfolio()
end

function getopenorders()
    checkforparent([:ondata, :beforeclose])
    deepcopy(getopenorders(algorithm.brokerage))
end
export getopenorders

function cancelopenorders(symbol::SecuritySymbol)
    checkforparent([:ondata, :beforeclose])
    cancelallorders(algorithm.brokerage, symbol)
end
export cancelallorders

function cancelopenorders()
    checkforparent([:ondata, :beforeclose])
    cancelallorders(algorithm.brokerage)    
end
export cancelallorders