
using YRead

import YRead: history, getsecurity, getsecurityid, getsecurityids, getsymbol
import Base: getindex, convert


function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime())
    checkforparent([:ondata])
    ids = Vector{Int}(length(securities))

    for i = 1:length(ids)
        ids[i] = securities[i].symbol.id    
    end
    
    history(ids, datatype, frequency, horizon, enddate = enddate)

end

function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime()) 
    if frequency!=:Day
        Logger.info("""Only ":Day" frequency supported in history()""")
        exit()
    end

    checkforparent([:ondata, :_init])

    if enddate == DateTime()
        enddate = getcurrentdatetime()
     elseif !checkforparent([:_init])
        Logger.error("history() can not be called with enddate argument")
        exit()
    end

    df = YRead.history(secids, datatype, frequency,
            horizon, enddate)

    return sort(df, cols = :Date, rev=true)

end

# Based on symbols
function history(symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime = getcurrentdatetime(),
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")
    
    if frequency!=:Day
        Logger.info("""Only ":Day" frequency supported in history()""")
        exit(0)
    end

    checkforparent([:ondata, :_init])

    if enddate == DateTime()       
        enddate = getcurrentdatetime()
    elseif !checkforparent([:_init])
        Logger.warn("history() can not be called with enddate argument")
        exit(0)
    end
    
    df = YRead.history(symbols, datatype, frequency,
            horizon, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country) 

    return sort(df, cols = :Date, rev=true)
end

function history(symbols::Vector{String},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    df = YRead.history(symbols, datatype, frequency,
            startdate, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country) 

    return sort(df, cols = :Date, rev=true) 
end

function history(symbols::Vector{SecuritySymbol},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    tickers = Vector{String}()
    for sym in symbols
        push!(tickers, sym.ticker)
    end

    history(tickers, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype  =securitytype,
                exchange = exchange,
                country = country)
    
end

export history

#=function getsecurityids(tickers::Array{String,1}; 
                        securitytype::String="EQ", 
                        exchange::String="NSE",
                        country::String="IN")
    
    getsecurityids(securitycollection, tickers, 
                        securitytype = securitytype,
                        exchange = exchange,
                        country = country)

end

"""
Get security id for a symbol id (and exchange and security type)
"""
function getsecurityid(ticker::String; 
                        securitytype::String="EQ", 
                        exchange::String="NSE",
                        country::String="IN")

    getsecurityid(securitycollection, ticker,
                    securitytype = securitytype,
                    exchange = exchange,
                    country = country)
end

function getsymbol(id::Int)
    return getsymbol(securitycollection, id)
end=#


function getsecurity(secid::Int)
   convert(Raftaar.Security, YRead.getsecurity(secid))
end

function convert(::Type{Raftaar.Security}, security::YRead.Security)
    
    return Raftaar.Security(security.symbol.id, security.symbol.ticker, security.name,
                      exchange = security.exchange,
                      country = security.exchange,
                      securitytype = security.securitytype)
end


function getsecurity(ticker::String; 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")

    sec =  YRead.getsecurity(ticker, 
                        securitytype, 
                        exchange, 
                        country)
    convert(Raftaar.Security, sec)
end

# Overriding getindex for history dataframes
getindex(dataframe::DataFrame, security::Security) = getindex(dataframe, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, symbol::SecuritySymbol) = getindex(dataframe, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, ticker::String) = getindex(dataframe, Symbol(ticker))

getindex(dataframe::DataFrame, col_inds::Colon, security::Security) = getindex(dataframe, col_inds, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, col_inds::Colon, symbol::SecuritySymbol) = getindex(dataframe, col_inds, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, col_inds::Colon, ticker::String) = getindex(dataframe, col_inds, Symbol(ticker))

getindex(dataframe::DataFrame, col_ind::Int64, security::Security) = getindex(dataframe, col_ind, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, col_ind::Int64, symbol::SecuritySymbol) = getindex(dataframe, col_ind, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, col_ind::Int64, ticker::String) = getindex(dataframe, col_ind, Symbol(ticker))

getindex(dataframe::DataFrame, col_inds::UnitRange{Int64}, security::Security) = getindex(dataframe, col_ind, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, col_inds::UnitRange{Int64}, symbol::SecuritySymbol) = getindex(dataframe, col_ind, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, col_inds::UnitRange{Int64}, ticker::String) = getindex(dataframe, col_ind, Symbol(ticker))

#=function history(symbol::String,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime=DateTime(),                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")

 history(securitycollection, datacollection,
            symbol, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)  
end=#
