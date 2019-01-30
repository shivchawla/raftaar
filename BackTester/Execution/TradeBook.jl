const TradeBook = Dict{SecuritySymbol, Vector{Trade}}

TradeBook(data::Dict{String, Any}) = Dict([(SecuritySymbol(sym), [Trade(trade) for trade in vectorTrades]) for (sym, vectorTrades) in data])

function serialize(tradeBook::TradeBook)
  temp = Dict{String, Any}()
  for (symbol, vectorTrades) in tradeBook
    temp[tostring(symbol)] = [serialize(trade) for trade in vectorTrades]
  end
  return temp
end

function updateTradeBook!(tradeBook::TradeBook, fill::OrderFill)

	# println("Updating Trade Book")
	# println("With Fill: $(fill)")

	sym = fill.securitysymbol
	qty = fill.fillquantity
	eligibleQty = qty  #in case, qty is more than required closing trades
	
	price = fill.fillprice
	fee = fill.orderfee
	eligibleFee = fee #in case, qty is more than required closing trades

	datetime = fill.datetime
	orderid = fill.orderid

	lastTrade = nothing

	#Check if trade exists
	if haskey(tradeBook, sym)
		#get the last trade
		trades = tradeBook[sym]

		if length(trades) > 0
			lastTrade = trades[end]
		end
	end

	#Set New trade if any (over closing trade or if trade doesn't exists)
	newTrade = nothing 

	#If last trade is NOT available or CLOSED, create a new trade
	if lastTrade == nothing || lastTrade.closed
		newTrade = Trade(sym, qty, price, fee, datetime)
	else

		#Current Trade qty/price
		currentQty = lastTrade.totalQty
		currentAvgBuyPrice = lastTrade.avgBuyPrice
		currentAvgSellPrice = lastTrade.avgSellPrice
		
		#Closed Status
		if qty > 0 && currentQty < 0 && abs(qty) == abs(currentQty)
			lastTrade.closed  = true
			lastTrade.endDate = datetime

		elseif qty < 0 && currentQty > 0 && abs(qty) == abs(currentQty)
			lastTrade.closed = true
			lastTrade.endDate = datetime
		
		elseif qty > 0 && currentQty < 0 && abs(qty) > abs(currentQty)
			# this means this trade is closed and a new BUY one is created in SELL
			eligibleQty = abs(currentQty)
			eligibleFee = abs(currentQty/qty) * fee
			
			newTradeQty = qty + currentQty
			newTradeFee = abs((qty + currentQty)/qty)*fee
			newTrade = Trade(sym, newTradeQty, price, newTradeFee, datetime)

		elseif qty < 0 && currentQty > 0 && abs(qty) > abs(currentQty)
			# this means this trade is closed and a new BUY one is created in SELL
			eligibleQty = -abs(currentQty)
			eligibleFee = abs(currentQty/qty) * fee
			
			newTradeQty = qty + currentQty
			newTradeFee = abs((qty + currentQty)/qty)*fee
			newTrade = Trade(sym, newTradeQty, price, newTradeFee, datetime)
		end

		#Update fillIds
		push!(lastTrade.fillIds, fill.orderid)
		
		#Update fee
		lastTrade.totalFees += fee
		
		#Quantity
		if eligibleQty > 0
			lastTrade.buyQty += eligibleQty
		else	
			lastTrade.sellQty += abs(eligibleQty)
		end

		lastTrade.totalQty += abs(eligibleQty)

		#Avg Buy Price	
		if eligibleQty > 0 && currentQty >= 0
			lastTrade.avgBuyPrice = (currentQty*currentAvgBuyPrice + eligibleQty*price)/(currentQty + eligibleQty)
			lastTrade.buyValue += eligibleQty*price

		elseif eligibleQty > 0 && currentQty < 0
			lastTrade.avgBuyPrice = price
			lastTrade.buyValue += eligibleQty*price

		elseif eligibleQty < 0 && currentQty <= 0
			lastTrade.avgSellPrice = (currentQty*currentAvgBuyPrice + abs(eligibleQty)*price)/(currentQty + abs(eligibleQty))
			lastTrade.sellValue += abs(eligibleQty*price)

		elseif eligibleQty < 0 && currentQty > 0
			lastTrade.avgSellPrice = price
			lastTrade.sellValue += abs(eligibleQty*price)

		end

		lastTrade.totalValue += abs(eligibleQty*price)

		#Pnl
		if eligibleQty > 0 && currentQty < 0
			lastTrade.pnl += min(abs(eligibleQty), abs(currentQty))*(lastTrade.avgSellPrice - price)
			
		elseif eligibleQty < 0 && currentQty > 0
			lastTrade.pnl += min(abs(eligibleQty), abs(currentQty))*(price - lastTrade.avgBuyPrice)
		end
		lastTrade.totalValue += abs(eligibleQty*price)
		
		#Update Count
		lastTrade.buyCount += eligibleQty > 0 ? 1 : 0
		lastTrade.sellCount += eligibleQty < 0 ? 1 : 0
		lastTrade.totalCount += 1
	end

	#In-case a NEW TRADE was created
	if newTrade != nothing
		newTrade.fillIds = [orderid]
		if haskey(tradeBook, sym)
			push!(tradeBook[sym], newTrade)
		else
			tradeBook[sym] = [newTrade]
		end
	end
end

function updateTradeBook!(tradeBook::TradeBook, fills::Vector{OrderFill})
	for fill in fills
		updateTradeBook!(tradeBook, fill)
	end
end

function updateTradeBook!(tradeBook::TradeBook, tradebars::Dict{SecuritySymbol, Vector{TradeBar}})

	for (sym, vectorTrades) in tradeBook
  		
  		for trade in vectorTrades
  			if !trade.closed
    			updateTrade!(trade, tradebars[trade.symbol][1])
			end
		end
  		
	end
end
