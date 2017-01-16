# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Algorithm/Universe.jl")
#include("../Account/Account.jl")

"""
Types to support brokerge actions
"""
type BacktestBrokerage
	blotter::Blotter
	commission::Commission
	margin::Margin
	slippage::Slippage
	cancelpolicy::CancelPolicy
	participationrate::Float64
end

"""
Empty brokerage constructor
"""
BacktestBrokerage() = BacktestBrokerage(Blotter(), Commission(), Margin(),
							Slippage(), CancelPolicy(EOD), 0.005)
      
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
	brokerage.commission = Commission(eval(parse(commission[1])), commission[2])
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
	brokerage.slippage = Slippage(eval(parse(slippage[1])), slippage[2])
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
	brokerage.cancelpolicy = CancelPolicy(eval(parse(cancelpolicy)))
end 

"""
Function to set participationrate
"""
function setparticipationrate!(brokerage::BacktestBrokerage, participationrate::Float64)
	brokerage.participationrate = participationrate
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
	order.orderstatus = OrderStatus(New)
	addorder!(brokerage.blotter, order)
	order.orderstatus = OrderStatus(Submitted)	

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
	order.orderstatus = OrderStatus(Canceled)
end	

"""
Function to cancel all orders for the symbol
"""
function cancelallorders!(brokerage::BacktestBrokerage, symbol::SecuritySymbol)
	blotter = brokerage.blotter
	
	orders = removeallopenorders!(blotter, symbol)

	for order in orders
		order.orderstatus = OrderStatus(Canceled)
	end
end

"""
Function to cancel all orders
"""
function cancelallorders!(brokerage::BacktestBrokerage)
	blotter = brokerage.blotter

	for symbol in keys(brokerage.blotter.openorders)
		cancelallorders!(brokerage, symbol)
	end
end

"""
Function to get all open orders
"""
function getopenorders(brokerage::BacktestBrokerage)
	[getopenorders(brokerage.blotter)]
end

"""
Function to get open orders for a security
"""
function getopenorders(brokerage::BacktestBrokerage, security::SecuritySymbol)
	[getopenorders(brokerage.blotter, security)]
end

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
		if order.orderstatus == OrderStatus(Canceled)
			removeopenorder!(blotter, order.id)
			continue
		#=else
			#Step 3 check if account has sufficient capital to execute the order
			if !checkforsufficientcapital(brokerage.margin, 
											brokerage.commission, 
											account, order)
				
				removeopenorder!(blotter, order.id)
				continue
			end	=#
		end

		latesttradebar = getlatesttradebar(universe, order.securitysymbol)


		# Get fill based on size or order and latest price
		fill = getorderfill(order, brokerage.slippage, 
							brokerage.commission, brokerage.participationrate, 
							latesttradebar)

		#Append fill with other fills
		push!(fills, fill)

		#Also, update blotter with fill history
		#addtransaction!(blotter, fill)

		#Here create a signal to up .... 

		fillquantity = fill.fillquantity
		order.remainingquantity -= fillquantity
		#update the status of the order based on the fill quantity
		
		if order.remainingquantity == 0
			order.orderstatus = OrderStatus(Filled)	
		elseif order.remainingquantity!=0 && fillquantity!=0
			order.orderstatus = OrderStatus(PartiallyFilled)
		end
			
		#remove order from pending orders if fill is complete
		if order.orderstatus == OrderStatus(Filled)
			removeopenorder!(brokerage.blotter, order.id)
 		end
	
	end	

	return fills

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

	freemargin = getmarginremaining(account, margin, order)
	
	#Pro-rate the initial margin required for order based on how much has already been filled
    initialmarginrequired = abs(order.remainingquantity)/abs(order.quantity) * getinitialmarginfororder(margin, order, commission)
   
    if initialmarginrequired > freemargin
    	return false
	end

	return true

end

"""
Function to generate unique orderid
"""
generateorderid(order::Order) = object_id(order)







