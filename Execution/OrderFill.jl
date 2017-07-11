# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


@enum FillType Default DirectFill

"""
Encapsulate the characteristics of the order fill
"""
type OrderFill
	orderid::UInt64
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

OrderFill(securitysymbol::SecuritySymbol, fillprice::Float64, fillquantity::Int, fee::Float64 = 0.0) =
    OrderFill(convert(UInt64, now()), securitysymbol, DateTime(), fee, fillprice, fillquantity, "")

OrderFill(data::BSONObject) = OrderFill(parse(UInt64, data["orderid"]),
										SecuritySymbol(data["securitysymbol"]["id"], data["securitysymbol"]["ticker"]),
										data["datetime"],
										data["orderfee"],
										data["fillprice"],
										data["fillquantity"],
										data["message"])

"""
Function to check if order fill is complete
"""
function isclosed(fill::OrderFill)
  return fill.status == OrderStatus(Filled) ||
  		 fill.status == OrderStatus(Canceled) ||
  		 fill.status == OrderStatus(Invalid)
end

function serialize(orderfill::OrderFill)
  return Dict{String, Any}("orderid" => string(orderfill.orderid),
                            "securitysymbol" => Dict("id"      => orderfill.securitysymbol.id,
                                                      "ticker" => orderfill.securitysymbol.ticker),
                            "datetime" => orderfill.datetime,
                            "orderfee" => orderfill.orderfee,
                            "fillprice" => orderfill.fillprice,
                            "fillquantity" => orderfill.fillquantity,
                            "message" => orderfill.message)
end

==(of1::OrderFill, of2::OrderFill) = of1.orderid == of2.orderid &&
																			of1.securitysymbol == of2.securitysymbol &&
																			of1.datetime == of2.datetime &&
																			of1.orderfee == of2.orderfee &&
																			of1.fillprice == of2.fillprice &&
																			of1.fillquantity == of2.fillquantity &&
																			of1.message == of2.message
