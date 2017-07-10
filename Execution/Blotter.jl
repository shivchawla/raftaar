# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("Order.jl")

import Base.convert

"""
Type to encapsulate the open orders, all orders and transactions
"""
typealias OrderTracker Dict{Date, Vector{Order}}
typealias TransactionTracker Dict{Date, Vector{OrderFill}}

type Blotter
	openorders::Dict{SecuritySymbol, Vector{Order}}
	ordertracker::OrderTracker
	#transactiontracker::TransactionTracker
end

"""
Empty blotter construction
"""
Blotter() = Blotter(Dict(), OrderTracker())

Blotter(data::BSONObject) = Blotter(
															Dict([(SecuritySymbol(parse(Int64, id)), [Order(order) for order in vectorOrder]) for (id, vectorOrder) in data["openorders"]]),
															OrderTracker(data["ordertracker"])
														)

OrderTracker(data::BSONObject) = Dict([(Date(date), [Order(order) for order in vectorOrder]) for (date, vectorOrder) in data])

TransactionTracker(data::BSONObject) = Dict([(Date(date), [OrderFill(orderfill) for orderfill in vectorOrderFill]) for (date, vectorOrderFill) in data])

"""
Function to add order to the blotter
"""
function addorder!(blotter::Blotter, order::Order)

    if !haskey(blotter.openorders, order.securitysymbol)
        blotter.openorders[order.securitysymbol] = Vector{Order}()
    end

    push!(blotter.openorders[order.securitysymbol], order)

    ordertracker = blotter.ordertracker

    dateoforder = Date(order.datetime)
    if !haskey(ordertracker, dateoforder)
        ordertracker[dateoforder] = [order]
    end

    push!(ordertracker[dateoforder], order)

end

"""
Function to get all the transactions
"""
function gettransactions(blotter::Blotter)
    blotter.transactiontracker
end

"""
Function to get all the open orders
"""
function getopenorders(blotter::Blotter)
    openorders = Vector{Order}()
    for (symbol, oos) in blotter.openorders
        append!(openorders, oos)
    end

    return openorders
end

"""
Function to get all the open orders
"""
function getopenorders(blotter::Blotter, symbol::SecuritySymbol)
		#=
    if haskey(blotter.openorders, symbol)
        return blotter.openorders[symbol]
    else
        Vector{Order}()
    end
		=#
		return get(blotter.openorders, symbol, Vector{Order}())
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
    if (order.datetime > latesttradebar.datetime) || (order.orderstatus == OrderStatus(Canceled)) || latesttradebar.datetime == DateTime()
        return fill
    end

    lastprice = latesttradebar.close
    volume = latesttradebar.volume

    if isnan(lastprice) || isnan(volume) || lastprice <= 0.0 || volume <= 0
        return fill
    end

    fill.orderfee = getcommission(order, commission)

    slippage = getslippage(order, slippage, lastprice)
    # find the execution price based on slippage model
    if order.quantity  < 0
        fill.fillprice = lastprice - slippage
    else
        fill.fillprice = lastprice + slippage
    end

    #find the quantity that can be executed...assume 5% of the total volume
    availablequantity = Int(round(participationrate * volume))

    if availablequantity > abs(order.remainingquantity)
        fill.fillquantity = order.remainingquantity
    else
        fill.fillquantity = sign(order.remainingquantity) * availablequantity
    end

    return fill
end


"""
Function to record fill history
"""
function addtransaction!(blotter::Blotter, fill::OrderFill)

    dateoffill = Date(fill.datetime)

    if haskey(blotter.transactiontracker, dateoffill)
        push!(blotter.transactiontracker[dateoffill], fill)
    else
        blotter.transactiontracker[dateoffill] = [fill]
    end

end

function serialize(blotter::Blotter)
  temp = Dict{String, Any}()
  for (symbol, vectorOrders) in blotter.openorders
    temp[string(symbol.id)] = [serialize(eachOrder) for eachOrder in vectorOrders]
  end
  return Dict{String, Any}("openorders"     => temp,
														"ordertracker"	=> serialize(blotter.ordertracker))
end

function serialize(transactiontracker::TransactionTracker)
  temp = Dict{String, Any}()
  for (date, orderfills) in transactiontracker
    temp[string(date)] = [serialize(orderfill) for orderfill in orderfills]
  end
  return temp
end

function serialize(ordertracker::OrderTracker)
  temp = Dict{String, Any}()
  for (date, vectorOrders) in ordertracker
    temp[string(date)] = [serialize(order) for order in vectorOrders]
  end
  return temp
end

==(blt1::Blotter, blt2::Blotter) = blt1.openorders == blt2.openorders &&
																		blt1.ordertracker == blt2.ordertracker
