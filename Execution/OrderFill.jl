# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("Order.jl") 

@enum FillType Default DirectFill

"""
Encapsulate the characteristics of the order fill
"""
type OrderFill
	orderid::Int
	securitysymbol::SecuritySymbol
	datetime::DateTime
	orderfee::Float64
	fillprice::Float64
	fillquantity::Int
	message::String
end

OrderFill(order::Order, datetime::DateTime, orderfee::Float64, message = "") = 
	OrderFill(order.id, order.securitysymbol, datetime, orderfee, 0.0, 0, message)

OrderFill(order::Order, datetime::DateTime) = OrderFill(order, datetime, 0.0)

"""
Function to check if fill closes the order
"""	
function isclosed(fill::OrderFill) 
  return fill.status == OrderStatus(Filled) ||
  		 fill.status == OrderStatus(Canceled) ||
  		 fill.status == OrderStatus(Invalid)
end
   

