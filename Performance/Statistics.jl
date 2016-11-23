# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using DataStructures
using JSON

import Base.convert

function outputbackteststatistics_partial(accttrkr::AccountTracker,
                                    pftrkr::PerformanceTracker,
                                    cshtrkr::CashTracker,
                                    trsctrkr::TransactionTracker,
                                    ordrtrkr::OrderTracker)


    #Create a sorted list of dates
    sorteddates = sort(collect(keys(pftrkr)))
 
    #creating the right format datastructures to save backtest info

    #Cumulative Strategy Equity Data
    equity = OrderedDict{String,Float64}()
    totalreturn = OrderedDict{String,Float64}()
        
    for i = 1:length(sorteddates)
        equity[string(sorteddates[i])] = round(100.0 * pftrkr[sorteddates[i]].netvalue,2)
        totalreturn[string(sorteddates[i])] = round(100.0 * pftrkr[sorteddates[i]].totalreturn,2)
    end

    lastperformance = pftrkr[sorteddates[end]] 
    
    # Create aggregate returns (JSON ready format)
    # Just the onthly returns in the basic run      
    monthlyreturns = getaggregatereturns(pftrkr, :Monthly)

    outputdict = Dict{String, Any}(
                    "outputtype" => "backtest",
                    "detail" => false,
                    "equity" => equity,
                    "totalreturn" => totalreturn,
                    "returns" => 
                        Dict{String, Any}(
                            "monthly" => monthlyreturns
                        ),
                    "analytics" => 
                        Dict{String, Any}(
                            "rolling" => convert(Dict, lastperformance)
                            
                        ) 
                    )
 
end

function outputbackteststatistics(accttrkr::AccountTracker,
                                    pftrkr::PerformanceTracker,
                                    cshtrkr::CashTracker,
                                    trsctrkr::TransactionTracker,
                                    ordrtrkr::OrderTracker)
    
    outputdict = outputbackteststatistics_partial(accttrkr,
                                    pftrkr,
                                    cshtrkr,
                                    trsctrkr,
                                    ordrtrkr)
    
    JSON.print(outputdict)
end

function outputbackteststatistics_full(accttrkr::AccountTracker,
                                    pftrkr::PerformanceTracker,
                                    cshtrkr::CashTracker,
                                    trsctrkr::TransactionTracker,
                                    ordrtrkr::OrderTracker)


    outputdict = outputbackteststatistics_partial(accttrkr,
                                    pftrkr,
                                    cshtrkr,
                                    trsctrkr,
                                    ordrtrkr)

    #update the detail to true
    outputdict["detail"] = true
    
    #Compute yearly and Weekly returns
    weeklyreturns, monthlyreturns, yearlyreturns = getaggregatereturns(pftrkr)
    outputdict["returns"]["weekly"] = weeklyreturns
    outputdict["returns"]["yearly"] = yearlyreturns

    #Now add fixed window based analytics too

    #Create a sorted list of dates
    monthlyanalytics = getmonthlyanalytics(pftrkr) 
    yearlyanalytics = getyearlyanalytics(pftrkr)

    #update the output dictionary with analytics

    outputdict["analytics"]["fixed"] = Dict{String, Any}(
                                                    "monthly" => monthlyanalytics,
                                                    "yearly" => yearlyanalytics)


    JSON.print(outputdict)
    println()
end

function getaggregatereturns(pft::PerformanceTracker, symbol::Symbol = :All)
    sorteddates = sort(collect(keys(pft)))
    date = sorteddates[1]
    
    yearlyreturns = OrderedDict{String, Float64}()
    monthlyreturns = OrderedDict{String, Float64}()
    weeklyreturns = OrderedDict{String, Float64}()


    i = 1
    yret = 1.0
    mret = 1.0
    wret = 1.0
    nyear = year = Dates.year(date)
    nmonth = month = Dates.month(date)
    nweek = week = Dates.week(date)

    wstr = mstr = ystr = ""
    
    while i < length(sorteddates)
        
        dailyreturn = pft[sorteddates[i]].dailyreturn

        #Yearly
        nyear = Dates.year(sorteddates[i])
        ystr = string(year)
        if (nyear == year)
            yret *= (1.0 + dailyreturn)
        else
            yearlyreturns[ystr] = round((yret - 1.0)*100.0,2)
            yret = (1.0 + dailyreturn)
        end

        year = nyear

        #Monthly
        if(month < 10)
            mstr = ystr*"0"*string(month)
        else
            mstr = ystr*string(month)
        end 
        
        nmonth = Dates.month(sorteddates[i])       
        if (nmonth == month)
            mret *= (1.0 + dailyreturn)
        else
            monthlyreturns[mstr] = round((mret - 1.0)*100.0,2)
            mret = (1.0 + dailyreturn)
        end

        month = nmonth

        #Weekly
        if(week < 10)
            wstr = mstr*"0"*string(week)
        else
            wstr = mstr*string(week)
        end 
        
        nweek = Dates.week(sorteddates[i])
        if (nweek == week)
            wret *= (1.0 + dailyreturn)
        else
            weeklyreturns[wstr] = round((wret - 1.0)*100.0,2)
            wret = (1.0 + dailyreturn)
        end

        week = nweek

        i = i + 1
        
    end

    if (year == nyear)
       yearlyreturns[ystr] = round((yret - 1.0) * 100.0, 2)
    end

    if (month == nmonth)
       monthlyreturns[mstr] = round((mret - 1.0) * 100.0, 2)
    end

    if (week == nweek)
       weeklyreturns[wstr] = round((wret - 1.0) * 100.0, 2)
    end

    if symbol == :All
        return weeklyreturns, monthlyreturns, yearlyreturns
    elseif symbol == :Weekly
        return weeklyreturns
    elseif symbol == :Monthly
        return monthlyreturns 
    elseif symbol == :Yearly
        return yearlyreturns  
    end

