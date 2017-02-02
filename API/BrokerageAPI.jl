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


function _checkforrebalance()
    rebalance = getrebalancefrequency()
    date = getcurrentdate()
    
    if(rebalance == Rebalance(Rebalance_Daily))
        return true
    elseif (rebalance == Rebalance(Rebalance_Weekly) && Dates.dayofweek(date)==1)
        return true
    elseif (rebalance == Rebalance(Rebalance_Monthly) && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7)
        return true
    elseif (rebalance == Rebalance(Rebalance_Monthly) && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7 && Dates.dayofyear(date)<=31)
        return true
    else
        return false
    end
    
end


function placeorder(ticker::String, quantity::Int64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    placeorder(getsecurity(ticker), quantity)
end 

function placeorder(secid::Int, quantity::Int64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    placeorder(getsecurity(secid), quantity)
end 

function placeorder(security::Security, quantity::Int64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    placeorder(security.symbol, quantity)
end 

function placeorder(symbol::SecuritySymbol, quantity::Int64)
    
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose]) 
    placeorder(Order(symbol, quantity))  
    
end

function placeorder(order::Order)
    if !_checkforrebalance()
        return
    end
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

function liquidate(ticker::String)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(ticker, 0)  
end

function liquidate(secid::Int)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(secid, 0)  
end

function liquidate(symbol::SecuritySymbol)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(symbol, 0)  
end

function liquidate(security::Security)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(security, 0)  
end

function liquidate(pos::Position)
    checkforparent([:ondata, :beforeclose])
    setholdingshares(pos.securitysymbol, 0)  
end

export liquidate

function liquidateportfolio()
    checkforparent([:ondata, :beforeclose])
    for pos in getallpositions(algorithm.portfolio)
        liquidate(pos)
    end
end
export liquidateportfolio


# Order function to set holdings to a specific level in pct/value/shares
function setholdingpct(ticker::String, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingpct(getsecurity(ticker), target)
end

function setholdingpct(secid::Int, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingpct(getsecurity(secid), target)
end


function setholdingpct(security::Security, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingpct(security.symbol, target)
end

function setholdingpct(symbol::SecuritySymbol, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    
    if !ispartofuniverse(symbol)
        adduniverse(symbol)
        
        #=Logger.warn("Security: $(symbol.id)/$(symbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return=#
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

    openqty = 0

    for order in getopenorders(symbol)
        openqty += order.quantity
    end
    netroundedshares = roundedshares - openqty

    if abs(netroundedshares) > 0
        placeorder(symbol, netroundedshares)
    end

end

export setholdingpct

function setholdingvalue(secid::Int, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingvalue(getsecurity(secid), target)
end

function setholdingvalue(ticker::String, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingvalue(getsecurity(ticker), target)
end

function setholdingvalue(security::Security, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingvalue(security.symbol, target)
end

function setholdingvalue(symbol::SecuritySymbol, target::Float64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    
    if !ispartofuniverse(symbol)
        adduniverse(symbol)
        
        #=Logger.warn("Security: $(symbol.id)/$(symbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return=#
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

    openqty = 0
    for order in getopenorders(symbol)
        openqty += order.quantity
    end

    netroundedshares = roundedshares - openqty

    if abs(netroundedshares) > 0
        placeorder(symbol, netroundedshares)
    end
    
end
export setholdingvalue

function setholdingshares(secid::Int, target::Int64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingshares(getsecurity(secid), target)
end

function setholdingshares(ticker::String, target::Int64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingshares(getsecurity(ticker), target)
end

function setholdingshares(security::Security, target::Int64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    setholdingshares(security.symbol, target)
end

function setholdingshares(symbol::SecuritySymbol, target::Int64)
    if !_checkforrebalance()
        return
    end
    checkforparent([:ondata, :beforeclose])
    
    if !ispartofuniverse(symbol)
        adduniverse(symbol)
       
        #=Logger.warn("Security: $(symbol.id)/$(symbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return=#
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
    
    openqty = 0
    for order in getopenorders(symbol)
        openqty += order.quantity
    end

    sharestobeinvested = target - initialshares - openqty

    if abs(sharestobeinvested) > 0
        placeorder(symbol, sharestobeinvested)
    end

end
export setholdingshares

function hedgeportfolio()
end

function getopenorders(ticker::String)
    checkforparent([:ondata, :beforeclose])
    deepcopy(getopenorders(algorithm.brokerage, getsecurity(ticker).symbol))
end

function getopenorders(secid::Int)
    checkforparent([:ondata, :beforeclose])
    deepcopy(getopenorders(algorithm.brokerage, getsecurity(secid).symbol))
end

function getopenorders(symbol::SecuritySymbol)
    checkforparent([:ondata, :beforeclose])
    deepcopy(getopenorders(algorithm.brokerage, symbol))
end

function getopenorders(security::Security)
    checkforparent([:ondata, :beforeclose])
    deepcopy(getopenorders(algorithm.brokerage, security.symbol))
end

function getopenorders()
    checkforparent([:ondata, :beforeclose])
    deepcopy(getopenorders(algorithm.brokerage))
end
export getopenorders

function cancelopenorders(ticker::String)
    checkforparent([:ondata, :beforeclose])
    security = getsecurity(ticker)
    Logger.info("Canceling all orders for $(security.symbol.id)/$(security.symbol.ticker)")
    cancelallorders!(algorithm.brokerage, security.symbol)
end

function cancelopenorders(secid::Int)
    checkforparent([:ondata, :beforeclose])
    security = getsecurity(secid)
    Logger.info("Canceling all orders for $(security.symbol.id)/$(security.symbol.ticker)")
    cancelallorders!(algorithm.brokerage, security.symbol)
end
    
function cancelopenorders(security::Security)
    checkforparent([:ondata, :beforeclose])
    Logger.info("Canceling all orders for $(security.symbol.id)/$(security.symbol.ticker)")
    cancelallorders!(algorithm.brokerage, security.symbol)
end

function cancelopenorders(symbol::SecuritySymbol)
    checkforparent([:ondata, :beforeclose])
    Logger.info("Canceling all orders for $(symbol.id)/$(symbol.ticker)")
    cancelallorders!(algorithm.brokerage, symbol)
end

function cancelopenorders()
    checkforparent([:ondata, :beforeclose])
    Logger.info("Canceling all orders")
    cancelallorders!(algorithm.brokerage)    
end
export cancelopenorders
