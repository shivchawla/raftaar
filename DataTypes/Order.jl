
@enum OrderType
  Limit = 1 #Limit Order
  Market = 2 #Market Order
  StopLimit = 3 #Stop Limit Order : triggers a Limit Order on crossing stop price
  StopMarket = 4 #Stop Market Order :triggers a market Order on crossing stop price
  MarketOnOpen = 5 #Market on Open: executes trade at exchange open
  MarketOnClose = 6 #Market on Close: executes trade at exchange close

@enum OrderDuration
  GTC = 1  #Good-till-Canceled
  Day = 2  #Canceled at EOD

@enum OrderStatus
  New = 0 #Pre-Submission
  Submitted = 1 #Submitted to market
  PartiallyFilled = 2 #Partially Filled
  Filled = 3 #Completed
  Canceled  = 4 #Canceled before Filled
  None = 5 #No Order State
  Invalid  = 6 #Order invalidated before reaching market

"Order"
type Order 
  id::ASCIIString # unique order id for submission/tracking
  symbol::SecuritySymbol # security symbol (NIFTY, VOLTAS)
  quantity::Int64 # abs. value of position change targeted
  price::Float64 # limit price, set to NaN for market order
  ordertype::OrderType# :market :limit
  datetime::DateTime # date-time when order was created
  duration::OrderDuration #:GTC
  status::OrderStatus # :pending :complete :cancelled
  stopprice::Float64 # stop price
  stopReached::Bool # :
  tag::ASCIIString # custom string 

  function Order(id::ASCIIString, symbol::SecuritySymbol, quantity::Int64,
                price::Float64, ordertype::OrdertType, datetime::DateTime,
                duration::OrderDuration, status::OrderStatus,
                stopprice::Float64, stopreached::Bool, tag::ASCIIString)

    new(id, symbol, quantity, price, ordertype, datetime,
        orderduration, orderstatus, stopprice,
        stopreached, tag)
  end
end

Order() = Order(ASCIIString(), SecuritySymbol(), 0, 
                0, OrderType.Market, DateTime(), 0, 
                OrderDuration.Day, OrderStatus.New, 
                0, false, ASCIIString())

Order(symbol::SecuritySymbol, quantity::Int64, time::DateTime, tag = "") = 
                              Order(ASCIIString(), symbol, quantity, 0, 
                                    OrderType.Market, time, OrderDuration.Day,
                                    OrderStatus.New, 0, false, tag)

Order(symbol::SecuritySymbol, quantity::Int64) =
            Order(ASCIIString(), symbol, quantity, 0, 
                                    OrderType.Market, DateTime(), OrderDuration.Day,
                                    OrderStatus.New, 0, false, ASCIIString())

Order(symbol::SecuritySymbol, quantity::Int64, price::Float64) =
            Order(ASCIIString(), symbol, quantity, price, 
                                    OrderType.Limit, DateTime(), OrderDuration.Day,
                                    OrderStatus.New, 0, false, ASCIIString())
            

LimitOrder(symbol::SecuritySymbol, quantity::Int64, price::Float64) = Order(symbol, quantity, price)
  
MarketOrder(symbol::SecuritySymbol, quantity::Int64) = Order(symbol, quantity)
  
function StopMarketOrder(symbol::SecuritySymbol, quantity::Int64, stopPrice::Float64)
  order = Order(symbol, quantity)
  order.ordertype = OrderType.StopMarket
  order.stopprice = stopprice
  return order
end

function StopLimitOrder(symbol::SecuritySymbol, quantity::Int64, price::Float64, stopprice::Float64)
  order = Order(symbol, quantity, price)
  order.ordertype = OrderType.StopMarket
  order.stopprice = stopprice
  return order
end

function MarketOnCloseOrder(symbol::SecuritySymbol, quantity::Int64)
  order = Order(symbol, quantity)
  order.ordertype = OrderType.MarketOnClose
  return order
end

function MarketOnOpenOrder(symbol::SecuritySymbol, quantity::Int64)
  order = Order(symbol, quantity)
  order.ordertype = OrderType.MarketOnOpen
  return order
end

"Check if order status is CLOSED"
function isclosed(order::Order) 
  return (order.status == OrderStatus.Filled ||
  order.status == OrderStatus.Canceled ||
  order.status == OrderStatus.Invalid)
end    

"Change order status to 'Canceled'"
setcanceled!(order::Order) order.status = OrderStatus.Canceled

"Change order status to invalid"
setinvalid!(order::Order) order.status = OrderStatus.Invalid


function getordervalue(order::Order)
  return order.quantity * 
end

""Signed position change in the Order object"
function getorderposchg(orde::Order)
  if orde.side == :buy
    return orde.quantity
  end
  if orde.side == :sell
    return -orde.quantity
  end
  error("Unknown order side")
end

# "Completed (closed) trade type."
# immutable ClosedTrade
#   topen::datetime
#   tclose::datetime
#   popen::Float64
#   pclose::Float64
#   tradeside::Symbol
#   tradequantity::Int64
# end



# """
# Array-like type keeping all open trades,
# thus holding current (actual) position information with open prices.
# Multiple entries may appear when an order is filled in parts.
# """
# immutable OpenTrades <: TradingStructures
#   quantities::Vector{Int64} # abs. value of outstanding position
#   openprices::Vector{Float64}
#   sides::Vector{Symbol} # :long :short

#   ### TODO inner constructor checks (similar to TimeArray in TimeSeries.jl)
# end

# "OpenTrades object without outstanding position"
# emptyopentrades() = OpenTrades([0], [NaN], [:long])

# "Get total outstanding position from `OpenTrades`-object."
# getopenposition(otrades::OpenTrades) = sum(otrades.quantities)


### use array of Trade-objects instead of what is below?
### (append closed trades to it)

# """
# Array type keeping trades information, both open and completed.
# Since it contains open trades, it holds
# current (actual) position information with open prices.
# Multiple open entries may appear when an order is filled in parts.
# """
# immutable TradesArray <: TradingStructures
#   entertimes::Vector{datetime}
#   exittimes::Union(Vector{datetime}, Symbol) # :open of exit datetime
#   quantities::Vector{Int64} # abs. value of outstanding position
#   openprices::Vector{Float64}
#   closeprices::Vector{Float64}
#   sides::Vector{Symbol} # :long :short

#   ### TODO inner constructor checks (similar to TimeArray in TimeSeries.jl)
# end

# "Empty TradesArray object"
# emptytrades() = TradesArray(Array(datetime, 0), Array(datetime, 0),
#                             Array(Int64, 0),
#                             Array(Float64, 0), Array(Float64, 0),
#                             Array(Symbol, 0))

# "Get total outstanding position from `TradesArray`-object."
# getopenposition(trarr::TradesArray) = sum(otrades.quantities)
