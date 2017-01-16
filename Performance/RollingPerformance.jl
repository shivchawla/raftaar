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
        currentperformance = _intializepeformance(accounttracker[actkeys[1]].cash)    
    end
   
    #update netvalue and leverage here
    currentperformance.portfoliostats.netvalue = accounttracker[date].netvalue
    currentperformance.portfoliostats.leverage = accounttracker[date].leverage

    #Add benchmark returns

    currentperformance.returns.dailyreturn_benchmark = benchmarktracker[date].returns.dailyreturn

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
        latestreturn = (benchmarkvalue - lastbenchmarkvalue)/lastbenchmarkvalue
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


function _computecurrentperformance(firstperformance::Performance, lastperformance::Performance, latestreturn::Float64)
    performance = Performance()
    performance.returns.dailyreturn = latestreturn
    performance.returns.totalreturn = lastperformance.returns.totalreturn * (1 + performance.returns.dailyreturn)
    
    if (performance.returns.totalreturn > lastperformance.returns.peaktotalreturn)
        performance.returns.peaktotalreturn = performance.returns.totalreturn
    else 
        performance.returns.peaktotalreturn = lastperformance.returns.peaktotalreturn
    end

    performance.deviation.squareddailyreturn =  performance.returns.dailyreturn * performance.returns.dailyreturn
    performance.drawdown.currentdrawdown = (performance.returns.peaktotalreturn - performance.returns.totalreturn) / performance.returns.peaktotalreturn
    if (performance.drawdown.currentdrawdown > lastperformance.drawdown.maxdrawdown) 
        performance.drawdown.maxdrawdown = performance.drawdown.currentdrawdown
    else
        performance.drawdown.maxdrawdown = lastperformance.drawdown.maxdrawdown
    end
    # Now here we run a specialized algorithm that updates performance based on 
    if lastperformance.period < 252
        performance.period = lastperformance.period + 1
        #performance.positivedays = performance.returns.dailyreturn > 0 ? lastperformance.positivedays + 1 : lastperformance.positivedays
        #performance.negativedays = performance.returns.dailyreturn < 0 ? lastperformance.negativedays + 1 : lastperformance.negativedays
        performance.deviation.sumdailyreturn = lastperformance.deviation.sumdailyreturn + performance.returns.dailyreturn
        performance.deviation.sumsquareddailyreturn = lastperformance.deviation.sumsquareddailyreturn + performance.deviation.squareddailyreturn
        #annualvariance and annual standard deviation
        performance.returns.averagedailyreturn = (performance.deviation.sumdailyreturn / performance.period)
        performance.returns.annualreturn = ((1 + performance.returns.averagedailyreturn)^252 - 1.0)
        #Unbiased estimator
        performance.deviation.annualvariance = 252 * (performance.period/(performance.period - 1)) * ((performance.deviation.sumsquareddailyreturn/performance.period) - performance.returns.averagedailyreturn^2.0)
        performance.deviation.annualstandarddeviation = sqrt(performance.deviation.annualvariance)
    elseif lastperformance.period >= 252

        performance.period = 252

        performance.deviation.sumdailyreturn = lastperformance.deviation.sumdailyreturn + performance.returns.dailyreturn - firstperformance.returns.dailyreturn
        performance.deviation.sumsquareddailyreturn = lastperformance.deviation.sumsquareddailyreturn + performance.deviation.squareddailyreturn - firstperformance.deviation.squareddailyreturn   
        
        performance.returns.averagedailyreturn = performance.deviation.sumdailyreturn/performance.period
        performance.returns.annualreturn = ((1 + performance.returns.averagedailyreturn)^252 - 1.0)
        
        #Unbiased estimator 
        performance.deviation.annualvariance = 252 * (performance.period/(performance.period - 1)) * ((performance.deviation.sumsquareddailyreturn/performance.period) - performance.returns.averagedailyreturn^2.0)
        performance.deviation.annualstandarddeviation = sqrt(performance.deviation.annualvariance)

    end

    return performance
end

#precompile(_computecurrentperformance, (Performance, Performance, Float64))

function updateperformanceratios(performancetracker::PerformanceTracker)
    sorteddates = sort(collect(keys(performancetracker)))

    if (length(sorteddates) < 2)
        return
    end
    #Initialize returns vector
    algorithmreturns = Vector{Float64}(length(sorteddates))
    benchmarkreturns = Vector{Float64}(length(sorteddates))

    latestperformance = performancetracker[sorteddates[end]]

    for i in 1:length(sorteddates)
        algorithmreturns[i] = performancetracker[sorteddates[i]].returns.dailyreturn
        benchmarkreturns[i] = performancetracker[sorteddates[i]].returns.dailyreturn_benchmark
    end

    s_idx = 1
    if length(sorteddates) > 252    #253
        s_idx = length(sorteddates) - 252 + 1   #2
    end

    df = DataFrame(X = benchmarkreturns[s_idx:end], Y = algorithmreturns[s_idx:end])
    OLS = lm(Y ~ X, df)
    coefficients = coef(OLS)
    latestperformance.ratios.beta = coefficients[2]
    latestperformance.ratios.alpha = coefficients[1]
    latestperformance.ratios.stability = r2(OLS)

    trkerr = sqrt(252) * std(algorithmreturns[s_idx:end] - benchmarkreturns[s_idx:end])
    excessret = 252 * mean(algorithmreturns[s_idx:end] - benchmarkreturns[s_idx:end])
    
    ##
    latestperformance.ratios.sharperatio = latestperformance.deviation.annualstandarddeviation > 0.0 ? latestperformance.returns.annualreturn / latestperformance.deviation.annualstandarddeviation : 0.0
    latestperformance.ratios.informationratio = trkerr > 0 ? excessret/trkerr : 0.0
    #latestperformance.ratios.sortinoratio = latestperformance.deviation.annualsemideviation > 0.0 ? latestperformance.returns.annualreturn / latestperformance.deviation.annualsemideviation : 0.0
    latestperformance.ratios.calmarratio = latestperformance.drawdown.maxdrawdown > 0.0 ? latestperformance.returns.annualreturn/latestperformance.drawdown.maxdrawdown : 0.0
end

#precompile(updateperformanceratios, (PerformanceTracker,))

######IMPROVEMENT: Don't calculate the whole series here
function computereturns(accounttracker, cashtracker)
    sortedkeys = sort(collect(keys(accounttracker)))
    returns = Vector{Float64}(length(sortedkeys))

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
    newfunds = haskey(cashtracker, lastdate) ? cashtracker[lastdate] : 0.0
    
    #netvalue = accounttracker[lastdate].netvalue
    #leverage = accounttracker[lastdate].leverage
    #adjustednetvalue = netvalue - newfunds    

    return returns[end] #, netvalue, newfunds, leverage
end

#precompile(computereturns, (AccountTracker, CashTracker))


