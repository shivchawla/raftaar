
@enum CancelPolicy
	Day = 1
	Never = 2


type Blotter
	openorders::Dict{ASCIIString, Order}
	orders::Vector{Order}
	feemodel::FeeModel
	cancelpolicy::CancelPolicy
	slippage::SlippageModel	
end 

function cancelallopenorders(blotter::Blotter)
	for (id, order) in enumerate(openOrders)
			CancelOrder(order)
	end
end

function CancelOrder(blotter::Blotter, id::ASCIIString)
		
end

function getopenorders(blotter::Blotter)
	return blotter.openorders
end

