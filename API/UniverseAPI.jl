import Raftaar: getlatestprice

"""
Functions to expose Universe API
"""

function removeuniverse(ticker::String;securitytype::String="EQ",
                        exchange::String="NSE")

    security = getsecurity(ticker, securitytype=securitytype, exchange=exchange)
    removeuniverse!(algorithm.universe, security) 
end

function removeuniverse(secid::Int)
    security = getsecurity(secid)
    removeuniverse!(algorithm.universe, security) 
end

function removeuniverse(symbol::SecuritySymbol)
    removeuniverse!(algorithm.universe, getsecurity(symbol.id)) 
end

function removeuniverse(security::Security)
    removeuniverse!(algorithm.universe, security) 
end

function adduniverse(ticker::String;
                        securitytype::String="EQ",
                        exchange::String="NSE")
      
    security = getsecurity(ticker, securitytype=securitytype, exchange=exchange)
    adduniverse!(algorithm.universe, security)
end


function adduniverse(tickers::Vector{String};
                        securitytype::String="EQ",
                        exchange::String="NSE")
    for ticker in tickers
        adduniverse(ticker, securitytype = securitytype, exchange = exchange)
    end
end

function adduniverse(secid::Int)
    adduniverse(getsecurity(secid))
end

function adduniverse(secids::Vector{Int})

    for secid in secids
        adduniverse(secid)
    end
end

function adduniverse(symbol::SecuritySymbol)
    adduniverse(symbol.id)
end

function adduniverse(symbols::Vector{SecuritySymbol})

    for symbol in symbols
        adduniverse(symbol)
    end
end

function adduniverse(security::Security)
    adduniverse!(algorithm.universe, security)
end

function adduniverse(securities::Vector{Security})

    for security in securities
        adduniverse(security)
    end
end


export adduniverse

function setuniverse(ticker::String;
                        securitytype::String="EQ",
                        exchange::String="NSE")
    
    # Get security id for the ticker before adding to the Raftaar
    security = getsecurity(ticker, securitytype=securitytype, exchange=exchange)
    setuniverse!(algorithm.universe, security)
   
end

function setuniverse(tickers::Vector{String};
                        securitytype::String="EQ",
                        exchange::String="NSE")

    securities = Vector{Security}()
    inuniverse = Dict{String, Bool}()

    for i in 1:length(tickers)
        if !haskey(inuniverse, tickers[i])
            security = getsecurity(tickers[i], securitytype = securitytype, exchange = exchange)
            push!(securities, security)
            inuniverse[tickers[i]] = true
        end    
    end

    #Add the benchmark security to the universe
    #=benchmark = getbenchmark()
    
    if !haskey(inuniverse, benchmark.ticker) && benchmark.ticker!=""
        push!(securities, getsecurity(benchmark.ticker))
        inuniverse[benchmark.ticker] = true
    end=#

    setuniverse!(algorithm.universe, securities)
end

function setuniverse(secids::Vector{Int})

    securities = Vector{Security}()
    inuniverse = Dict{Int, Bool}()

    for i in 1:length(secids)
        if !haskey(inuniverse, secids[i])
            security = getsecurity(secids[i])
            push!(securities, security)
            inuniverse[secids[i]] = true
        end    
    end

    #Add the benchmark security to the universe
    #=benchmark = getbenchmark()
    
    if !haskey(inuniverse, benchmark.ticker) && benchmark.ticker!=""
        push!(securities, getsecurity(benchmark.ticker))
        inuniverse[benchmark.id] = true
    end=#

    setuniverse!(algorithm.universe, securities)
end    

export setuniverse


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

function getuniverse(;validprice=true)  #return array of security symbol

    if validprice
        securities_with_valid_price = Vector{Security}()
        for sec in getuniverse(algorithm.universe)
            price = getlatestprice(sec.symbol)
            if price != 0.0
                push!(securities_with_valid_price, sec)
            end
        end
        
        if(length(securities_with_valid_price) == 0)
            Logger.warn("Empty universe")
        end
        
        return securities_with_valid_price
    else
        deepcopy(getuniverse(algorithm.universe))
    end   
end
export getuniverse

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
export getlatestprice


function ispartofuniverse(security::Security)
    return contains(algorithm.universe, security.symbol) 
end

function ispartofuniverse(symbol::SecuritySymbol)
    return contains(algorithm.universe, symbol) 
end

function ispartofuniverse(secid::Int)   
    return contains(algorithm.universe, getsecurity(secid)) 
end

function ispartofuniverse(ticker::String)
    return contains(algorithm.universe, getsecurity(ticker)) 
end
export ispartofuniverse