end   

function convert(::Type{Dict}, performance::Performance)
    Dict{String, Any}(  "annualreturn" => round(100.0 * performance.annualreturn,2), 
                        "totalreturn" => round(100.0 * performance.totalreturn,2),
                        "annualstandarddeviation" => round(100.0 * performance.annualstandarddeviation,2),
                        "annualvariance" => round(100.0 * 100.0 * performance.annualvariance,2),
                        "sharperatio" => round(performance.sharperatio,2),
                        "informationratio" => round(performance.informationratio,2),
                        "drawdown" => round(100.0 * performance.drawdown,2),
                        "maxdrawdown" => round(100.0 * performance.maxdrawdown,2),
                        "period" => round(performance.period,2)
                    )
end

function getmonthlyanalytics(pft::PerformanceTracker)
    sorteddates = sort(collect(keys(pft)))
    date = sorteddates[1]

    monthlyanalytics = OrderedDict{String, Dict{String,Float64}}()

    i = 1
    while i <= length(sorteddates)
        fdate = sorteddates[i]
        fmonth = Dates.month(fdate)
        ldate = sorteddates[i]
        lmonth = Dates.month(ldate)
        
        while fmonth == lmonth && i <= length(sorteddates)
            ldate = sorteddates[i]
            lmonth = Dates.month(ldate)
            i = i + 1
        end

        # Go-Back one day if month has changed
        if (fmonth != lmonth)
            ldate = sorteddates[i-1]
        end

        if fmonth < 10
            mstr = string(Dates.year(fdate)) * "0" * string(fmonth) 
        else    
            mstr = string(Dates.year(fdate)) * string(fmonth)
        end

        monthlyanalytics[mstr] =  convert(Dict, getperformanceforperiod(pft, fdate, ldate))
        
    end

    return monthlyanalytics

end


function getyearlyanalytics(pft::PerformanceTracker)
    sorteddates = sort(collect(keys(pft)))
    date = sorteddates[1]

    yearlyanalytics = OrderedDict{String, Dict{String,Float64}}()

    i = 1
    while i <= length(sorteddates)
        fdate = sorteddates[i]
        fyear = Dates.year(fdate)
        ldate = sorteddates[i]
        lyear = Dates.year(ldate)
        
        while fyear == lyear && i <= length(sorteddates)
            ldate = sorteddates[i]
            lyear = Dates.year(ldate)
            i = i + 1
        end

        # Go-Back one day if month has changed
        if (fyear != lyear)
            ldate = sorteddates[i-1]
        end

        ystr = string(Dates.year(fdate))

        yearlyanalytics[ystr] =  convert(Dict, getperformanceforperiod(pft, fdate, ldate))
    end

    return yearlyanalytics

end

function outputperformanceJSON(performancetracker::PerformanceTracker, date::Date)
    if date == Date()
        return
    else 
        if !haskey(performancetracker, date)
            return
        end
    end

    performance = performancetracker[date]

    jsondict = Dict{String, Any}("outputtype" => "performance",
                                "date" => date,
                                "dailyreturn" => round(100.0*performance.dailyreturn,2),
                                "netvalue" => round(performance.netvalue,2),
                                "annualreturn" => round(100.0*performance.annualreturn,2),
                                "totalreturn" => round(100.0*performance.totalreturn,2),
                                "annualstandarddeviation" => round(100.0*performance.annualstandarddeviation,2),
                                "annualvariance" => round(100.0*100.0*performance.annualvariance,2),
                                "sharperatio" => round(performance.sharperatio,2),
                                "informationratio" => round(performance.informationratio,2),
                                "drawdown" => round(100.0*performance.drawdown,2),
                                "maxdrawdown" => round(100.0*performance.maxdrawdown,2),
                                "leverage" => round(performance.leverage,2)
                            )
           
    JSON.print(jsondict)
    println()

end


                        