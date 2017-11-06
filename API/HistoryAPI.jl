__precompile__(true)

module HistoryAPI

using API
using TimeSeries
using YRead
using Raftaar

import YRead: history 
#history_unadj, getsecurity, getsecurityid, getsecurityids, getsymbol

function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int)
    
    __IllegalContextMessage(:history, :initalize)

    ids = [security.symbol.id  for security in securities]
    history(ids, datatype, frequency, horizon)

end

function history(symbols::Vector{SecuritySymbol},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int)
    
    __IllegalContextMessage(:history, :initalize)

    ids = [symbol.id for symbol in symbols]
    history(ids, datatype, frequency, horizon)
end

function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int) 
    __IllegalContextMessage(:history, :initalize)

    tickers = [getsecurity(secid).symbol.ticker for secid in secids]
    history(tickers, datatype, frequency, horizon)  

end

# Based on symbols
function history(tickers::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")
    
    __IllegalContextMessage(:history, :initalize)

    SIZE = 500

    if frequency!=:Day
        info("""Only ":Day" frequency supported in history()""")
        exit()
    end

    #=if enddate == DateTime()
        enddate = getcurrentdatetime()
     elseif !checkforparent([:_init])
        Logger.error("history() can not be called with enddate argument")
        exit()
    end=#


    tickers = length(tickers) > SIZE ? tickers[1:SIZE] : tickers
 
    YRead.history(tickers, datatype, frequency, horizon, getcurrentdatetime(),
            securitytype = securitytype,
            exchange = exchange,
            country = country)[tickers]  
end

# Period based History
#=function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    __IllegalContextMessage(:history, :initalize)

    ids = [security.symbol.id for security in securities]
    history(ids, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype = securitytype,
                exchange = exchange,
                country = country)
    
end

function history(symbols::Vector{SecuritySymbol},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    __IllegalContextMessage(:history, :initalize)

    ids = [symbol.id for symbol in symbols]
    history(ids, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype = securitytype,
                exchange = exchange,
                country = country)   
end


function history(secids::Vector{Int},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    __IllegalContextMessage(:history, :initalize)

    tickers = [getsecurity(secid).symbol.ticker for secid in secids]
    
    history(tickers, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype = securitytype,
                exchange = exchange,
                country = country)
end

function history(tickers::Vector{String},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 

    __IllegalContextMessage(:history, :initalize)

    SIZE = 50
    tickers = length(tickers) > SIZE ? tickers[1:50] : tickers

    YRead.history(tickers, datatype, frequency, startdate, enddate,
                    securitytype = securitytype,
                    exchange = exchange,
                    country = country)
end

export history

#for Unadjusted History
function history_unadj(securities::Vector{Security},
                        datatype::String,
                        frequency::Symbol;
                        startdate::DateTime = now(),
                        enddate::DateTime = now(),                   
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN") 
    
    __IllegalContextMessage(:history_unadj, :initalize)

    ids = [security.symbol.id for security in securities]
    history_unadj(ids, datatype, frequency, 
                    startdate = startdate,
                    enddate = enddate,
                    securitytype = securitytype,
                    exchange = exchange,
                    country = country)
    
end

function history_unadj(symbols::Vector{SecuritySymbol},
                        datatype::String,
                        frequency::Symbol;
                        startdate::DateTime = now(),
                        enddate::DateTime = now(),                   
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN") 
    
    __IllegalContextMessage(:history_unadj, :initalize)

    ids = [symbol.id for symbol in symbols]
    history_unadj(ids, datatype, frequency, 
                    startdate = startdate,
                    enddate = enddate,
                    securitytype  =securitytype,
                    exchange = exchange,
                    country = country)   
end

function history_unadj(tickers::Vector{String},
                        datatype::String,
                        frequency::Symbol;
                        startdate::DateTime = now(),
                        enddate::DateTime = now(),                   
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN") 
    
    __IllegalContextMessage(:history_unadj, :initalize)

    SIZE = 50
    tickers = length(tickers) > SIZE ? tickers[1:50] : tickers
    
    YRead.history_unadj(tickers, datatype, frequency, startdate, enddate,
                        securitytype  =securitytype,
                        exchange = exchange,
                        country = country)      
end

function history_unadj(secids::Vector{Int},
                        datatype::String,
                        frequency::Symbol;
                        startdate::DateTime = now(),
                        enddate::DateTime = now(),                   
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN") 
    
    __IllegalContextMessage(:history_unadj, :initalize)

    tickers = [getsecurity(secid).symbol.ticker for secid in secids]
    history_unadj(tickers, datatype, frequency, 
                    startdate = startdate,
                    enddate = enddate,
                    securitytype = securitytype,
                    exchange = exchange,
                    country = country)
end

export history_unadj
=#


#=function getadjustments(tickers::Vector{String},
                            startdate::DateTime, 
                            enddate::DateTime, 
                            securitytype::String="EQ",
                            exchange::String="NSE",
                            country::String="IN")

    YRead.getadjustments(tickers, datatype, frequency,
                            startdate, enddate, 
                            securitytype = securitytype, 
                            exchange = exchange, country = country)    
end

function getadjustments(secids::Vector{Int},
                            startdate::DateTime, 
                            enddate::DateTime, 
                            securitytype::String="EQ",
                            exchange::String="NSE",
                            country::String="IN")
    
    YRead.getadjustments(tickers, datatype, frequency,
                            startdate, enddate, 
                            securitytype = securitytype, 
                            exchange = exchange, country = country)    
end

function getadjustments(securities::Vector{Security},
                            startdate::DateTime, 
                            enddate::DateTime, 
                            securitytype::String="EQ",
                            exchange::String="NSE",
                            country::String="IN")

    secids = [security.symbol.id for security in securities]
    getadjustments(secids, datatype, frequency,
                    startdate, enddate, 
                    securitytype = securitytype, 
                    exchange = exchange, country = country)    
end

function getadjustments(symbols::Vector{SecuritySymbol},
                            startdate::DateTime, 
                            enddate::DateTime, 
                            securitytype::String="EQ",
                            exchange::String="NSE",
                            country::String="IN")

    secids = [symbol.id for symbol in symbols]
    getadjustments(secids, datatype, frequency,
                    startdate, enddate, 
                    securitytype = securitytype, 
                    exchange = exchange, country = country)    
end=#
   
end #End of module
