# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

mutable struct TradeStats
    count::Int64
    winCount::Int64
    lossCount::Int64
    totalPnl::Float64
    totalProfit::Float64
    totalLoss::Float64
    maxProfit::Dict{SecuritySymbol, Float64}
    maxLoss::Dict{SecuritySymbol, Float64}
    avgPnl::Float64
    avgProfit::Float64
    avgLoss::Float64
    avgHoldingPeriod::Float64
    profitFactor::Float64
    successRatio::Float64
    avgMae::Float64 #The average Maximum Adverse Excursion for all trades
    avgMfe::Float64 #The average Maximum Favorable Excursion for all trades  
    maxMae::Dict{SecuritySymbol, Float64} #The largest Maximum Adverse Excursion in a single trade (as symbol currency)
    maxMfe::Dict{SecuritySymbol, Float64} #The largest Maximum Favorable Excursion in a single trade (as symbol currency)
    totalTradeValue::Float64
end

TradeStats() = TradeStats(
            0, 0, 0, #Count
            0.0, 0.0, 0.0, #Total
            Dict{SecuritySymbol, Float64}(), Dict{SecuritySymbol, Float64}(), #Max
            0.0, 0.0, 0.0, #Avg
            0.0, 0.0, 0.0,
            0.0, 0.0,
            Dict{SecuritySymbol, Float64}(), Dict{SecuritySymbol, Float64}(), #Max MAE/MFE
            0.0)

serialize(sd::Dict{SecuritySymbol, Float64}) = Dict(tostring(k) => v for (k,v) in sd)

TradeStats(data::Dict{String, Any}) = TradeStats(
        get(data, "count", 0),
        get(data, "winCount", 0),
        get(data, "lossCount", 0),
        get(data, "totalPnl", 0.0),
        get(data, "totalProfit", 0.0),
        get(data, "totalLoss", 0.0),
        haskey(data, "maxProfit") ? 
            Dict(SecuritySymbol(k) => v for (k,v) in data["maxProfit"]) : Dict{SecuritySymbol, Float64}(),
        haskey(data, "maxProfit") ? 
            Dict(SecuritySymbol(k) => v for (k,v) in data["maxLoss"]) : Dict{SecuritySymbol, Float64}(),
        get(data, "avgPnl", 0.0),
        get(data, "avgProfit", 0.0),
        get(data, "avgLoss", 0.0),
        get(data, "avgHoldingPeriod", 0.0),
        get(data, "profitFactor", 0.0),
        get(data, "successRatio", 0.0),
        get(data, "avgMae", 0.0),
        get(data, "avgMfe", 0.0),
        haskey(data, "maxMae") ? 
            Dict(SecuritySymbol(k) => v for (k,v) in data["maxMae"]) : Dict{SecuritySymbol, Float64}(),
        haskey(data, "maxMfe") ? 
            Dict(SecuritySymbol(k) => v for (k,v) in data["maxMfe"]) : Dict{SecuritySymbol, Float64}(),
        get(data, "totalTradeValue", 0.0))


function serialize(tradeStats::TradeStats)
    return Dict{String, Any}(
        "count" => tradeStats.count,
        "winCount" => tradeStats.winCount,
        "lossCount" => tradeStats.lossCount,
        "totalPnl" => tradeStats.totalPnl,
        "totalProfit" => tradeStats.totalProfit,
        "totalLoss" => tradeStats.totalLoss,
        "maxProfit" => serialize(tradeStats.maxProfit),
        "maxLoss" => serialize(tradeStats.maxLoss),
        "avgPnl" => tradeStats.avgPnl,
        "avgProfit" => tradeStats.avgProfit,
        "avgLoss" => tradeStats.avgHoldingPeriod,
        "avgHoldingPeriod" => tradeStats.avgHoldingPeriod,
        "profitFactor" => tradeStats.profitFactor,
        "successRatio" => tradeStats.successRatio,
        "avgMae" => tradeStats.avgMae,
        "avgMfe" => tradeStats.avgMfe,
        "maxMae" => tradeStats.maxMae,
        "maxMfe" => tradeStats.maxMfe,
        "totalTradeValue" => tradeStats.totalTradeValue)
end

serialize(allTradeStats::Dict{String, TradeStats}) = Dict(k => serialize(v) for (k,v) in allTradeStats)


function filterTrades(tradeBook::TradeBook, direction::String = "NET")
    allTrades = Vector{Trade}()

    for (sym, tradesVector) in tradeBook
        append!(allTrades, tradesVector[findall(x -> x.direction == direction, tradesVector)])
    end

    return allTrades
end

function computeTradeStats(trades::Vector{Trade}, currentDate::DateTime)
    tradeStats = TradeStats()

    if length(trades) > 0
        
        pnl = [trade.pnl for trade in trades]

        #Count
        tradeStats.count = length(trades)
        tradeStats.winCount = sum(pnl .> 0)
        tradeStats.lossCount = sum(pnl .< 0)

        #Total Pnl
        tradeStats.totalPnl = sum(pnl)
        tradeStats.totalProfit = sum(pnl[pnl .> 0])
        tradeStats.totalLoss = sum(pnl[pnl .< 0])

        #Max Loss/Profit
        maxPnlTrade = trades[(pnl .== maximum(pnl)) .& (pnl .> 0)]
        minPnlTrade = trades[(pnl .== minimum(pnl)) .& (pnl .< 0)]

        if length(maxPnlTrade) > 0
            tradeStats.maxProfit = Dict(maxPnlTrade[1].symbol => maxPnlTrade[1].pnl)
        end

        if length(minPnlTrade) > 0
            tradeStats.maxLoss = Dict(minPnlTrade[1].symbol => minPnlTrade[1].pnl)
        end

        #Avg Loss/Profit
        tradeStats.avgPnl = mean(pnl)
        tradeStats.avgProfit = mean(pnl[pnl .> 0])
        tradeStats.avgLoss = mean(pnl[pnl .< 0])
        
        #Avg Holding Period
        startDate  = [trade.startDate == DateTime(1) ? currentDate : trade.startDate for trade in trades]
        endDate  = [trade.endDate == DateTime(1) ? currentDate : trade.endDate for trade in trades]
        
        duration  = [Dates.value((trade.endDate == DateTime(1) ? currentDate : trade.endDate)  - (trade.startDate == DateTime(1) ? date : trade.startDate))/86400000 for trade in trades]
        tradeStats.avgHoldingPeriod = mean(duration[duration .>0])
        #Profit Factor
        tradeStats.profitFactor = abs(tradeStats.totalLoss) > 0.001 ? tradeStats.totalProfit/tradeStats.totalLoss : NaN

        #Success Ratio
        tradeStats.successRatio = tradeStats.winCount/tradeStats.count

        #MAE/MFE
        tradeStats.avgMae = 0
        tradeStats.avgMfe = 0
        tradeStats.maxMae = Dict{SecuritySymbol, Float64}()
        tradeStats.maxMfe = Dict{SecuritySymbol, Float64}()

        tradeStats.totalTradeValue = sum([trade.totalValue for trade in trades])

    end

    return tradeStats
end

function computeAllTradeStats(tradeBook::TradeBook, currentDate::DateTime)

    allTradeStats = Dict{String, TradeStats}()

    for direction in ["NET", "LONG", "SHORT"]
        allTradeStats[direction] = computeTradeStats(filterTrades(tradeBook, direction), currentDate)
    end

    return allTradeStats
end

