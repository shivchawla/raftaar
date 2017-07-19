"""
Functions to expose trading environment API
"""
function setresolution(resolution::Resolution)
    checkforparent(:initialize)
    setresolution!(algorithm.tradeenv, resolution)
end

function setresolution(resolution::String)
    checkforparent([:initialize,:_init])
    setresolution!(algorithm.tradeenv, resolution)
end

runStartDate = Date(now())
runEndDate = Date(now())
wasRunStartDateFound = false
wasRunEndDateFound = false

function setstartdate(date::Date; forward_with_serialize_data = false)
    checkforparent([:initialize,:_init])
    if forward_with_serialize_data
        global runStartDate = date
        global wasRunStartDateFound = true
    else
        setstartdate!(algorithm.tradeenv, date)
    end
end

function setstartdate(dt::DateTime; forward_with_serialize_data = false)
    checkforparent([:initialize,:_init])
    if forward_with_serialize_data
        global runStartDate = Date(dt)
        global wasRunStartDateFound = true
    else
        setstartdate!(algorithm.tradeenv, Date(dt))
    end
end

function setstartdate(date::String; format="yyyy-mm-dd", forward_with_serialize_data = false)
    checkforparent([:initialize,:_init])
    if forward_with_serialize_data
        global runStartDate = Date(date, format)
        global wasRunStartDateFound = true
    else
        setstartdate!(algorithm.tradeenv, Date(date, format))
    end
end
export setstartdate

function setenddate(date::Date; forward_with_serialize_data = false)
    checkforparent([:initialize,:_init])
    if forward_with_serialize_data
        global runEndDate = date
        global wasRunEndDateFound = true
    else
        setenddate!(algorithm.tradeenv, date)
    end
end

function setenddate(dt::DateTime; forward_with_serialize_data = false)
    checkforparent([:initialize,:_init])
    if forward_with_serialize_data
        global runEndDate = Date(dt)
        global wasRunEndDateFound = true
    else
        setenddate!(algorithm.tradeenv, Date(dt))
    end
end

function setenddate(date::String; format="yyyy-mm-dd", forward_with_serialize_data = false)
    checkforparent([:initialize,:_init])
    if forward_with_serialize_data
        global runEndDate = Date(date, format)
        global wasRunEndDateFound = true
    else
        setenddate!(algorithm.tradeenv, Date(date, format))
    end
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
    setinvestmentplan!(algorithm.tradeenv, plan)
end

function setrebalance(rebalance::String)
    setrebalance!(algorithm.tradeenv, rebalance)
end

function setinvestmentplan(plan::InvestmentPlan)
    setinvestmentplan!(algorithm.tradeenv, plan)
end

function setrebalance(rebalance::Rebalance)
    setrebalance!(algorithm.tradeenv, rebalance)
end

export setrebalance, setinvestmentplan

function setbenchmarkvalues(prices::Dict{String, Float64})
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
