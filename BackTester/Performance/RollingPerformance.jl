
function _nanAdjusted(value; default=0.0)
    isnan(value) ? default : value 
end

"""
Updates performance of rolling window of 252 days
"""
function updatelatestperformance_algorithm(accounttracker::AccountTracker, cashtracker::CashTracker, performancetracker::PerformanceTracker, benchmarktracker::PerformanceTracker, date::Date)

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
        currentperformance = _intializepeformance(accounttracker[actkeys[1]].netvalue)
        currentperformance = _computecurrentperformance(currentperformance, currentperformance, accounttracker, cashtracker)     
    end
   
    #update netvalue and leverage here
    currentperformance.portfoliostats.netvalue = accounttracker[date].netvalue
    currentperformance.portfoliostats.leverage = accounttracker[date].leverage

    #Add benchmark returns

    currentperformance.returns.dailyreturn_benchmark = _nanAdjusted(benchmarktracker[date].returns.dailyreturn)

    #nowupdate the performance tracker
    performancetracker[date] = currentperformance
       
    # now update ratios dependent on benchmark
    updateperformanceratios(performancetracker)
end

#precompile(updatelatestperformance_algorithm, (AccountTracker,CashTracker, PerformanceTracker,PerformanceTracker,Date))

"""
Updates performance of benchmark rolling window of 252 days
"""
function updatelatestperformance_benchmark(performancetracker::PerformanceTracker, benchmarkvalue::Float64, date::Date)

    #use past performance and new netvalue and update the performance
    sorteddates = sort(collect(keys(performancetracker)))

    # Now, we need latest returns
    # But insted we calculate the whole series again
    # PERFORMANCE IMPROVEMENT
    
    if !isempty(sorteddates)
        
        # Get last Performance
        lastperformance = performancetracker[sorteddates[end]]
        
        if length(sorteddates) >= 252
            firstperformance = performancetracker[sorteddates[length(sorteddates) - 252 + 1]]
        else
            firstperformance = performancetracker[sorteddates[1]]
        end

        lastbenchmarkvalue = lastperformance.portfoliostats.netvalue

        latestreturn = abs(lastbenchmarkvalue) > 0.0  && abs(benchmarkvalue) > 0.0 ? (benchmarkvalue - lastbenchmarkvalue)/lastbenchmarkvalue : 0.0
        performancetracker[date] = _computecurrentperformance(firstperformance, lastperformance, latestreturn) 

    else
        performancetracker[date] = _intializepeformance(benchmarkvalue)    
    end

    performancetracker[date].portfoliostats.netvalue = benchmarkvalue
   
end

#precompile(updatelatestperformance_benchmark,(PerformanceTracker,Float64,Date))

function _intializepeformance(netvalue::Float64)
    performance = Performance()

    performance.portfoliostats.netvalue = netvalue    
    performance.period = 1

    return performance
end

function _computecurrentperformance(firstperformance::Performance, lastperformance::Performance, accounttracker::AccountTracker, cashtracker::CashTracker)

    latestreturn  = computereturns(accounttracker, cashtracker)
    latestperformance = _computecurrentperformance(firstperformance, lastperformance, latestreturn)
    return latestperformance
end


#Annual RETURN cacualtion is wrong....It should use calendar period!!!
function _computecurrentperformance(firstperformance::Performance, lastperformance::Performance, latestreturn::Float64)
    performance = Performance()
    performance.returns.dailyreturn = latestreturn

    #Handling Initial NaN values
    lastTotalReturn = _nanAdjusted(lastperformance.returns.totalreturn)
    lastPeakTotalReturn = _nanAdjusted(lastperformance.returns.peaktotalreturn, default=1.0)

    performance.returns.totalreturn =  (1 + lastTotalReturn) * (1 + performance.returns.dailyreturn) - 1
    
    if (1 + performance.returns.totalreturn) > lastPeakTotalReturn
        performance.returns.peaktotalreturn =  1 + performance.returns.totalreturn
    else 
        performance.returns.peaktotalreturn = lastPeakTotalReturn
    end

    performance.deviation.squareddailyreturn =  performance.returns.dailyreturn * performance.returns.dailyreturn
    performance.drawdown.currentdrawdown = (performance.returns.peaktotalreturn - (1+ performance.returns.totalreturn)) / performance.returns.peaktotalreturn

    lastMaxDrawdown = _nanAdjusted(lastperformance.drawdown.maxdrawdown)

    if (performance.drawdown.currentdrawdown > lastMaxDrawdown) 
        performance.drawdown.maxdrawdown = performance.drawdown.currentdrawdown
    else
        performance.drawdown.maxdrawdown = lastMaxDrawdown
    end

    lastSumDailyReturn = _nanAdjusted(lastperformance.deviation.sumdailyreturn)
    lastSumSquaredDailyReturn = _nanAdjusted(lastperformance.deviation.sumsquareddailyreturn)

    firstSumDailyReturn = _nanAdjusted(firstperformance.deviation.sumdailyreturn)
    firstSumSquaredDailyReturn = _nanAdjusted(firstperformance.deviation.sumsquareddailyreturn)

    # Now here we run a specialized algorithm that updates performance based on 
    if lastperformance.period < 1000000000
        performance.period = lastperformance.period + 1

        
        performance.deviation.sumdailyreturn = lastSumDailyReturn + performance.returns.dailyreturn
        performance.deviation.sumsquareddailyreturn = lastSumSquaredDailyReturn + performance.deviation.squareddailyreturn
        #annualvariance and annual standard deviation
        performance.returns.averagedailyreturn = (performance.deviation.sumdailyreturn / performance.period)
        performance.returns.annualreturn = ((1 + performance.returns.averagedailyreturn)^252 - 1.0)
        #Unbiased estimator
        performance.deviation.annualvariance = 252 * (performance.period/(performance.period - 1)) * ((performance.deviation.sumsquareddailyreturn/performance.period) - performance.returns.averagedailyreturn^2.0)
        performance.deviation.annualstandarddeviation = sqrt(performance.deviation.annualvariance)
    elseif lastperformance.period >= 252

        performance.period = 252

        performance.deviation.sumdailyreturn = lastSumDailyReturn + performance.returns.dailyreturn - firstSumDailyReturn
        performance.deviation.sumsquareddailyreturn = lastSumSquaredDailyReturn + performance.deviation.squareddailyreturn - firstSumSquaredDailyReturn
        
        performance.returns.averagedailyreturn = performance.deviation.sumdailyreturn/performance.period
        performance.returns.annualreturn = ((1 + performance.returns.averagedailyreturn)^252 - 1.0)
        
        #Unbiased estimator 
        performance.deviation.annualvariance = 252 * (performance.period/(performance.period - 1)) * ((performance.deviation.sumsquareddailyreturn/performance.period) - performance.returns.averagedailyreturn^2.0)
        performance.deviation.annualstandarddeviation = sqrt(performance.deviation.annualvariance)

    end

    return performance
