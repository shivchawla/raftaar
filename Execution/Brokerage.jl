
include("OrderFill.jl")
include("Blotter.jl")
include("Commission.jl")
include("Margin.jl")
include("Slippage.jl")
include("Order.jl")
include("../Algorithm/Universe.jl")

@enum CancelPolicy EOD GTC 

type BacktestBrokerage
	blotter::Blotter
	commission::Commission
	margin::Margin
	slippage::Slippage
	cancelpolicy::CancelPolicy
	participationrate::Float64
end

BacktestBrokerage() = BacktestBrokerage(Blotter(), Commission(), Margin(),
							Slippage(), CancelPolicy(EOD), 0.005)
      
function setcommission!(brokerage::BacktestBrokerage, commission::Commission)
	brokerage.commission = commission
end 

function setmargin!(brokerage::BacktestBrokerage, commission::Commission)
	brokerage.margin = margin
end

function setslippage!(brokerage::BacktestBrokerage, slippage::Slippage)
	brokerage.slippage = slippage
end

function setcancelpolicy!(brokerage::BacktestBrokerage, cancelpolicy::CancelPolicy)
	brokerage.cancelpolicy = cancelpolicy
end

function setparticipationrate!(brokerage::BacktestBrokerage, participationrate::Float64)
	brokerage.participationrate = participationrate
end

function getmargin(brokerage::BacktestBrokerage, order::Order)
end

function placeorder(brokerage::BacktestBrokerage, order::Order)
	
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

function cancelorder(brokerage::BacktestBrokerage, orderid::Integer)
	order = removeopenorder!(brokerage.blotter, orderid)
	order.orderstatus = OrderStatus(Canceled)
end	


function cancelallorders!(brokerage::BacktestBrokerage, symbol::SecuritySymbol)
	blotter = brokerage.blotter
	
	orders = removeallopenorders!(blotter, symbol)

	for order in orders
		order.orderstatus = OrderStatus(Canceled)
	end
end

function cancelallorders!(brokerage::BacktestBrokerage)
	blotter = brokerage.blotter

	for symbol in keys(brokerage.blotter.openorders)
		cancelallorders!(brokerage, symbol)
	end
end

function getopenorders(brokerage::BacktestBrokerage)
	[getopenorders(brokerage.blotter)]
end

function getopenorders(brokerage::BacktestBrokerage, security::SecuritySymbol)
	[getopenorders(brokerage.blotter, security)]
end

function updatependingorders!(brokerage::BacktestBrokerage, universe::Universe)

	blotter = brokerage.blotter
	#Step 1: Get all pending orders
	openorders = getopenorders(blotter)

	fills = Vector{OrderFill}()

	#Step 2: Check if the orders ae actually pending nd not Canceled
	#this may not happen but a good sanity check
	for order in openorders
		if order.orderstatus == OrderStatus(Canceled)
			removeopenorder!(blotter, order.id)
			continue
		#else
			#Step 3 check if account has sufficient capital to execute the order
		end

		if haskey(universe.tradebars, order.securitysymbol)
			latestprice = universe.tradebars[order.securitysymbol]
		else
			continue
		end

		####compare the time of latestprice vs order time

		fill = getorderfill(order, brokerage.slippage, 
							brokerage.commission, brokerage.participationrate, 
							latestprice[1])

		push!(fills, fill)
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

generateorderid(order::Order) = object_id(order)







