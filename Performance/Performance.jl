# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

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
    peaknormalizednetvalue::Float64
    normalizednetvalue::Float64
    leverage::Float64
end

Performance() = Performance(0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)

typealias AccountTracker Dict{Date, Account}
typealias CashTracker Dict{Date, Float64}
typealias PerformanceTracker Dict{Date, Performance}  


"""
Get performance for a specific period
"""
function getperformanceforperiod(performancetracker::PerformanceTracker, startdate::Date, enddate::Date)
    
    dailyreturns = Vector{Float64}()
    for date in startdate:enddate
        if(haskey(performancetracker, date))
            push!(dailyreturns, performancetracker[date].dailyreturn)
        end 
    end

    calculateperformance(dailyreturns)

end

"""
Updates performance of rolling window of 252 days
"""
function getlatestperformance(accounttracker::AccountTracker, cashtracker::CashTracker, performancetracker::PerformanceTracker)

    currentperformance = Performance()
    
    #use past performance and new netvalue and update the performance
    sorteddates = sort(collect(keys(performancetracker)))

    # Now, we need latest returns
    # But insted we calculate the whole series again
    # PERFORMANCE IMPROVEMENT
    
    if !isempty(sorteddates)
        
        #Get Latest Performance
        lastperformance = performancetracker[sorteddates[end]]
        
        if length(sorteddates) >= 252
            firstperformance = performancetracker[sorteddates[length(sorteddates) - 252 + 1]]
        else
            firstperformance = performancetracker[sorteddates[1]]
        end

        currentperformance = _computecurrentperformance(firstperformance, lastperformance, accounttracker, cashtracker) 

    else
        actkeys = sort(collect(keys(accounttracker)))
        currentperformance = _intializepeformance(accounttracker[actkeys[1]].cash)    
    end

    return currentperformance

    #performancetracker[date] = currentperformance

end

export getlatestperformance


function _intializepeformance(netvalue::Float64)
    performance = Performance()

    performance.netvalue = netvalue    
    performance.normalizednetvalue = netvalue
    performance.peaknormalizednetvalue = netvalue
    performance.period = 1

    return performance
end

function _computecurrentperformance(firstperformance::Performance, lastperformance::Performance, accounttracker::AccountTracker, cashtracker::CashTracker)

    (latestreturn, netvalue, newcash, leverage)  = computereturns(accounttracker, cashtracker)

    performance = Performance()
    
    performance.dailyreturn = latestreturn
    performance.squareddailyreturn =  performance.dailyreturn * performance.dailyreturn
    performance.totalreturn = ((1.0 + lastperformance.totalreturn) * (1 + performance.dailyreturn) - 1.0)
    performance.netvalue = netvalue
    #performance.adjustednetvalue = netvalue - newcash
    performance.leverage = leverage

    performance.normalizednetvalue = lastperformance.normalizednetvalue * (1.0 + performance.dailyreturn) 
    
    if (performance.normalizednetvalue > lastperformance.peaknormalizednetvalue)
        performance.peaknormalizednetvalue = performance.normalizednetvalue
    else 
        performance.peaknormalizednetvalue = lastperformance.peaknormalizednetvalue
    end
    
    #=if (performance.adjustednetvalue > lastperformance.peaknetvalue) 
        performance.peaknetvalue = performance.netvalue
    else
        performance.peaknetvalue = lastperformance.peaknetvalue + newcash   
    end=#
    
    performance.drawdown = (performance.peaknormalizednetvalue - performance.normalizednetvalue) / performance.peaknormalizednetvalue   

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
        
        performance.annualreturn = ((1 + performance.averagedailyreturn)^252 - 1.0)

        #Unbiased estimator
        performance.annualvariance = 252 * (performance.period/(performance.period - 1)) * ((performance.sumsquareddailyreturn/performance.period) - performance.averagedailyreturn^2.0)
        performance.annualstandarddeviation = sqrt(performance.annualvariance)

        # Multiply by 252 because denominator is already annualized
        performance.sharperatio = 252 * (performance.averagedailyreturn / performance.annualstandarddeviation)
        performance.informationratio = performance.sharperatio
        
    elseif lastperformance.period >= 252

        performance.period = 252

        performance.sumdailyreturn = lastperformance.sumdailyreturn + performance.dailyreturn - firstperformance.dailyreturn
        performance.sumsquareddailyreturn = lastperformance.sumsquareddailyreturn + performance.squareddailyreturn - firstperformance.squareddailyreturn   
        
        performance.averagedailyreturn = performance.sumdailyreturn/performance.period
        performance.annualreturn = ((1 + performance.averagedailyreturn)^252 - 1.0)
        
        #Unbiased estimator 
        performance.annualvariance = 252 * (performance.period/(performance.period - 1)) * ((performance.sumsquareddailyreturn/performance.period) - performance.averagedailyreturn^2.0)

        performance.annualstandarddeviation = sqrt(performance.annualvariance)

        # Multiply by 252 because denominator is already annualized
        performance.sharperatio = 252 * (performance.averagedailyreturn / performance.annualstandarddeviation)

        performance.informationratio = performance.sharperatio
        
    end

    return performance

