# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("PortfolioStats.jl")
#include("TradeStats.jl")
#include("../DataTypes/Trade.jl")


typealias AccountTracker Dict{DateTime, Account}
typealias CashTracker Dict{DateTime, Float64}
typealias PortfolioStatsTracker Dict{DateTime, PortfolioStats}  

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

