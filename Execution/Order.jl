# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


"""
Encapsulate the order characteristics    
"""
type Order 
  id::UInt64 # unique order id for submission/tracking
  securitysymbol::SecuritySymbol # security symbol (NIFTY, VOLTAS)
  quantity::Int64 # value of position change targeted
  remainingquantity::Int64
  price::Float64 # limit price, set to NaN for market order
  ordertype::OrderType# :market :limit
  datetime::DateTime # date-time when order was created
  orderstatus::OrderStatus # :pending :complete :cancelled
  stopprice::Float64 # stop price
  stopReached::Bool # :
  tag::String # custom string 
end

"""
Empty Constructor
"""
Order() = Order(0, SecuritySymbol(), 0, 0,
                0, OrderType(Market), DateTime(), 0, 
                OrderDuration(EOD), OrderStatus(New), 
                0, false, "")

"""
More Constructors
"""
Order(symbol::SecuritySymbol, quantity::Int64, time::DateTime, tag = "") = 
                              Order(0, symbol, quantity, quantity, 0,
                                    OrderType(Market), time,
                                    OrderStatus(New), 0, false, tag)

Order(symbol::SecuritySymbol, quantity::Int64) =
            Order(0, symbol, quantity, quantity, 0,
                                    OrderType(Market), DateTime(), 
                                    OrderStatus(New), 0, false, "")

Order(symbol::SecuritySymbol, quantity::Int64, price::Float64) =
            Order(0, symbol, quantity, quantity, price, 
                                    OrderType(Limit), DateTime(),
                                    OrderStatus(New), 0, false,"")
            
#LimitOrder(symbol::SecuritySymbol, quantity::Int64, price::Float64) = Order(symbol, quantity, price)
  
#MarketOrder(symbol::SecuritySymbol, quantity::Int64) = Order(symbol, quantity)
  



#=function StopMarketOrder(symbol::SecuritySymbol, quantity::Int64, stopPrice::Float64)
  order = Order(symbol, quantity)
  order.ordertype = OrderType(StopMarket)
  order.stopprice = stopprice
  return order
end

function StopLimitOrder(symbol::SecuritySymbol, quantity::Int64, price::Float64, stopprice::Float64)
  order = Order(symbol, quantity, price)
  order.ordertype = OrderType(StopMarket)
  order.stopprice = stopprice
  return order
end

function MarketOnCloseOrder(symbol::SecuritySymbol, quantity::Int64)
  order = Order(symbol, quantity)
  order.ordertype = OrderType(MarketOnClose)
  return order
end

function MarketOnOpenOrder(symbol::SecuritySymbol, quantity::Int64)
  order = Order(symbol, quantity)
  order.ordertype = OrderType(MarketOnOpen)
  return order
end

#Check if order status is CLOSED
function isclosed(order::Order) 
  return order.status == OrderStatus(Filled) || 
         order.status == OrderStatus(Canceled) || 
         order.status == OrderStatus(Invalid)
end=#    

#Change order status to 'Canceled'
#=
setcanceled!(order::Order) order.status = OrderStatus(Canceled)

#Change order status to invalid
setinvalid!(order::Order) order.status = OrderStatus(Invalid)

=#
function getordervalue(order::Order)
  return order.quantity  
end


