"""
Functions to expose trading environment API
""" 
function setresolution(resolution::Resolution)
    checkforparent(:setresolution, :initialize)
    setresolution!(algorithm.tradeenv, resolution)
end

function setstartdate(datetime::DateTime)    
    setstartdate!(algorithm.tradeenv, datetime)
end

function setenddate(datetime::DateTime)
    setenddate!(algorithm.tradeenv, datetime)
end

function setcurrentdatetime(datetime::DateTime)
    setcurrentdatetime!(algorithm.tradeenv, datetime) 
    Logger.configure(algo_clock = datetime)
end

function getstartdate()
    algorithm.tradeenv.startdate
end

function getenddate()
    algorithm.tradeenv.enddate
end

function getcurrentdatetime()
    algorithm.tradeenv.currentdatetime
end