end


function computereturns(accounttracker, cashtracker)
    sortedkeys = sort(collect(keys(accounttracker)))
    returns = Vector{Float64}(length(sortedkeys))

    #push!(returns, 0.0)
    if !isempty(sortedkeys)
        firstdate = sortedkeys[1]
        startingcaptital = accounttracker[firstdate].cash
        netvalue = startingcaptital


        for i in 2:length(sortedkeys)
            date = sortedkeys[i]
            oldnetvalue = netvalue

            netvalue = accounttracker[date].netvalue
            newfunds = haskey(cashtracker, date) ? cashtracker[date] : 0.0
            adjustednetvalue = netvalue - newfunds

            rt = oldnetvalue > 0.0 ? (netvalue - newfunds - oldnetvalue)/ oldnetvalue : 0.0

            returns[i] = rt   

        end
    end

    lastdate = sortedkeys[end]
    newfunds = haskey(cashtracker, lastdate) ? cashtracker[date] : 0.0
    netvalue = accounttracker[lastdate].netvalue
    leverage = accounttracker[lastdate].leverage
    #adjustednetvalue = netvalue - newfunds    

    return returns[end], netvalue, newfunds, leverage
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
        end
    end

    return calculatesportfoliostats(returns)
end

"""
Function to compute performance based on vector of returns
"""
function calculateperformance(returns::Vector{Float64})
   
    ps = Performance()
    ps.averagedailyreturn, ps.totalreturn, ps.annualreturn = aggregatereturns(returns) 
    
    ps.annualstandarddeviation , ps.annualvariance = calculatestandarddeviation(returns)
    
    ps.sharperatio = 0.0
    ps.sharperatio = ps.annualstandarddeviation > 0.0 ? ps.averagedailyreturn * 252 / ps.annualstandarddeviation : 0.0
    ps.informationratio = ps.sharperatio 

    ps.drawdown, ps.maxdrawdown = calculatedrawdown(returns)
    
    ps.period = length(returns)

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

function aggregatereturns(returns::Vector{Float64})
    totalreturn = calculatetotalreturn(returns)
    return totalreturn/length(returns), totalreturn, totalreturn*252/length(returns)
end


"""
Function to compute standard deviation
"""
function calculatestandarddeviation(returns::Vector{Float64})

    sdev = std(returns) * sqrt(252.0)
    
    return sdev, sdev*sdev
end

"""
Function to compute drawdown
"""
function calculatedrawdown(returns::Vector{Float64})
    netvalue = 100000.0 * cumprod(1.0 + returns) 
    drawdown = zeros(length(returns))
    maxdrawdown = zeros(length(returns))
    peak = -9999.0
    len = length(returns)
    
    for i in 1:len
      # peak will be the maximum value seen so far (0 to i), only get updated when higher NAV is seen
      if (netvalue[i] > peak) 
        peak = netvalue[i]
      end
      drawdown[i] = (peak - netvalue[i]) / peak
      # Same idea as peak variable, MDD keeps track of the maximum drawdown so far. Only get updated when higher DD is seen.
      if (drawdown[i] > maxdrawdown[i]) 
        maxdrawdown[i] = drawdown[i]
      elseif i > 1
        maxdrawdown[i] = maxdrawdown[i-1] 
      end
    end

    return (drawdown[end], maxdrawdown[end])
end






