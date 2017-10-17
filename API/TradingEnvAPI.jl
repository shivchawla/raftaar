"""
Functions to expose trading environment API
"""
function setresolution(resolution::Resolution)
    __IllegalContextMessage(:setresolution, :ondata)
    setresolution!(algorithm.tradeenv, resolution)
end

function setresolution(resolution::String)
    __IllegalContextMessage(:setresolution, :ondata)
    setresolution!(algorithm.tradeenv, resolution)
end

runStartDate = Date(now())
runEndDate = Date(now())
wasRunStartDateFound = false
wasRunEndDateFound = false

function setstartdate(date::Date; forward_with_serialize_data = false)
    __IllegalContextMessage(:setstartdate, :ondata)

    if forward_with_serialize_data
        global runStartDate = date
        global wasRunStartDateFound = true
    else
        setstartdate!(algorithm.tradeenv, date)
    end
end

function setstartdate(dt::DateTime; forward_with_serialize_data = false)
    __IllegalContextMessage(:setstartdate, :ondata)
    setstartdate(Date(dt), forward_with_serialize_data = forward_with_serialize_data)
end

function setstartdate(date::String; format="yyyy-mm-dd", forward_with_serialize_data = false)
    __IllegalContextMessage(:setstartdate, :ondata)
    setstartdate(Date(date, format), forward_with_serialize_data = forward_with_serialize_data)
end
export setstartdate

function setenddate(date::Date; forward_with_serialize_data = false)
    __IllegalContextMessage(:setenddate, :ondata)
    if forward_with_serialize_data
        global runEndDate = date
        global wasRunEndDateFound = true
    else
        setenddate!(algorithm.tradeenv, date)
    end
end

function setenddate(dt::DateTime; forward_with_serialize_data = false)
    __IllegalContextMessage(:setenddate, :ondata)
    setenddate(Date(dt), forward_with_serialize_data = forward_with_serialize_data)
end

function setenddate(date::String; format="yyyy-mm-dd", forward_with_serialize_data = false)
    __IllegalContextMessage(:setenddate, :ondata)
    setenddate(Date(date, format), forward_with_serialize_data = forward_with_serialize_data)
end
export setenddate

function getrunstartdate()
    return wasRunStartDateFound ? runStartDate : (getenddate() + Base.Dates.Day(1))
end
export getrunstartdate

function getrunenddate()
    return wasRunEndDateFound ? runEndDate : (getenddate() + Base.Dates.Day(1))
end
export getrunenddate

function setcurrentdate(date::Date)
    setcurrentdate!(algorithm.tradeenv, date)
    Logger.updateclock(DateTime(date))
end
export setcurrentdatetime

function setinvestmentplan(plan::String)
    __IllegalContextMessage(:setinvestmentplan, :ondata)
    setinvestmentplan!(algorithm.tradeenv, plan)
end

function setinvestmentplan(plan::InvestmentPlan)
    __IllegalContextMessage(:setinvestmentplan, :ondata)
    setinvestmentplan!(algorithm.tradeenv, plan)
end

function setrebalance(rebalance::String)
    __IllegalContextMessage(:setrebalance, :ondata)
    setrebalance!(algorithm.tradeenv, rebalance)
end

function setrebalance(rebalance::Rebalance)
    __IllegalContextMessage(:setrebalance, :ondata)
    setrebalance!(algorithm.tradeenv, rebalance)
end

export setrebalance, setinvestmentplan

function setbenchmarkvalues(prices::Dict{String, Float64})
    __IllegalContextMessage(:setbenchmarkvalues, :ondata)
    setbenchmarkvalues!(algorithm.tradeenv, prices)
end
export setbenchmarkvalues

function getbenchmark()
    return algorithm.tradeenv.benchmark
end

function getstartdate()
    algorithm.tradeenv.startdate
end
export getstartdate

function getenddate()
    algorithm.tradeenv.enddate
end
export getenddate

function getcurrentdate()
    algorithm.tradeenv.currentdate
end

function getcurrentdatetime()
    DateTime(getcurrentdate())
end
export getcurrentdate, getcurrentdatetime


function getinvestmentplan()
  algorithm.tradeenv.investmentplan
end
export getinvestmentplan

function getrebalancefrequency()
  algorithm.tradeenv.rebalance
end
export getrebalancefrequency
