# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using DataFrames
using GLM
using JSON
using TimeSeries
using Statistics

mutable struct Drawdown
    currentdrawdown::Float64
    maxdrawdown:: Float64
end

Drawdown() = Drawdown(NaN,NaN)

Drawdown(data::Dict{String, Any}) = Drawdown(data["currentdrawdown"], data["maxdrawdown"])

mutable struct Deviation
    annualstandarddeviation::Float64
    annualvariance::Float64
    annualsemideviation::Float64
    annualsemivariance::Float64
    squareddailyreturn::Float64
    sumsquareddailyreturn::Float64
    sumdailyreturn::Float64
end

Deviation() = Deviation(NaN,NaN,NaN,NaN,NaN,NaN,NaN)

Deviation(data::Dict{String, Any}) = Deviation(data["annualstandarddeviation"],
                                        data["annualvariance"],
                                        data["annualsemideviation"],
                                        data["annualsemivariance"],
                                        data["squareddailyreturn"],
                                        data["sumsquareddailyreturn"],
                                        data["sumdailyreturn"])

mutable struct Ratios
    sharperatio::Float64
    informationratio::Float64
    calmarratio::Float64
    sortinoratio::Float64
    treynorratio::Float64
    beta::Float64
    alpha::Float64
    stability::Float64
end

Ratios() = Ratios(NaN,NaN,NaN,0.0,0.0,1.0,0.0,1.0)

Ratios(data::Dict{String, Any}) = Ratios(data["sharperatio"],
                                  data["informationratio"],
                                  data["calmarratio"],
                                  data["sortinoratio"],
                                  data["treynorratio"],
                                  data["beta"],
                                  data["alpha"],
                                  data["stability"])

mutable struct Returns
    dailyreturn::Float64
    dailyreturn_benchmark::Float64
    averagedailyreturn::Float64
    annualreturn::Float64
    totalreturn::Float64
    peaktotalreturn::Float64
end

Returns() = Returns(NaN,NaN,NaN,NaN,NaN,NaN)

Returns(data::Dict{String, Any}) = Returns(data["dailyreturn"],
                                    data["dailyreturn_benchmark"],
                                    data["averagedailyreturn"],
                                    data["annualreturn"],
                                    data["totalreturn"],
                                    data["peaktotalreturn"])

mutable struct PortfolioStats
    netvalue::Float64
    #peaknormalizednetvalue::Float64
    #normalizednetvalue::Float64
    leverage::Float64
    concentration::Float64
end

PortfolioStats() = PortfolioStats(0.0,0.0,0.0)

PortfolioStats(data::Dict{String, Any}) = PortfolioStats(data["netvalue"], data["leverage"], data["concentration"])

mutable struct Performance
    period::Int
    returns::Returns
    deviation::Deviation
    ratios::Ratios
    drawdown::Drawdown
    portfoliostats::PortfolioStats
    tradeStats:: Dict{String, TradeStats}
end

Performance() = Performance(0, Returns(), Deviation(), Ratios(), Drawdown(), PortfolioStats(), Dict{String, TradeStats}())

Performance(data::Dict{String, Any}) = Performance(data["period"],
                                            Returns(data["returns"]),
                                            Deviation(data["deviation"]),
                                            Ratios(data["ratios"]),
                                            Drawdown(data["drawdown"]),
                                            PortfolioStats(data["portfoliostats"]),
                                            haskey(data, "tradeStats") ? 
                                                Dict(k => TradeStats(v) for (k,v) in data["tradeStats"]) : Dict{String, TradeStats}()
                                        )

const PerformanceTracker = Dict{Date, Performance}
const VariableTracker = Dict{Date, Dict{String, Float64}}

PerformanceTracker(data::Dict{String, Any}) = Dict([(Date(date), Performance(perf)) for (date, perf) in data])
VariableTracker(data::Dict{String, Any}) = Dict([(Date(date), Dict(dt)) for (date, dt) in data])

