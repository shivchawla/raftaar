# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using DataFrames
using GLM

type Drawdown
    currentdrawdown::Float64
    maxdrawdown:: Float64
end

Drawdown() = Drawdown(0.0,0.0)

type Deviation
    annualstandarddeviation::Float64
    annualvariance::Float64
    annualsemideviation::Float64
    annualsemivariance::Float64
    squareddailyreturn::Float64
    sumsquareddailyreturn::Float64
    sumdailyreturn::Float64
end

Deviation() = Deviation(0.0,0.0,0.0,0.0,0.0,0.0,0.0)

type Ratios
    sharperatio::Float64
    informationratio::Float64
    calmarratio::Float64
    sortinoratio::Float64
    treynorratio::Float64
    beta::Float64
    alpha::Float64
    stability::Float64   
end

Ratios() = Ratios(0.0,0.0,0.0,0.0,0.0,1.0,0.0,1.0)

type Returns
    dailyreturn::Float64
    dailyreturn_benchmark::Float64
    averagedailyreturn::Float64
    annualreturn::Float64
    totalreturn::Float64 
    peaktotalreturn::Float64 
end

Returns() = Returns(0.0,0.0,0.0,0.0,1.0,1.0)

type PortfolioStats  
    netvalue::Float64
    #peaknormalizednetvalue::Float64
    #normalizednetvalue::Float64
    leverage::Float64
    concentration::Float64
end

PortfolioStats() = PortfolioStats(0.0,0.0,0.0)

type Performance
    period::Int
    #positivedays::Int
    #negativedays::Int
    returns::Returns
    deviation::Deviation
    ratios::Ratios
    drawdown::Drawdown
    portfoliostats::PortfolioStats
end

Performance() = Performance(0, Returns(), Deviation(), Ratios(), Drawdown(), PortfolioStats())

typealias AccountTracker Dict{Date, Account}
typealias CashTracker Dict{Date, Float64}
typealias PerformanceTracker Dict{Date, Performance}  

"""
Get performance for a specific period
"""
function getperformanceforperiod(performancetracker::PerformanceTracker, startdate::Date, enddate::Date)
    
    algorithmreturns = Vector{Float64}()
    benchmarkreturns = Vector{Float64}()

    for date in startdate:enddate
        if(haskey(performancetracker, date))
            push!(algorithmreturns, performancetracker[date].returns.dailyreturn)
            push!(benchmarkreturns, performancetracker[date].returns.dailyreturn_benchmark)
        end

    end

    calculateperformance(algorithmreturns, benchmarkreturns)

end

function getlatestperformance(performancetracker::PerformanceTracker)
    lastdate = sort(collect(keys(performancetracker)))[end]

    return performancetracker[lastdate]
end


"""
Function to compute performance based on vector of returns
"""
function calculateperformance(algorithmreturns::Vector{Float64}, benchmarkreturns::Vector{Float64})
   
    ps = Performance()

    ps.returns = aggregatereturns(algorithmreturns)   
    ps.deviation = calculatedeviation(algorithmreturns)  
    ps.drawdown = calculatedrawdown(algorithmreturns)
    
    ps.ratios = calculateratios(ps.returns, ps.deviation, ps.drawdown) 
    
    df = DataFrame(X = benchmarkreturns, Y = algorithmreturns)
    OLS = lm(Y ~ X, df)
    coefficients = coef(OLS)
    ps.ratios.beta = coefficients[2]
    ps.ratios.alpha = coefficients[1]
    ps.ratios.stability = r2(OLS)

    trkerr = sqrt(252) * std(algorithmreturns - benchmarkreturns)
    excessret = calculateannualreturns(algorithmreturns - benchmarkreturns)

    ps.ratios.informationratio = trkerr > 0.0 ? excessret/trkerr : 0.0

    ps.period = length(algorithmreturns)

    return ps
end 

"""
Function to compute annual returns
"""
function calculateannualreturns(returns::Vector{Float64}) 
    (calculatetotalreturn(returns)/sum(length(returns))) * 252.0
end

"""
Function to compute total return
"""
function calculatetotalreturn(returns::Vector{Float64})
    (cumprod(1.0 + returns) - 1.0)[end]
end

function aggregatereturns(rets::Vector{Float64})
    returns = Returns()
    totalreturn = calculatetotalreturn(rets)
    returns.averagedailyreturn = totalreturn/length(rets)
    returns.totalreturn = totalreturn
    returns.annualreturn = totalreturn*252/length(rets)
    return returns
end


"""
Function to compute standard deviation
for all returns and just negative returns
"""
function calculatedeviation(returns::Vector{Float64})
    deviation = Deviation()
    deviation.annualstandarddeviation, deviation.annualvariance = calculatestandarddeviation(returns)
    deviation.annualsemideviation, deviation.annualsemivariance = calculatesemideviation(returns)
    return deviation
end

function calculatestandarddeviation(returns::Vector{Float64})
    sdev = std(returns) * sqrt(252.0)
    return sdev, sdev*sdev
end

function calculatesemideviation(returns::Vector{Float64})
    sdev = std(returns .< 0) * sqrt(252.0)
    return sdev, sdev*sdev
end

"""
Function to compute drawdown
"""
function calculatedrawdown(returns::Vector{Float64})
    drawdown = Drawdown()

    netvalue = 100000.0 * cumprod(1.0 + returns) 
    currentdrawdown = zeros(length(returns))
    maxdrawdown = zeros(length(returns))
    peak = -9999.0
    len = length(returns)
    
    for i in 1:len
      # peak will be the maximum value seen so far (0 to i), only get updated when higher NAV is seen
      if (netvalue[i] > peak) 
        peak = netvalue[i]
      end
      currentdrawdown[i] = (peak - netvalue[i]) / peak
      # Same idea as peak variable, MDD keeps track of the maximum drawdown so far. Only get updated when higher DD is seen.
      if (currentdrawdown[i] > maxdrawdown[i]) 
        maxdrawdown[i] = currentdrawdown[i]
      elseif i > 1
        maxdrawdown[i] = maxdrawdown[i-1] 
      end
    end

    drawdown.currentdrawdown = currentdrawdown[end]
    drawdown.maxdrawdown  = maxdrawdown[end]

    return drawdown
end


"""
Function to compute risk measuring ratios
"""
function calculateratios(returns::Returns, deviation::Deviation, drawdown::Drawdown)
    ratios = Ratios()
    ratios.sharperatio = deviation.annualstandarddeviation > 0.0 ? returns.annualreturn / deviation.annualstandarddeviation : 0.0 
    ratios.sortinoratio = deviation.annualsemideviation > 0.0 ? returns.annualreturn / deviation.annualsemideviation : 0.0
    ratios.calmarratio = drawdown.maxdrawdown > 0.0 ? returns.annualreturn/drawdown.maxdrawdown : 0.0
    return ratios
end