end

function updateperformanceratios(performancetracker::PerformanceTracker)
    sorteddates = sort(collect(keys(performancetracker)))
 
    #Initialize returns vector
    algorithmreturns = Vector{Float64}(undef, length(sorteddates))
    benchmarkreturns = Vector{Float64}(undef, length(sorteddates))

    latestperformance = performancetracker[sorteddates[end]]

    for i in 1:length(sorteddates)
        algorithmreturns[i] = _nanAdjusted(performancetracker[sorteddates[i]].returns.dailyreturn)
        benchmarkreturns[i] = _nanAdjusted(performancetracker[sorteddates[i]].returns.dailyreturn_benchmark)
    end

    s_idx = 1

    if (length(sorteddates) > 5)
        df = DataFrame(X = benchmarkreturns[s_idx:end], Y = algorithmreturns[s_idx:end])
        try
            if(size(df, 1) > 2)
                OLS = fit(LinearModel, @formula(Y ~ X), df)
                coefficients = coef(OLS)
                latestperformance.ratios.beta = coefficients[2]
                latestperformance.ratios.alpha = coefficients[1]
                latestperformance.ratios.stability = r2(OLS)
            end
        catch err
            println(err)
        end
    end

    trkerr = sqrt(252) * std(algorithmreturns[s_idx:end] - benchmarkreturns[s_idx:end])
    excessret = 252 * mean(algorithmreturns[s_idx:end] - benchmarkreturns[s_idx:end])
    
    ##
    latestperformance.ratios.sharperatio = _nanAdjusted(latestperformance.deviation.annualstandarddeviation) > 0.0 ? (latestperformance.returns.annualreturn - 0.065) / latestperformance.deviation.annualstandarddeviation : 0.0
    latestperformance.ratios.informationratio = trkerr > 0 ? excessret/trkerr : 0.0
    #latestperformance.ratios.sortinoratio = latestperformance.deviation.annualsemideviation > 0.0 ? latestperformance.returns.annualreturn / latestperformance.deviation.annualsemideviation : 0.0
    latestperformance.ratios.calmarratio = _nanAdjusted(latestperformance.drawdown.maxdrawdown) > 0.0 ? _nanAdjusted(latestperformance.returns.annualreturn)/_nanAdjusted(latestperformance.drawdown.maxdrawdown) : 0.0
end


######IMPROVEMENT: Don't calculate the whole series here
function computereturns(accounttracker, cashtracker)
    sortedkeys = sort(collect(keys(accounttracker)))
    returns = Vector{Float64}(undef, length(sortedkeys))

    if !isempty(sortedkeys)
        firstdate = sortedkeys[1]
        startingcaptital = accounttracker[firstdate].seedcash
        netvalue = startingcaptital

        for i in 1:length(sortedkeys)

            date = sortedkeys[i]
            oldnetvalue = netvalue

            netvalue = accounttracker[date].netvalue
            
            newfunds = 0
            if i > 1 #seedcash is already part of netvalue on day 1
                newfunds = get(cashtracker, date, 0.0)
            end

            adjustednetvalue = netvalue - newfunds

            rt = oldnetvalue > 0.0 ? (netvalue - newfunds - oldnetvalue)/ oldnetvalue : 0.0
            returns[i] = rt   

        end
    end

    return returns[end] 
end
