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

function setstartdate(date::Date)  
    checkforparent([:initialize,:_init])
    setstartdate!(algorithm.tradeenv, date)
end

function setstartdate(dt::DateTime)  
    checkforparent([:initialize,:_init])
    setstartdate!(algorithm.tradeenv, Date(dt))
end

function setstartdate(date::String; format="yyyy-mm-dd")  
    checkforparent([:initialize,:_init])
    setstartdate!(algorithm.tradeenv, Date(date, format))
end
export setstartdate

function setenddate(date::Date)
    checkforparent([:initialize,:_init])
    setenddate!(algorithm.tradeenv, date)
end

function setenddate(dt::DateTime)
    checkforparent([:initialize,:_init])
    setenddate!(algorithm.tradeenv, Date(dt))
end

function setenddate(date::String; format="yyyy-mm-dd")
    checkforparent([:initialize,:_init])
    setenddate!(algorithm.tradeenv, Date(date, format))
end
export setenddate

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

