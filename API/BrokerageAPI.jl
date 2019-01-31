"""
Functions to expose brokerage API
""" 
function setcancelpolicy(cancelpolicy::CancelPolicy)
    __IllegalContextMessage(:setcancelpolicy, :ondata)
    setcancelpolicy!(algorithm.brokerage, cancelpolicy)
end

function setcancelpolicy(cancelpolicy::String)
    __IllegalContextMessage(:setcancelpolicy, :ondata)
    setcancelpolicy!(algorithm.brokerage, cancelpolicy)
end

function setcommission(commission::Tuple{String, Float64})
    __IllegalContextMessage(:setcommission, :ondata)
    setcommission!(algorithm.brokerage, commission)
end

function setcommission(commission::Commission)
    __IllegalContextMessage(:setcommission, :ondata)
    setcommission!(algorithm.brokerage, commission)
end

function setslippage(slippage::Slippage)
    __IllegalContextMessage(:setslippage, :ondata)
    setslippage!(algorithm.brokerage, slippage)
end

function setslippage(slippage::Tuple{String, Float64})
    __IllegalContextMessage(:setslippage, :ondata)
    setslippage!(algorithm.brokerage, slippage)
end

function setparticipationrate(participationrate::Float64)
    __IllegalContextMessage(:setparticipationrate, :ondata)
    setparticipationrate!(algorithm.brokerage, participationrate)
end
export setparticipationrate

function setexecutionpolicy(executionpolicy::String)
    __IllegalContextMessage(:setexecutionpolicy, :ondata)
    setexecutionpolicy!(algorithm.brokerage, executionpolicy)
end
export setexecutionpolicy

function _checkforrebalance()
    rebalance = getrebalancefrequency()
    date = getcurrentdate()
    
    if rebalance == Rebalance_Daily
        return true
    elseif rebalance == Rebalance_Weekly && Dates.dayofweek(date)==1
        return true
    elseif rebalance == Rebalance_Monthly && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7
        return true
    elseif rebalance == Rebalance_Monthly && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7 && Dates.dayofyear(date)<=31
        return true
    else
        return false
    end
    
end

function placeorder(ticker::String, quantity::Int64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:placeorder, :initialize)
    placeorder(getsecurity(ticker), quantity)
end 

function placeorder(secid::Int, quantity::Int64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:placeorder, :initialize)
    placeorder(getsecurity(secid), quantity)
end 

function placeorder(security::Security, quantity::Int64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:placeorder, :initialize)
    placeorder(security.symbol, quantity)
end 

function placeorder(symbol::SecuritySymbol, quantity::Int64)
    
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:placeorder, :initialize)
    placeorder(Order(symbol, quantity))  
    
end

function placeorder(order::Order)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:placeorder, :initialize)
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
        order.datetime = getlatesttradebar(order.securitysymbol).datetime
    else 
        order.datetime = now()
    end
    
    #info("Placing order: $(order.securitysymbol.ticker)/$(order.quantity)/$(order.ordertype)")
    placeorder!(algorithm.brokerage, order)  
end
export placeorder

liquidate(sym::Symbol) = liquidate(String(sym))

function liquidate(ticker::String)
    __IllegalContextMessage(:liquidate, :initialize)
    setholdingshares(ticker, 0)  
end

function liquidate(secid::Int)
    __IllegalContextMessage(:liquidate, :initialize)
    setholdingshares(secid, 0)  
end

function liquidate(symbol::SecuritySymbol)
    __IllegalContextMessage(:liquidate, :initialize)
    setholdingshares(symbol, 0)  
end

function liquidate(security::Security)
    __IllegalContextMessage(:liquidate, :initialize)
    setholdingshares(security, 0)  
end

function liquidate(pos::Position)
    __IllegalContextMessage(:liquidate, :initialize)
    setholdingshares(pos.securitysymbol, 0)  
end

export liquidate

