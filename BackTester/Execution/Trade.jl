
mutable struct Trade
	symbol::SecuritySymbol
	direction::String
	fillIds::Vector{UInt64}
	avgBuyPrice::Float64
	avgSellPrice::Float64
	totalQty::Int64 
	buyQty::Int64 
	sellQty::Int64 
	totalValue::Float64
	buyValue::Float64 
	sellValue::Float64 
	pnl::Float64
	totalFees::Float64
	totalCount::Int64
	buyCount::Int64
	sellCount::Int64
	closed::Bool
	startDate::DateTime
	endDate::DateTime
end

Trade(symbol::SecuritySymbol, quantity::Int64, price::Float64, fee::Float64, datetime::DateTime) =
	Trade(symbol, quantity > 0 ? "LONG" : "SHORT", UInt64[], 
		quantity > 0 ? price : 0.0, quantity < 0 ? price : 0.0,  #bp, sp 
		abs(quantity), quantity > 0 ? quantity : 0, quantity < 0 ? abs(quantity) : 0, #tq, bq, sq
		abs(price*quantity), price*(quantity > 0 ? quantity : 0), price*abs(quantity < 0 ? quantity : 0), #tv, bv, sv
		0.0, fee, 
		1, quantity > 0 ? 1 : 0, quantity < 0 ? 1 : 0, 
		false,
		datetime, DateTime(1))


Trade(symbol::SecuritySymbol, direction::String, datetime) =
	Trade(symbol, direction, UInt64[], 
		0, 0,
		0, 0, 0,
		0.0, 0.0, 0.0,
		0.0, 0.0,
		0, 0, 0,
		false,
		DateTime(1), DateTime(1))

Trade(data::Dict{String, Any}) = Trade(
	haskey(data, "symbol") ? SecuritySymbol(data["symbol"]) : SecuritySymbol(),
	get(data, "direction", ""),
	get(data, "fillIds", UInt64[]),
	get(data, "avgBuyPrice", 0.0),
	get(data, "avgSellPrice", 0.0),
	get(data, "totalQty", 0),
	get(data, "buyQty", 0),
	get(data, "sellQty", 0),
	get(data, "totalValue", 0.0),
	get(data, "buyValue", 0.0),
	get(data, "sellValue", 0.0),
	get(data, "pnl", 0.0),
	get(data, "totalFees", 0.0),
	get(data, "buyCount", 1),
	get(data, "sellCount", 1),
	get(data, "totalCount", 1),
	get(data, "closed", false),
	haskey(data, "startDate") ? DateTime(startDate) : DateTime(1),
	haskey(data, "endDate") ? DateTime(endDate) : DateTime(1))
		
function serialize(trade::Trade) 
	return Dict{String, Any}(
		"symbol" => serialize(trade.symbol),
		"direction" => trade.direction,
		"fillIds" => trade.fillIds, 
		"avgBuyPrice" => trade.avgBuyPrice,
		"avgSellPrice" => trade.avgSellPrice,
		"totalQty" => trade.totalQty,
		"buyQty" => trade.buyQty,
		"sellQty" => trade.sellQty,
		"totalValue" => trade.totalValue,
		"buyValue" => trade.buyValue,
		"sellValue" => trade.sellValue,
		"pnl" => trade.pnl,
		"totalFees" => trade.totalFees,
		"buyCount" => trade.buyCount,
		"sellCount" => trade.sellCount,
		"totalCount" => trade.totalCount,
		"closed" => trade.closed,
		"startDate" =>  trade.startDate,
		"endDate" =>  trade.endDate)
end


function updateTrade!(trade::Trade, tradebar::TradeBar)
	if(tradebar.close > 0.0000000001 && !isnan(tradebar.close))
		price = tradebar.close
		trade.pnl = trade.direction == "LONG" ? trade.buyQty*(price - trade.avgBuyPrice) : trade.sellQty*(trade.avgSellPrice - price)
	end
end



