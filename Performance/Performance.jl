# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("PortfolioStats.jl")
include("../Account/Account.jl")
#include("TradeStats.jl")
#include("../DataTypes/Trade.jl")

type Performance
    netvalue::Float64
    dailyreturn::Float64
    averagedailyreturn::Float64
    annualreturn::Float64
    totalreturn::Float64
    annualstandarddeviation::Float64
    annualvariance::Float64
    sharperatio::Float64
    informationratio::Float64
    drawdown::Float64
    maxdrawdown::Float64
    period::Int
    squareddailyreturn::Float64
    sumsquareddailyreturn::Float64
    sumdailyreturn::Float64
    peaknetvalue::Float64
end

Performance() = Performance(0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)

typealias AccountTracker Dict{Date, Account}
typealias CashTracker Dict{Date, Float64}
typealias PerformanceTracker Dict{Date, Performance}  

"""
Updates performance of rolling window of 252 days
"""
function updateperformance(accounttracker::AccountTracker, cashtracker::CashTracker, performancetracker::PerformanceTracker, date::Date)

    currentperformance = Performance()
    
    #use past performance and new netvalue and update the performance
    sorteddates = sort(collect(keys(performancetracker)))

    # Now, we need latest returns
    # But insted we calculate the whole series again
    # PERFORMANCE IMPROVEMENT
    returns = computereturns(accounttracker, cashtracker)

    if !isempty(sorteddates)
        
        #Get Latest Performance
        lastperformance = performancetracker[sorteddates[end]]
        
        if length(returns) == length(sorteddates) + 1
            latestreturn = returns[end]

            if length(sorteddates) >= 252
                firstperformance = performancetracker[sorteddates[length(sorteddates) - 252 + 1]]
            else
                firstperformance = performancetracker[sorteddates[1]]
            end

            currentperformance = _computecurrentperformance(firstperformance, lastperformance, latestreturn) 

        end
    
    else
        actkeys = sort(collect(keys(accounttracker)))
        currentperformance = _intializepeformance(accounttracker[actkeys[1]].cash)    
    end

    performancetracker[date] = currentperformance

end

export updateperformance


function _intializepeformance(netvalue::Float64)
    performance = Performance()

    performance.netvalue = netvalue    
    performance.peaknetvalue = netvalue
    performance.period = 1

    return performance
end

function _computecurrentperformance(firstperformance::Performance, lastperformance::Performance, latestreturn::Float64)

    performance = Performance()
    
    performance.dailyreturn = 100.0 * latestreturn
    performance.squareddailyreturn =  performance.dailyreturn * performance.dailyreturn
    performance.totalreturn = 100.0 * ((1.0 + lastperformance.totalreturn/100.0) * (1 + performance.dailyreturn/100.0) - 1.0)
    performance.netvalue = lastperformance.netvalue * (1.0 + performance.dailyreturn/100.0)    

    if (performance.netvalue > lastperformance.peaknetvalue) 
        performance.peaknetvalue = performance.netvalue
    else
        performance.peaknetvalue = lastperformance.peaknetvalue    
    end
    
    performance.drawdown = 100.0 * (performance.peaknetvalue - performance.netvalue) / performance.peaknetvalue   

    if (performance.drawdown > lastperformance.maxdrawdown) 
        performance.maxdrawdown = performance.drawdown
    else
        performance.maxdrawdown = lastperformance.maxdrawdown
    end

    # Now here we run a specialized algorithm that updates performance based on 
    if lastperformance.period < 252
        performance. period = lastperformance.period + 1
        
        performance.sumdailyreturn = lastperformance.sumdailyreturn + performance.dailyreturn
        performance.sumsquareddailyreturn = lastperformance.sumsquareddailyreturn + performance.squareddailyreturn
        
        #annualvariance and annual standard deviation
        performance.averagedailyreturn = (performance.sumdailyreturn / performance.period)
        
        performance.annualreturn = 100.0 * ((1 + performance.averagedailyreturn/100.0)^252 - 1.0)

        performance.annualvariance = 252 * ((performance.sumsquareddailyreturn/performance.period) - performance.averagedailyreturn^2.0)
        performance.annualstandarddeviation = sqrt(performance.annualvariance)

        performance.sharperatio = sqrt(252) * (performance.averagedailyreturn / performance.annualstandarddeviation)
        performance.informationratio = performance.sharperatio
        
    elseif lastperformance.period >= 252

        performance.period = 252

        performance.sumdailyreturn = lastperformance.sumdailyreturn + performance.dailyreturn - firstperformance.dailyreturn
        performance.sumsquareddailyreturn = lastperformance.sumsquareddailyreturn + performance.squareddailyreturn - firstperformance.squareddailyreturn   
        
        performance.averagedailyreturn = performance.sumdailyreturn/performance.period
        performance.annualreturn = 100.0 * ((1 + performance.averagedailyreturn/100.0)^252 - 1.0)
        
        performance.annualvariance = 252 * ((performance.sumsquareddailyreturn/performance.period) - performance.averagedailyreturn^2.0)

        performance.annualstandarddeviation = sqrt(performance.annualvariance)

        performance.sharperatio = sqrt(252) * (performance.averagedailyreturn / performance.annualstandarddeviation)

        performance.informationratio = performance.sharperatio
        performance.drawdown
        
    end

    return performance

