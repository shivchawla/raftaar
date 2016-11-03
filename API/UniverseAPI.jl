import Raftaar: getlatestprice

"""
Functions to expose Universe API
""" 
function adduniverse(ticker::String;
                        securitytype::String="EQ",
                        exchange::String="NSE")
    adduniverse!(algorithm.universe, ticker, 
                    securitytype = securitytype,
                    exchange = exchange)
end

function adduniverse(tickers::Vector{String};
                        securitytype::String="EQ",
                        exchange::String="NSE")
    
    for ticker in tickers
        adduniverse(tickers, securitytype = securitytype, exchange = exchange)
    end
end

function setuniverse(ticker::String;
                        securitytype::String="EQ",
                        exchange::String="NSE")
    
    #checkforparent(:setuniverse, :initialize)
   
    setuniverse!(algorithm.universe, [ticker],
                    securitytype = securitytype,
                    exchange = exchange)
end

function setuniverse(tickers::Vector{String};
                        securitytype::String="EQ",
                        exchange::String="NSE")
    
    #checkforparent(:setuniverse, :initialize)
   
    setuniverse!(algorithm.universe, tickers,
                    securitytype = securitytype,
                    exchange = exchange)
end


#=function adduniverse(ticker::String, securitytype::SecurityType = SecurityType(InValid))
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
    adduniverse!(algorithm.universe, ticker, securitytype)
end

function adduniverse(tickers::Vector{String}, securitytype::SecurityType = SecurityType(InValid))
    for ticker in tickers
        adduniverse(ticker, securitytype)
    end
end


function adduniverse(ticker::String, securitytype::SecurityType = SecurityType(InValid))
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
    adduniverse!(algorithm.universe, ticker, securitytype)
end

function adduniverse(tickers::Vector{String}, securitytype::SecurityType = SecurityType(InValid))
    for ticker in tickers
        adduniverse(ticker, securitytype)
    end
end

function setuniverse(ticker::String, securitytype::SecurityType = SecurityType(InValid))
    checkforparent(:setuniverse, :initialize)
   
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
    
    setuniverse1!(algorithm.universe, ticker, securitytype)
end

function setuniverse(tickers::Vector{String}, securitytype::SecurityType = SecurityType(InValid))
    checkforparent(:setuniverse, :initialize)
  
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
      
    setuniverse2!(algorithm.universe, tickers, securitytype)
end=#

function getuniverse()  #return array of security symbol
    deepcopy(getuniverse(algorithm.universe))
end

function updatesecurity(security::Security, id::Int)
    updatesecurity!(algorithm.universe, security, id)
end

function cantrade(ticker::String)
    cantrade(symbol, algorithm.tradeenv.defaultsecuritytype, algorithm.tradeenv.datetime)
end 

function cantrade(symbol::SecuritySymbol)
    cantrade(symbol, algorithm.tradeenv.datetime)
end 

function cantrade(security::Security)
    cantrade(security, algorithm.tradeenv.datetime)
end 

function getlatestprice(symbol::SecuritySymbol)
    return getlatestprice(algorithm.universe, symbol)
end
