
include("Order.jl") 

@enum FillType Default DirectFill

type OrderFill
	orderid::Integer
	securitysymbol::SecuritySymbol
	datetime::DateTime
	orderfee::Float64
	fillprice::Float64
	fillquantity::Int64
	message::ASCIIString
end

OrderFill(order::Order, datetime::DateTime, orderfee::Float64, message = "") = 
	OrderFill(order.id, order.securitysymbol, datetime, orderfee, 0.0, 0, message)

OrderFill(order::Order, datetime::DateTime) = OrderFill(order, datetime, 0.0)
	
function isclosed(fill::OrderFill) 
  return fill.status == OrderStatus(Filled) ||
  		 fill.status == OrderStatus(Canceled) ||
  		 fill.status == OrderStatus(Invalid)
end
   