function liquidateportfolio()
    __IllegalContextMessage(:liquidate, :initialize)
    for pos in getallpositions(algorithm.account.portfolio)
        liquidate(pos)
    end
end
export liquidateportfolio


setholdingpct(sym::Symbol, target::Float64) = setholdingpct(String(sym), target)
# Order function to set holdings to a specific level in pct/value/shares
function setholdingpct(ticker::String, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingpct, :initialize)
    setholdingpct(getsecurity(ticker), target)
end

function setholdingpct(secid::Int, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingpct, :initialize)
    setholdingpct(getsecurity(secid), target)
end


function setholdingpct(security::Security, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingpct, :initialize)
    setholdingpct(security.symbol, target)
end

function setholdingpct(symbol::SecuritySymbol, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingpct, :initialize)
    
    if !ispartofuniverse(symbol)
        adduniverse(symbol)
        
        #=Logger.warn("Security: $(symbol.id)/$(symbol.ticker) not present in the universe")
        Logger.warn("Can't place order for security missing in the universe")
        return=#
    end

    initialshares = getposition(symbol).quantity
    
    if target == 0.0 && abs(initialshares) > 0
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
    
    #in case of sell, it was selling more 
    #absvaluetobeinvested = abs(valuetobeinvested)
    roundedshares = valuetobeinvested > 0 ? Int(floor(valuetobeinvested/latestprice)) : Int(ceil(valuetobeinvested/latestprice))
    #roundedshares = absvaluetobeinvested > 0 ? convert(Int, (valuetobeinvested/absvaluetobeinvested) * floor(Int, absvaluetobeinvested/latestprice)) : 0

    openqty = 0

    orders = getopenorders(algorithm.brokerage, symbol)
    if length(orders) > 0
        for order in orders
            openqty += order.quantity
        end
    end
    netroundedshares = roundedshares - openqty

    if abs(netroundedshares) > 0
        placeorder(symbol, netroundedshares)
    end

end

export setholdingpct

setholdingvalue(sym::Symbol, target::Float64) = setholdingvalue(String(sym), target)

function setholdingvalue(secid::Int, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingvalue, :initialize)
    setholdingvalue(getsecurity(secid), target)
end

function setholdingvalue(ticker::String, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingvalue, :initialize)
    setholdingvalue(getsecurity(ticker), target)
end

function setholdingvalue(security::Security, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingvalue, :initialize)
    setholdingvalue(security.symbol, target)
end

function setholdingvalue(symbol::SecuritySymbol, target::Float64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingvalue, :initialize)
    
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
    roundedshares = valuetobeinvested > 0 ? Int(floor(valuetobeinvested/latestprice)) : Int(ceil(valuetobeinvested/latestprice))
    #absvaluetobeinvested = abs(valuetobeinvested)
    #roundedshares = absvaluetobeinvested > 0 ? convert(Int, (valuetobeinvested/absvaluetobeinvested) * floor(Int, absvaluetobeinvested/latestprice)) : 0

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

setholdingshares(sym::Symbol, target::Int64) = setholdingshares(String(sym), target)

function setholdingshares(secid::Int, target::Int64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingshares, :initialize)
    setholdingshares(getsecurity(secid), target)
end

function setholdingshares(ticker::String, target::Int64)
    if !_checkforrebalance()
        return
    end
    __IllegalContextMessage(:setholdingshares, :initialize)
    setholdingshares(getsecurity(ticker), target)
end

function setholdingshares(security::Security, target::Int64)
    __IllegalContextMessage(:setholdingshares, :initialize)

    if !_checkforrebalance()
        return
    end
    setholdingshares(security.symbol, target)
end

function setholdingshares(symbol::SecuritySymbol, target::Int64)
    __IllegalContextMessage(:setholdingshares, :initialize)

    if !_checkforrebalance()
        return
    end
    
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


function settargetportfolio(port::Dict{String, Float64})
    settargetportfolio([(getsecurity(k).symbol.id, v) for (k,v) in port])