"""
Get performance for a specific period
"""
function getperformanceforperiod(performancetracker::PerformanceTracker, startdate::Date, enddate::Date)

    algorithmreturns = Vector{Float64}()
    benchmarkreturns = Vector{Float64}()

    for date in startdate:Day(1):enddate
        if(haskey(performancetracker, date))
            push!(algorithmreturns, performancetracker[date].returns.dailyreturn)
            push!(benchmarkreturns, performancetracker[date].returns.dailyreturn_benchmark)
        end

    end

    calculateperformance(algorithmreturns, benchmarkreturns)

end

function getlatestperformance(performancetracker::PerformanceTracker)
    # lastdate = sort(collect(keys(performancetracker)))[end]
    if length(keys(performancetracker)) > 0
        lastdate = maximum(keys(performancetracker))
        return performancetracker[lastdate]
    end
end


"""
Function to compute performance based on vector of returns
"""
function calculateperformance(algorithmreturns::Vector{Float64}, benchmarkreturns::Vector{Float64}; scale::Int = 252, period::Int=0)
   
    # replace NaN with zeros
    algorithmreturns[isnan.(algorithmreturns)] .= 0.0
    benchmarkreturns[isnan.(benchmarkreturns)] .= 0.0
    
    # replace Inf with zeros (this is tricky and debatable) 
    algorithmreturns[isinf.(algorithmreturns)] .= 0.0
    benchmarkreturns[isinf.(benchmarkreturns)] .= 0.0
        
    ps = Performance()

    ps.returns = aggregatereturns(algorithmreturns, scale, period)
    ps.deviation = calculatedeviation(algorithmreturns)
    ps.drawdown = calculatedrawdown(algorithmreturns)

    ps.ratios = calculateratios(ps.returns, ps.deviation, ps.drawdown)

    df = DataFrame(X = benchmarkreturns, Y = algorithmreturns)
    
    try
        if(size(df, 1) > 2)
            OLS = fit(LinearModel, @formula(Y ~ X), df)
            coefficients = coef(OLS)

            ps.ratios.beta = round(coefficients[2], digits = 2)
            ps.ratios.alpha = round(coefficients[1] * 252.0, digits = 4)
            ps.ratios.stability = round(r2(OLS), digits = 3)
        end
    catch err
        println(err)
    end

    trkerr = sqrt(252) * std(algorithmreturns - benchmarkreturns)
    excessret = calculateannualreturns(algorithmreturns - benchmarkreturns, scale, period)
    ps.ratios.informationratio = round(trkerr > 0.0 ? excessret/trkerr : 0.0, digits = 2)
    ps.period = period == 0 ? length(algorithmreturns) : period

    return ps
end

