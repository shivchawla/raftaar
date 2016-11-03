using JSON

include("../Performance/Performance.jl")

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
                                "dailyreturn" => performance.dailyreturn,
                                "netvalue" => performance.netvalue,
                                "annualreturn" => performance.annualreturn,
                                "totalreturn" => performance.totalreturn,
                                "annualstandarddeviation" => performance.annualstandarddeviation,
                                "annualvariance" => performance.annualvariance,
                                "sharperatio" => performance.sharperatio,
                                "informationratio" => performance.informationratio,
                                "drawdown" => performance.drawdown,
                                "maxdrawdown" => performance.maxdrawdown)
                                
    JSON.print(jsondict)

end




   