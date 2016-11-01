# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("Order.jl")
include("Slippage.jl")
include("Commission.jl")
include("OrderFill.jl")

"""
Type to encapsulate the open orders, all orders and transactions
"""
type Blotter
	openorders::Dict{SecuritySymbol, Vector{Order}}
	orders::Vector{Order}
	transactions::Vector{OrderFill}
end 

"""
Empty blotter construction
"""
Blotter() = Blotter(Dict(), Vector(), Vector())

"""
Function to add order to the blotter
"""
function addorder!(blotter::Blotter, order::Order)
    
    if !haskey(blotter.openorders, order.securitysymbol)
        blotter.openorders[order.securitysymbol] = Vector{Order}()
    end 

    push!(blotter.openorders[order.securitysymbol], order)
    push!(blotter.orders, order)
end

"""
Function to get all the transactions
"""
function gettransactions(blotter::Blotter)
end

"""
Function to get all the open orders
"""
function getopenorders(blotter::Blotter)
    openorders = Vector{Order}()
    for (symbol, orders) in blotter.openorders
        append!(openorders, orders)
    end
    return openorders
end

"""
Function to get all the open orders
"""
function getopenorders(blotter::Blotter, symbol::SecuritySymbol)
    if haskey(blotter.openorders, symbol)
        return blotter.openorders[symbol]
    else 
        Vector{Order}()    
    end
end

"""
Function to remove single order from the blotter
"""
function removeopenorder!(blotter::Blotter, orderid::Integer)
    for (sec, orders) in blotter.openorders
        ind = find(order->(order.id == orderid), orders)
        if isempty(ind)
            continue
        else        
            order = splice!(orders, ind[1])
            return order
        end
    end   
end

"""
Function to remove all open orders for a security from the blotter
"""
function removeallopenorders!(blotter::Blotter, symbol::SecuritySymbol)
    openorders = delete!(blotter.openorders, symbol)
end

"""
Function to generate fill for an order based on latest price, slippage and commission model
"""
function getorderfill(order::Order, slippage::Slippage, commission::Commission, participationrate::Float64, latesttradebar::TradeBar)
    fill = OrderFill(order, latesttradebar.datetime)

    #can't process order with stale data
    if (order.datetime > latesttradebar.datetime) || (order.orderstatus == OrderStatus(Canceled))
        return fill
    end
        
    fill.orderfee = getcommission(order, commission)
    
    lastprice = latesttradebar.close
    volume = latesttradebar.volume

    slippage = getslippage(order, slippage, lastprice)
    # find the execution price based on slippage model
    if order.quantity  < 0
        fill.fillprice = lastprice - slippage
    else
        fill.fillprice = lastprice + slippage
    end

    #find the quantity that can be executed...assume 5% of the total volume
    availablequantity = convert(Int64, participationrate * volume)      

    if availablequantity > abs(order.remainingquantity)
        fill.fillquantity = order.remainingquantity
    else 
        fill.fillquantity = sign(order.remainingquantity) * availablequantity
    end

    #append!(transactions, fill)
    return fill 
end 