"""
Function to compute performance for all periods like 1/2/5/10/ytd/mtd based on vector of returns
"""
function calculateperformance_rollingperiods(algorithmreturns::Vector{Float64}, benchmarkreturns::Vector{Float64}, dates::Vector{Date}) 

    performances = Dict{String, Performance}()
    
    algo_ret_ta = TimeArray(dates[:], (algorithmreturns')', [:algorithm])
    benchmark_ret_ta = TimeArray(dates[:], (benchmarkreturns')', [:benchmark])

    returns = merge(algo_ret_ta, benchmark_ret_ta, :outer)
    lastdate = Date(dates[end])

    # WTD
    sd = lastdate - Dates.Day(Dates.dayofweek(lastdate))
    past_returns = from(returns, sd)
    sd_wtd = TimeSeries.timestamp(past_returns)[1]
    if length(past_returns) > 0
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["wtd"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    # 1wk 
    sd = lastdate - Dates.Week(1)
    past_returns = from(returns, sd)
    sd_1wk = TimeSeries.timestamp(past_returns)[1]
    if length(past_returns) > 0 && sd_1wk < sd_wtd
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["1wk"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    # MTD   
    sd = Date(Dates.year(lastdate), Dates.month(lastdate), 1)
    past_returns = from(returns, sd)
    sd_mtd = TimeSeries.timestamp(past_returns)[1]
    if length(past_returns) > 0
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["mtd"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    # 1m
    sd = lastdate - Dates.Month(1)
    past_returns = from(returns, sd)
    sd_1m = TimeSeries.timestamp(past_returns)[1]
    if length(past_returns) > 0 && sd_1m < sd_mtd
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["1m"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    # 2m
    sd = lastdate - Dates.Month(2)
    past_returns = from(returns, sd)
    sd_2m = TimeSeries.timestamp(past_returns)[1]
    if length(past_returns) > 0 && sd_2m < sd_1m
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["2m"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    # 6m
    sd = lastdate - Dates.Month(6)
    past_returns = from(returns, sd)
    sd_6m = TimeSeries.timestamp(past_returns)[1]
    if length(past_returns) > 0 && sd_6m < sd_2m
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["6m"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end
    
    # YTD 
    past_returns = when(returns, year, Dates.year(lastdate))
    sd_ytd = TimeSeries.timestamp(past_returns)[1]
    if length(past_returns) > 0
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["ytd"] = calculateperformance(TimeSeries.values(past_returns["algorithm"]), TimeSeries.values(past_returns["benchmark"]), scale=365, period=ndays)
    end    

    # Last 1 year data
    sd = lastdate - Dates.Year(1) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_1y = TimeSeries.timestamp(past_returns)[1]
    
    if length(past_returns) > 0 && sd_1y < sd_ytd
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["1y"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    # Last 2 year data
    sd = lastdate - Dates.Year(2) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_2y = TimeSeries.timestamp(past_returns)[1]
    
    if length(past_returns) > 0 && sd_2y < sd_1y
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["2y"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end    

    # Last 5 year data
    sd = lastdate - Dates.Year(5) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_5y = TimeSeries.timestamp(past_returns)[1]
    
    if length(past_returns) > 0 && sd_5y < sd_2y
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["5y"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    # Last 10 year data
    sd = lastdate - Dates.Year(10) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_10y = TimeSeries.timestamp(past_returns)[1]
    
    if length(past_returns) > 0 && sd_10y < sd_5y
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["10y"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    #Inception
    past_returns = returns
    
    if length(past_returns) > 0
        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1
        performances["inception"] = calculateperformance(TimeSeries.values(past_returns[:algorithm]), TimeSeries.values(past_returns[:benchmark]), scale=365, period=ndays)
    end

    return performances
end


"""
Function to compute performance for all periods like 1/2/5/10/ytd/mtd based on vector of returns
"""
function calculateperformance_rollingperiods(returns::TimeArray) 

    performances = Dict{String, Performance}()

    dates = TimeSeries.timestamp(returns)
    lastdate = dates[end]   

    # WTD
    sd = lastdate - Dates.Day(Dates.dayofweek(lastdate))
    past_returns = from(returns, sd)
    sd_wtd = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0)

        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["wtd"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end

    # 1wk (only if sd_1wk < sd_wtd)
    sd = lastdate - Dates.Week(1)
    past_returns = from(returns, sd)
    sd_1wk = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_1wk < sd_wtd)

        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["1wk"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end

    # MTD
    sd = Date(Dates.year(lastdate), Dates.month(lastdate), 1)
    past_returns = from(returns, sd)
    sd_mtd = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["mtd"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end


    # 1m    
    sd = lastdate - Dates.Month(1)
    past_returns = from(returns, sd)
    sd_1m = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_1m < sd_mtd)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["1m"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end

    # 2m 
    sd = lastdate - Dates.Month(2)
    past_returns = from(returns, sd)
    sd_2m = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_2m < sd_1m)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["2m"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end

    # 3m
    sd = lastdate - Dates.Month(3)
    past_returns = from(returns, sd)
    sd_3m = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_3m < sd_2m)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["3m"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end

    # 6m 
    sd = lastdate - Dates.Month(6)
    past_returns = from(returns, sd)
    sd_6m = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_6m < sd_3m)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["6m"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end


    # YTD 
    past_returns = when(returns, year, Dates.year(lastdate))
    sd_ytd = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["ytd"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end    

    # Last 1 year data
    sd = lastdate - Dates.Year(1) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_1y = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_1y < sd_ytd)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["1y"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end

    # Last 2 year data
    sd = lastdate - Dates.Year(2) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_2y = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_2y < sd_1y)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["2y"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end    

    # Last 5 year data
    sd = lastdate - Dates.Year(5) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_5y = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_5y < sd_2y)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["5y"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end

    # Last 10 year data
    sd = lastdate - Dates.Year(10) + Dates.Day(1)
    past_returns = from(returns, sd)
    sd_10y = TimeSeries.timestamp(past_returns)[1]
    if(length(past_returns) > 0 && sd_10y < sd_5y)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["10y"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end


    # Since inception
    past_returns = returns
    if(length(past_returns) > 0)
        algo_returns = TimeSeries.values(past_returns[:algorithm])
        benchmark_returns = TimeSeries.values(past_returns[:benchmark])

        ts = TimeSeries.timestamp(past_returns)
        ndays = Int(Dates.value(ts[end] - ts[1])) + 1

        performances["inception"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
    end   

    return performances
end

"""
Function to compute performance for all static periods 2015/2014/etc
"""
function calculateperformance_staticperiods(returns::TimeArray) 

    performance = Dict{String, Dict{String, Performance}}()

    dates = TimeSeries.timestamp(returns)

    performance["yearly"] = Dict{String, Performance}()
    performance["monthly"] = Dict{String, Performance}()
    for y = 2007:Dates.year(dates[end])
        past_returns = when(returns, year, y)
        if(length(past_returns) > 0)
            algo_returns = TimeSeries.values(past_returns[:algorithm])
            benchmark_returns = TimeSeries.values(past_returns[:benchmark])

            ts = TimeSeries.timestamp(past_returns)
            ndays = Int(Dates.value(ts[end] - ts[1])) + 1

            performance["yearly"][string(y)] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
        end

        for m = 1:12
            past_monthly_returns = when(past_returns, month, m)
            if(size(TimeSeries.values(past_monthly_returns),1) > 0)
                algo_returns = TimeSeries.values(past_monthly_returns[:algorithm])
                benchmark_returns = TimeSeries.values(past_monthly_returns[:benchmark])
                
                ts = TimeSeries.timestamp(past_monthly_returns)
                ndays = Int(Dates.value(ts[end] - ts[1])) + 1

                performance["monthly"]["$(y)_$(m)"] = calculateperformance(algo_returns, benchmark_returns, scale=365, period=ndays)
            end
        end
    end

    return performance
end

function toJSON(performance::Performance)
    JSON.json(performance.returns)
end

"""
Function to compute annual returns
"""
function calculateannualreturns(returns::Vector{Float64}, scale::Int=252, period::Int=0)

    tr = (cumprod(1.0 .+ returns))[end] - 1
    #Use scale and period to scale daily returns to annual returns
    len = period == 0 ? length(returns) : period
    ayr = (1 + tr)^(scale/len) - 1
   
    return round(ayr, digits = 4)
    
end

"""
Function to compute peak return
"""
function calculatepeakreturn(returns::Vector{Float64})
    round(maximum(cumprod(1.0 .+ returns)) - 1.0, digits = 4) 
end

"""
Function to compute total return
"""
function calculatetotalreturn(returns::Vector{Float64})
    round((cumprod(1.0 .+ returns))[end] - 1.0, digits = 4)
end

function aggregatereturns(rets::Vector{Float64}, scale::Int=252, period::Int=0)
    returns = Returns()
    totalreturn = calculatetotalreturn(rets)
    returns.averagedailyreturn = round(totalreturn/length(rets), digits = 4)
    returns.totalreturn = totalreturn
    returns.annualreturn = calculateannualreturns(rets, scale, period)
    returns.peaktotalreturn = calculatepeakreturn(rets)
    return returns
end


"""
Function to compute standard deviation
for all returns and just negative returns
"""
function calculatedeviation(returns::Vector{Float64})
    deviation = Deviation()
    if length(returns) > 1
        deviation.annualstandarddeviation, deviation.annualvariance = calculatestandarddeviation(returns)
        deviation.annualsemideviation, deviation.annualsemivariance = calculatesemideviation(returns)
    end

    return deviation
end

function calculatestandarddeviation(returns::Vector{Float64})
    sdev = std(returns) * sqrt(252.0)
    return round(sdev, digits = 4), round(sdev*sdev, digits = 4)
end

function calculatesemideviation(returns::Vector{Float64})
    sdev = std(returns .< 0) * sqrt(252.0)
    return round(sdev, digits = 4), round(sdev*sdev, digits = 4)
end

"""
Function to compute drawdown
"""
function calculatedrawdown(returns::Vector{Float64})
    drawdown = Drawdown()

    netvalue = 100000.0 * cumprod(1.0 .+ returns)
    currentdrawdown = zeros(length(returns))
    maxdrawdown = zeros(length(returns))
    peak = 100000.0
    len = length(returns)

    for i in 1:len
      # peak will be the maximum value seen so far (0 to i), only get updated when higher NAV is seen
      if (netvalue[i] > peak)
        peak = netvalue[i]
      end
      currentdrawdown[i] = (peak - netvalue[i]) / peak
      # Same idea as peak variable, MDD keeps track of the maximum drawdown so far. Only get updated when higher DD is seen.
      if i == 1
        maxdrawdown[i] = currentdrawdown[i]
      elseif (currentdrawdown[i] > maxdrawdown[i-1])
        maxdrawdown[i] = currentdrawdown[i]
      elseif i > 1
        maxdrawdown[i] = maxdrawdown[i-1]
      end
    end

    drawdown.currentdrawdown = round(currentdrawdown[end], digits = 4)
    drawdown.maxdrawdown  = round(maxdrawdown[end], digits = 4)

    return drawdown
end

#precompile(calculatedrawdown, (Array{Float64,1},()))


"""
Function to compute risk measuring ratios
"""
function calculateratios(returns::Returns, deviation::Deviation, drawdown::Drawdown)
    ratios = Ratios()
    ratios.sharperatio = round(deviation.annualstandarddeviation > 0.0 ? (returns.annualreturn - 0.065) / deviation.annualstandarddeviation : NaN, digits = 2)
    ratios.sortinoratio = round(deviation.annualsemideviation > 0.0 ? returns.annualreturn / deviation.annualsemideviation : NaN, digits = 2)
    ratios.calmarratio = round(drawdown.maxdrawdown > 0.0 ? returns.totalreturn/drawdown.maxdrawdown : Inf, digits = 2)
    return ratios
end

function serialize(performancetracker::PerformanceTracker)
  temp = Dict{String, Any}()
  for (date, perf) in performancetracker
    temp[string(date)] = serialize(perf)
  end
  return temp
end

function serialize(variabletracker::VariableTracker)
  temp = Dict{String, Any}()
  for (date, var) in variabletracker
    temp[string(date)] = var
  end
  return temp
end

function serialize(dw::Drawdown)
  return Dict{String, Any}("currentdrawdown" => dw.currentdrawdown,
                            "maxdrawdown" => dw.maxdrawdown)
end

function serialize(dv::Deviation)
  return Dict{String, Any}("annualstandarddeviation" => dv.annualstandarddeviation,
                            "annualvariance" => dv.annualvariance,
                            "annualsemideviation" => dv.annualsemideviation,
                            "annualsemivariance" => dv.annualsemivariance,
                            "squareddailyreturn" => dv.squareddailyreturn,
                            "sumsquareddailyreturn" => dv.sumsquareddailyreturn,
                            "sumdailyreturn" => dv.sumdailyreturn)
end

function serialize(rt::Ratios)
  return Dict{String, Any}("sharperatio" => rt.sharperatio,
                            "informationratio" => rt.informationratio,
                            "calmarratio" => rt.calmarratio,
                            "sortinoratio" => rt.sortinoratio,
                            "treynorratio" => rt.treynorratio,
                            "beta" => rt.beta,
                            "alpha" => rt.alpha,
                            "stability" => rt.stability)
end

function serialize(rs::Returns)
  return Dict{String, Any}("dailyreturn" => rs.dailyreturn,
                            "dailyreturn_benchmark" => rs.dailyreturn_benchmark,
                            "averagedailyreturn" => rs.averagedailyreturn,
                            "annualreturn" => rs.annualreturn,
                            "totalreturn" => rs.totalreturn,
                            "peaktotalreturn" => rs.peaktotalreturn)
end

function serialize(ps::PortfolioStats)
  return Dict{String, Any}("netvalue" => ps.netvalue,
                            "leverage" => ps.leverage,
                            "concentration" => ps.concentration)
end

function serialize(performance::Performance)
  return Dict{String, Any}("period" => performance.period,
                            "returns" => serialize(performance.returns),
                            "deviation" => serialize(performance.deviation),
                            "ratios" => serialize(performance.ratios),
                            "drawdown" => serialize(performance.drawdown),
                            "portfoliostats" => serialize(performance.portfoliostats))
end

#Function to serialize rolling performance
function serialize(performanceDict::Dict{String,Performance})
    temp = Dict{String, Any}()
    for (k,v) in performanceDict
        temp[k] = serialize(v)
    end
    return temp
end

#Function to serialize rolling performance
function serialize(staticperformance::Dict{String, Dict{String, Performance}})
    output = Dict{String, Dict{String, Any}}()
    for (k,v) in staticperformance

        temp = Dict{String,Any}()

        for (k2, v2) in v
            temp[k2] = serialize(v2)
        end

        output[k] = temp
    end
    return output
end

==(dw1::Drawdown, dw2::Drawdown) = dw1.currentdrawdown == dw2.currentdrawdown &&
                                    dw1.maxdrawdown == dw2.maxdrawdown

==(dv1::Deviation, dv2::Deviation) = dv1.annualstandarddeviation == dv2.annualstandarddeviation &&
                                      dv1.annualvariance == dv2.annualvariance &&
                                      dv1.annualsemideviation == dv2.annualsemideviation &&
                                      dv1.annualsemivariance == dv2.annualsemivariance &&
                                      dv1.squareddailyreturn == dv2.squareddailyreturn &&
                                      dv1.sumsquareddailyreturn == dv2.sumsquareddailyreturn &&
                                      dv1.sumdailyreturn == dv2.sumdailyreturn

==(rt1::Ratios, rt2::Ratios) = rt1.sharperatio == rt2.sharperatio &&
                                rt1.informationratio == rt2.informationratio &&
                                rt1.calmarratio == rt2.calmarratio &&
                                rt1.sortinoratio == rt2.sortinoratio &&
                                rt1.treynorratio == rt2.treynorratio &&
                                rt1.beta == rt2.beta &&
                                rt1.alpha == rt2.alpha &&
                                rt1.stability == rt2.stability

==(rs1::Returns, rs2::Returns) = rs1.dailyreturn == rs2.dailyreturn &&
                                  rs1.dailyreturn_benchmark == rs2.dailyreturn_benchmark &&
                                  rs1.averagedailyreturn == rs2.averagedailyreturn &&
                                  rs1.annualreturn == rs2.annualreturn &&
                                  rs1.totalreturn == rs2.totalreturn &&
                                  rs1.peaktotalreturn == rs2.peaktotalreturn

==(ps1::PortfolioStats, ps2::PortfolioStats) = ps1.netvalue == ps2.netvalue &&
                                                ps1.leverage == ps2.leverage &&
                                                ps1.concentration == ps2.concentration

==(pf1::Performance, pf2::Performance) = pf1.period == pf2.period &&
                                          pf1.returns == pf2.returns &&
                                          pf1.deviation == pf2.deviation &&
                                          pf1.ratios == pf2.ratios &&
                                          pf1.drawdown == pf2.drawdown &&
                                          pf1.portfoliostats == pf2.portfoliostats &&
                                          pf1.tradeStats == pf2.tradeStats

