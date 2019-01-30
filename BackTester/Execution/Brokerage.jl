# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Algorithm/Universe.jl")
#include("../Account/Account.jl")

"""
Types to support brokerage actions
"""
mutable struct BacktestBrokerage
	blotter::Blotter
	commission::Commission
	margin::Margin
	slippage::Slippage
	cancelpolicy::CancelPolicy
	executionpolicy::ExecutionPolicy
	participationrate::Float64
end

"""
Empty brokerage constructor
"""
BacktestBrokerage() = BacktestBrokerage(Blotter(), Commission(), Margin(),
							Slippage(), EOD, EP_Close, 0.05)

BacktestBrokerage(data::Dict{String, Any}) = BacktestBrokerage(
												haskey(data, "blotter") ? Blotter(data["blotter"]) : Blotter(), 
												haskey(data, "commission") ? Commission(data["commission"]) : Commission,
												haskey(data, "margin") ? Margin(data["margin"]) : Margin(), 
												haskey(data, "slippage") ? Slippage(data["slippage"]) : Slippage(),
												haskey(data, "cancelpolicy") ? eval(Meta.parse(data["cancelpolicy"])) : EOD,
												haskey(data, "executionpolicy") ? eval(Meta.parse(data["executionpolicy"])) : EP_Close,
												get(data, "participationrate", 0.05)
											)

"""
Function to set commission model
"""
function setcommission!(brokerage::BacktestBrokerage, commission::Commission)
	brokerage.commission = commission
end

"""
Function to set commission model
"""
function setcommission!(brokerage::BacktestBrokerage, commission::Tuple{String, Float64})
	brokerage.commission = Commission(eval(Meta.parse(commission[1])), commission[2])
end

"""
Function to set margin model
"""
function setmargin!(brokerage::BacktestBrokerage, margin::Margin)
	brokerage.margin = margin
end

"""
Function to set slippage model
"""
function setslippage!(brokerage::BacktestBrokerage, slippage::Slippage)
	brokerage.slippage = slippage
end

function setslippage!(brokerage::BacktestBrokerage, slippage::Tuple{String, Float64})
	brokerage.slippage = Slippage(eval(Meta.parse(slippage[1])), slippage[2])
end

"""
Function to set cancel policy
"""
function setcancelpolicy!(brokerage::BacktestBrokerage, cancelpolicy::CancelPolicy)
	brokerage.cancelpolicy = cancelpolicy
end

"""
Function to set cancelpolicy model
"""
function setcancelpolicy!(brokerage::BacktestBrokerage, cancelpolicy::String)
	brokerage.cancelpolicy = eval(Meta.parse(cancelpolicy))
end

"""
Function to set participationrate
"""
function setparticipationrate!(brokerage::BacktestBrokerage, participationrate::Float64)
	brokerage.participationrate = participationrate
end

"""
Function to set execution policy
"""
function setexecutionpolicy!(brokerage::BacktestBrokerage, executionpolicy::String)
	brokerage.executionpolicy = eval(Meta.parse("EP_"*executionpolicy))
end

function setexecutionpolicy!(brokerage::BacktestBrokerage, executionpolicy::ExecutionPolicy)
	brokerage.executionpolicy = executionpolicy
end

"""
Function to get margin for the order
"""
function getmargin(brokerage::BacktestBrokerage, order::Order)
end

"""
Function to place order
"""
function placeorder!(brokerage::BacktestBrokerage, order::Order)

	###################
	#should do sanity checks if order can be placed....
	#only then place the order
	###################


	#assign an order id
	order.id = generateorderid(order)
	order.orderstatus = New
	addorder!(brokerage.blotter, order)
	order.orderstatus = Submitted

	return order.id
end

#function updateorder(brokerage::BacktestBrokerage, order::Order, quantity::Int64)
#	getorderstatus()
#end

"""
Function to cancel an order based on orderid
"""
function cancelorder(brokerage::BacktestBrokerage, orderid::Integer)
	order = removeopenorder!(brokerage.blotter, orderid)
	order.orderstatus = Canceled
end

"""
Function to cancel all orders for the symbol
"""
function cancelallorders!(brokerage::BacktestBrokerage, symbol::SecuritySymbol)
	blotter = brokerage.blotter

	ordersDict = removeallopenorders!(blotter, symbol)

	for (symbol, orders) in ordersDict
		for order in orders
			order.orderstatus = Canceled
		end
	end
end

"""
Function to cancel all orders
"""
function cancelallorders!(brokerage::BacktestBrokerage)
	blotter = brokerage.blotter

	for symbol in keys(brokerage.blotter)
		cancelallorders!(brokerage, symbol)
	end
end

