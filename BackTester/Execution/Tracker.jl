const OrderTracker = Dict{Date, Vector{Order}}
const TransactionTracker = Dict{Date, Vector{OrderFill}}

OrderTracker(data::Dict{String, Any}) = Dict([(Date(date), [Order(order) for order in vectorOrder]) for (date, vectorOrder) in data])

TransactionTracker(data::Dict{String, Any}) = Dict([(Date(date), [OrderFill(orderfill) for orderfill in vectorOrderFill]) for (date, vectorOrderFill) in data])

function serialize(transactiontracker::TransactionTracker)
  temp = Dict{String, Any}()
  for (date, orderfills) in transactiontracker
    temp[string(date)] = [serialize(orderfill) for orderfill in orderfills]
  end
  return temp
end

function serialize(ordertracker::OrderTracker)
  temp = Dict{String, Any}()
  for (date, vectorOrders) in ordertracker
    temp[string(date)] = [serialize(order) for order in vectorOrders]
  end
  return temp
end


"""
Function to track the transactions at each time step (single transaction)
"""
function updateTransactionTracker!(transactionTracker::TransactionTracker, fill::OrderFill)
    
    if haskey(transactionTracker, Date(fill.datetime))
		push!(transactionTracker[Date(fill.datetime)], fill)
	else
		transactionTracker[Date(fill.datetime)] = [fill]
	end
end


"""
Function to track the transactions at each time step
"""
function updateTransactionTracker!(transactionTracker::TransactionTracker, fills::Vector{OrderFill})
    
	#update transaction tracker
	#This is not the right location
	for fill in fills
		updateTransactionTracker!(transactionTracker, fill)
	end
   
end