end


function computereturns(accounttracker, cashtracker)
    sortedkeys = sort(collect(keys(accounttracker)))
    returns = Vector{Float64}(1)

    #push!(returns, 0.0)

    if !isempty(sortedkeys)
        firstdate = sortedkeys[1]
        startingcaptital = accounttracker[firstdate].cash
        netvalue = startingcaptital

        for date in sortedkeys[2:end]
            oldnetvalue = netvalue

            netvalue = accounttracker[date].netvalue
            newfunds = haskey(cashtracker, date) ? cashtracker[date] : 0.0
            adjustednetvalue = netvalue - newfunds

            rt = oldnetvalue > 0.0 ? (netvalue - newfunds - oldnetvalue)/ oldnetvalue : 0.0

            push!(returns, rt)  

        end
    end
    return returns
end


"""
Function to calculate performance based on account and cash history
"""
function calculateperformance(accounttracker::AccountTracker, cashtracker::CashTracker)
    
    sortedkeys = sort(collect(keys(accounttracker)))
    returns = Vector{Float64}()

    if !isempty(sortedkeys)
        firstdate = sortedkeys[1]
        startingcaptital = accounttracker[firstdate].cash
        netvalue = startingcaptital

        for date in sortedkeys[2:end]
            oldnetvalue = netvalue

            netvalue = accounttracker[date].netvalue
            newfunds = haskey(cashtracker, date) ? cashtracker[date] : 0.0
            adjustednetvalue = netvalue - newfunds

            rt = oldnetvalue > 0.0 ? (netvalue - newfunds - oldnetvalue)/ oldnetvalue : 0.0

            push!(returns, rt)  
            println(netvalue) 
        end
    end

    return calculatesportfoliostats(returns)
end

"""
Function to compute portfolio statistics
"""
function calculatesportfoliostats(returns::Vector{Float64})
    ps = PortfolioStats()
    ps.annualreturn = calculateannualreturns(returns) 
    ps.totalreturn = calculatetotalreturn(returns)
    ps.annualstandarddeviation = calculatestandarddeviation(returns)
    ps.annualvariance = ps.annualstandarddeviation .* ps.annualstandarddeviation
    ps.sharperatio = zeros(length(returns))
    
    for i = 1:length(returns)
        ps.sharperatio[i] = ps.annualstandarddeviation[i] > 0.0 ? ps.annualreturn[i]./ ps.annualstandarddeviation[i] : 0.0
    end

    ps.informationratio = ps.sharperatio 
    ps.drawdown,ps.maxdrawdown = calculatedrawdown(returns)
    return ps
end 

"""
Function to compute annual returns
"""
function calculateannualreturns(returns::Vector{Float64}) 
    oness = ones(length(returns))
    100.0 * (cumsum(returns)./cumsum(oness)) * 252.0
end

"""
Function to compute total return
"""
function calculatetotalreturn(returns::Vector{Float64})
    100.0 * (cumprod(1.0 + returns) - 1.0)
end

"""
Function to compute standard deviation
"""
function calculatestandarddeviation(returns::Vector{Float64})
    std = zeros(length(returns))
    for i = 1:length(returns)

        demean = returns[1:i] - mean(returns[1:i])
        std[i] = 100.0 * mean(demean.*demean)*sqrt(252.0)     
    end

    return std
end

"""
Function to compute drawdown
"""
function calculatedrawdown(returns::Vector{Float64})
    netvalue = 10000.0 * (1.0 + cumprod(returns))
    drawdown = zeros(length(returns))
    maxdrawdown = zeros(length(returns))
    peak = -9999.0
    len = length(returns)
    
    for i in 1:len
      # peak will be the maximum value seen so far (0 to i), only get updated when higher NAV is seen
      if (netvalue[i] > peak) 
        peak = netvalue[i]
      end
      drawdown[i] = 100.0 * (peak - netvalue[i]) / peak
      # Same idea as peak variable, MDD keeps track of the maximum drawdown so far. Only get updated when higher DD is seen.
      if (drawdown[i] > maxdrawdown[i]) 
        maxdrawdown[i] = drawdown[i]
      elseif i > 1
        maxdrawdown[i] = maxdrawdown[i-1] 
      end
    end

    return (100.0*drawdown, 100.0*maxdrawdown)
end