"""
Function to get all open orders
"""
function getopenorders(brokerage::BacktestBrokerage)
	getopenorders(brokerage.blotter)
end

"""
Function to get open orders for a security
"""
function getopenorders(brokerage::BacktestBrokerage, security::SecuritySymbol)
	getopenorders(brokerage.blotter, security)
end

export getopenorders

"""
Function to update pending orders
"""
function updatependingorders!(brokerage::BacktestBrokerage, universe::Universe, account::Account)

	blotter = brokerage.blotter
	#Step 1: Get all pending orders
	openorders = getopenorders(blotter)

	fills = Vector{OrderFill}()

	#Step 2: Check if the orders ae actually pending and not Canceled
	#This will not happen but a good sanity check
	for order in openorders
		if order.orderstatus == Canceled
			removeopenorder!(blotter, order.id)
			continue
		else
			#Step 3 check if account has sufficient capital to execute the order
			if !checkforsufficientcapital(brokerage.margin,
											brokerage.commission,
											account, order)

				removeopenorder!(blotter, order.id)
				continue
			end
		end

		latesttradebar = getlatesttradebar(universe, order.securitysymbol)


		# Get fill based on size of order/latest tradebar/execution policy
		fill = getorderfill(order, brokerage.slippage, brokerage.commission, brokerage.executionpolicy, 
							brokerage.participationrate, latesttradebar)

		#Append fill with other fills
		#check if fill has any quantity
		if(abs(fill.fillquantity) > 0)
			push!(fills, fill)
		end

		#Here create a signal to up ....

		fillquantity = fill.fillquantity
		order.remainingquantity -= fillquantity
		#update the status of the order based on the fill quantity

		if order.remainingquantity == 0
			order.orderstatus = Filled
		elseif order.remainingquantity!=0 && fillquantity!=0
			order.orderstatus = PartiallyFilled
		end

		#remove order from pending orders if fill is complete
		if order.orderstatus == Filled
			removeopenorder!(brokerage.blotter, order.id)
 		end

	end

	return fills

end

"""
Function to update pending orders for splits
"""
function updatependingorders_splits!(brokerage::BacktestBrokerage, adjustments::Dict{SecuritySymbol, Adjustment})
	for (symbol, adjustment) in adjustments
		if(adjustment.adjustmenttype != 17.0)

			pendingorders = getopenorders(brokerage.blotter, symbol)

			for order in pendingorders
				order.quantity = Int(round(order.quantity * (1.0/adjustment.adjustmentfactor)))
				order.price = order.price * adjustment.adjustmentfactor
			end

		end
	end
end

"""
Check if sufficient cash/margin is available to complete the transaction
Logic taken from LEAN
"""
function checkforsufficientcapital(margin::Margin, commission::Commission, account::Account, order::Order)

	if order.quantity == 0
		return true
	end

	# When order only reduces or closes a security position, capital is always sufficient
    if (account.portfolio[order.securitysymbol].quantity * order.quantity < 0
    		&& abs(account.portfolio[order.securitysymbol].quantity) >= abs(order.quantity))
    	return true
	end

	return true

	freemargin = getmarginremaining(account, margin, order)

	#Pro-rate the initial margin required for order based on how much has already been filled
    initialmarginrequired = abs(order.remainingquantity)/abs(order.quantity) * getinitialmarginfororder(margin, order, commission)

    if initialmarginrequired > freemargin
    	return false
	end

	return true

end

function updateorders_cancelpolicy!(brokerage::BacktestBrokerage)
	blotter = brokerage.blotter
	#Step 1: Get all pending orders
	openorders = getopenorders(blotter)

	if(brokerage.cancelpolicy == EOD)
		cancelallorders!(brokerage)
	end
end

export updateorders_cancelpolicy!

"""
Function to generate unique orderid
"""
generateorderid(order::Order) = objectid(order)

function serialize(brokerage::BacktestBrokerage)
  return Dict{String, Any}("blotter"            => serialize(brokerage.blotter),
                            "commission"        => serialize(brokerage.commission),
                            "margin"            => serialize(brokerage.margin),
                            "slippage"          => serialize(brokerage.slippage),
                            "cancelpolicy"      => string(brokerage.cancelpolicy),
                            "executionpolicy"   => string(brokerage.executionpolicy),
                            "participationrate" => brokerage.participationrate)
end

==(bk1::BacktestBrokerage, bk2::BacktestBrokerage) = bk1.blotter == bk2.blotter &&
											bk1.commission == bk2.commission &&
											bk1.margin == bk2.margin &&
											bk1.slippage == bk2.slippage &&
											bk1.cancelpolicy == bk2.cancelpolicy &&
											bk1.executionpolicy == bk2.executionpolicy &&
											bk1.participationrate == bk2.participationrate
