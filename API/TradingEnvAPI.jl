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
export setstartdate

function setenddate(date::Date)
    checkforparent([:initialize,:_init])
    setenddate!(algorithm.tradeenv, date)
end
export setenddate

function setcurrentdatetime(datetime::DateTime)
    setcurrentdatetime!(algorithm.tradeenv, datetime) 
    Logger.updateclock(datetime)
end
export setcurrentdatetime

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

function getcurrentdatetime()
    algorithm.tradeenv.currentdatetime
end
export getcurrentdatetime