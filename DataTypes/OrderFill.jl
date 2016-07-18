type OrderFill
	orderid::ASCIString
	symbol::SecuritySymbol
	datetime::DateTime
	status::OrderStatus
	orderfee::Float64
	fillprice::Float64
	fillquantity::Int64
	message::ASCIString

	function OrderFill(orderid::ASCIString, symbol::SecuritySymbol, datetime::DateTime, 
						status::OrderStatus, orderfee::Float64, fillprice::Float64,
						fillquantity::Int64, message::ASCIString)
		new(orderId, symbol, datetime, status, orderfee, fillprice, fillquantity, message)
	end
end

OrderFill(order::Order, datetime::DateTime, orderfee::Float64, message = "") = 
	OrderFill(order.id, order.symbol, datetime, order.status, orderfee, 0.0, 0, message)


OrderFill(order::Order, datetime::DateTime) = OrderFill(order, datetime, 0)

OrderFill(order::Order) = OrderFill(order, DateTime())
	

function isclosed(fill::OrderFill) 
  return (fill.status == OrderStatus.Filled ||
  fill.status == OrderStatus.Canceled ||
  fill.status == OrderStatus.Invalid)
end

