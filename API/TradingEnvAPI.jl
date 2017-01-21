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