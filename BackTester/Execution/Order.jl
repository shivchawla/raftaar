# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


"""
Encapsulate the order characteristics
"""
mutable struct Order
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
                0, Market, DateTime(1), 0,
                EOD, New,
                0, false, "")

"""
More Constructors
"""
Order(symbol::SecuritySymbol, quantity::Int64, time::DateTime, tag = "") =
                              Order(0, symbol, quantity, quantity, 0,
                                    Market, time,
                                    New, 0, false, tag)

Order(symbol::SecuritySymbol, quantity::Int64) =
            Order(0, symbol, quantity, quantity, 0,
                                    Market, DateTime(1),
                                    New, 0, false, "")

Order(symbol::SecuritySymbol, quantity::Int64, price::Float64) =
            Order(0, symbol, quantity, quantity, price,
                                    Limit, DateTime(1),
                                    New, 0, false,"")

Order(data::Dict{String, Any}) = Order(parse(UInt64, data["id"]),
                                SecuritySymbol(data["securitysymbol"]["id"], data["securitysymbol"]["ticker"]),
                                data["quantity"],
                                data["remainingquantity"],
                                data["price"],
                                eval(parse(data["ordertype"])),
                                DateTime(data["datetime"]),
                                eval(parse(data["orderstatus"])),
                                data["stopprice"],
                                data["stopReached"],
                                data["tag"])

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

function serialize(order::Order)
  return Dict{String, Any}("id" => string(order.id),
                            "securitysymbol" => Dict("id"      => order.securitysymbol.id,
                                                      "ticker" => order.securitysymbol.ticker),
                            "quantity" => order.quantity,
                            "remainingquantity" => order.remainingquantity,
                            "price" => order.price,
                            "ordertype" => string(order.ordertype),
                            "datetime" => order.datetime,
                            "orderstatus" => string(order.orderstatus),
                            "stopprice" => order.stopprice,
                            "stopReached" => order.stopReached,
                            "tag" => order.tag)
end

==(odr1::Order, odr2::Order) = odr1.id == odr2.id &&
                                odr1.securitysymbol == odr2.securitysymbol &&
                                odr1.quantity == odr2.quantity &&
                                odr1.remainingquantity == odr2.remainingquantity &&
                                odr1.price == odr2.price &&
                                odr1.ordertype == odr2.ordertype &&
                                odr1.datetime == odr2.datetime &&
                                odr1.orderstatus == odr2.orderstatus &&
                                odr1.stopprice == odr2.stopprice &&
                                odr1.stopReached == odr2.stopReached &&
                                odr1.tag == odr2.tag
