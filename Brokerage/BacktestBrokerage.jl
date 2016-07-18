type BacktestBrokerage "transaction handler + fill model + "
	algorithm::Algorithm
	pendingorders::Dict{ASCIIString, Order}
	blotter::Blotter
	
	
	BacktestBrokerage(algorithm::Algorithm, transactionhandler::TransactionHandler, pendingorders::Dict{ASCIIString, Order})
		new(algorithm, transactionhandler, pendingorders)
end

BacktestBrokerage(algorithm::Algorithm) = BacktestBrokerage(algorithm, TransactionHandler(), {})

function getopenorders(brokerage::BacktestBrokerage)
	return Blotter.getopenorders(brokerage.algorithm.blotter)
end

function getaccountholdings(brokerage::BacktestBrokerage)
	return brokerage.algorithm.portfolio.positions
end

function setpendingorders(order::Order, brokerage::BacktestBrokerage)
	brokerage.pendingorders[order.id] = Deep.Copy(order)
end

function placeorder(order::Order, brokerage::BacktestBrokerage)

	if order.status == OrderStatus.New
		setpendingorders(order)

		"In Backtest, send it direcrly to transaction manager to process"

    	fill = OrderFill(order, brokerage.algorithm.datetime)
    	fill.status = OrderStatus.Submitted

    	handlefill(brokerage.transactionhandler, fill)

    	return true
	end

	return false

end

function updateorder(order::Order, brokerage::BacktestBrokerage)
	
	if haskey(brokerage.pendingorders, order.id) "is there a pending order already"
		setpendingorders(order)

		"In Backtest, send it direcrly to transaction manager to process"

    	fill = OrderFill(order, brokerage.algorithm.datetime)
    	fill.status = OrderStatus.Submitted

    	handlefill(brokerage.transactionhandler, fill)

    	return true
	end
	return false
end


function cancelorder(order::Order, brokerage::BacktestBrokerage)
	
	if !remove(brokerage.pendingorders, order.id) "is there a pending order already"
		return false
	end

	"In Backtest, send it direcrly to transaction manager to process"

	fill = OrderFill(order, brokerage.algorithm.datetime)
	fill.status = OrderStatus.Canceled

	handlefill(brokerage.transactionhandler, fill)
	return true

end

function getfill(order::Order, brokerage::BacktestBrokerage)
    
    datetime = brokerage.algorithm.datetime

    fill = OrderFill(order, datetime, 0.0)

    if (order.Status == OrderStatus.Canceled) return fill

	"make sure the exchange is open before filling"
    if (!isexchangeopen(order.symbol)) return fill

	if order.ordertype == OrderType.Market
		fee = brokerage.algorithm.algoparameters.feemodel
		margin = brokerage.algorithm.algoparameters.marginmodel
		return getfillformarketorder(order, fill, fee, margin)
	end	

end

function getfillformarketorder!(order, fillfee, margin)
    
    "Order [fill]price for a market order model is the current security price"
    fill.fillprice = getprice(order.symbol).current
    fill.status = OrderStatus.Filled

    "Calculate the model slippage: e.g. 0.01c"
    slip = getslippageapproximation(order, margin)

    "Apply slippage"
    if order.quantity > 0
    	fill.fillprice += slip
    else if order.quantity < 0
    	fill.fillprice -= slip

        
    "assume the order completely filled"
    if fill.status == OrderStatus.Filled
        fill.fillquantity = order.quantity
        fill.orderfee = getorderfee(order, fee)
    
    return fill;
end

function scanpendingorders!(brokerage::BacktestBrokerage)
	pendingorders = brokerage.pendingorders
	algorithm = brokerage.algorithm

	for (orderid, order) in enumerate(pendingorders)
		
		if isclosed(order)
			delete(pendingorders, orderid)
			continue
		end


		"All orders except market orders are processed in the next bar"
		if order.datetime == algorithm.datetime && order.ordertype != OrderType.Market
        	continue
        end	

        if !haskey(algorithm.universe, order.symbol)
        	"MSG"
        	delete(pendingorders, orderid)
        	continue
    	end

    	if !canexecuteorder(getbrokeragemodel(algorithm), order) 
    		continue
		end

		sufficientbuyingpower = getsufficientcapitalfororder(algorithm.portfolio, order);

		if sufficientbuyingpower
			fill = generatefill(order)
		else
			"MSG: not sufficient buying power"
			order.status = OrderStatus.Invalid
		end

		if order.status != fill.status || fill.quantity !=0
			handlefill(brokerage.transactionhandler, algorithm, fill)
		end
		
		if isclosed(fill)
			delete(pendingorders, orderid)
		end

	end

end


 