end

function settargetportfolio(port::Dict{Int64, Float64})
    settargetportfolio([(k, v) for (k,v) in port])
end

function settargetportfolio(port::Dict{SecuritySymbol, Float64})
    settargetportfolio([(k.id, v) for (k,v) in port])
end

function settargetportfolio(port::Vector{Tuple{Symbol, Float64}})
    settargetportfolio((String(p[1]), p[2]) for p in port)
end

function settargetportfolio(port::Vector{Tuple{String, Float64}})
    settargetportfolio([(getsecurity(v[1]).symbol.id, v[2]) for v in port])
end

function settargetportfolio(port::Vector{Tuple{SecuritySymbol, Float64}})
    settargetportfolio([(v[1].id, v[2]) for v in port])
end

function settargetportfolio(port::Vector{Tuple{Security, Float64}})
    settargetportfolio([(v[1].symbol.id, v[2]) for v in port])
end

function settargetportfolio(port::Vector{Tuple{Int64, Float64}})
    currentpositionids = [pos.securitysymbol.id for pos in getallpositions()]

    expectedpositionsids = [v[1] for v in port]

    diffs = setdiff(currentpositionids, expectedpositionsids)

    for id in diffs
        setholdingpct(id, 0.0)
    end

    #@sync @parallel 
    for v in port
        setholdingpct(v[1], v[2])
    end
end
export settargetportfolio

function hedgeportfolio()
end

getopenorders(sym::Symbol) = getopenorders(String(sym))
function getopenorders(ticker::String)
    __IllegalContextMessage(:getopenorders, :initialize)
    deepcopy(getopenorders(algorithm.brokerage, getsecurity(ticker).symbol))
end

function getopenorders(secid::Int)
    __IllegalContextMessage(:getopenorders, :initialize)
    deepcopy(getopenorders(algorithm.brokerage, getsecurity(secid).symbol))
end

function getopenorders(symbol::SecuritySymbol)
    __IllegalContextMessage(:getopenorders, :initialize)
    deepcopy(getopenorders(algorithm.brokerage, symbol))
end

function getopenorders(security::Security)
    __IllegalContextMessage(:getopenorders, :initialize)
    deepcopy(getopenorders(algorithm.brokerage, security.symbol))
end

function getopenorders()
    __IllegalContextMessage(:getopenorders, :initialize)
    deepcopy(getopenorders(algorithm.brokerage))
end
export getopenorders

cancelopenorders(sym::Symbol) = cancelopenorders(String(sym))

function cancelopenorders(ticker::String)
    __IllegalContextMessage(:cancelopenorders, :initialize)
    security = getsecurity(ticker)
    info("Canceling all orders for $(security.symbol.id)/$(security.symbol.ticker)")
    cancelallorders!(algorithm.brokerage, security.symbol)
end

function cancelopenorders(secid::Int)
    __IllegalContextMessage(:cancelopenorders, :initialize)
    security = getsecurity(secid)
    info("Canceling all orders for $(security.symbol.id)/$(security.symbol.ticker)")
    cancelallorders!(algorithm.brokerage, security.symbol)
end
    
function cancelopenorders(security::Security)
    __IllegalContextMessage(:cancelopenorders, :initialize)
    info("Canceling all orders for $(security.symbol.id)/$(security.symbol.ticker)")
    cancelallorders!(algorithm.brokerage, security.symbol)
end

function cancelopenorders(symbol::SecuritySymbol)
    __IllegalContextMessage(:cancelopenorders, :initialize)
    info("Canceling all orders for $(symbol.id)/$(symbol.ticker)")
    cancelallorders!(algorithm.brokerage, symbol)
end

function cancelopenorders()
    __IllegalContextMessage(:cancelopenorders, :initialize)
    info("Canceling all orders")
    cancelallorders!(algorithm.brokerage)    
end
export cancelopenorders
