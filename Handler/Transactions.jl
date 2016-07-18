type TransactionHandler
	ordertickets::Dict{ASCIIString, OrderTicket}
end


function handlefill(transactionhandler::TransactionHandler, algorithm::Algorithm, fill::OrderFill)
	order = getorder(fill.orderid)  
	if isempty(order)
		"MSG: unable to locate order"
		return
	end
	
	order.status = fill.status

	if fill.status == OrderStatus.Filled || fill.status == OrderStatus.PartiallyFilled
		security = algorithm.universe[fill.symbol]
   
        updateportfolioforfill(algorithm.portfolio, fill)
        "updatetradebuilderforfill(algorithm.tradebuilder, fill)"

    end    

    "update order ticket for fill()........"
    
    "update result for fill "
       
end








