using Mongo 
using Yojak

import Yojak: history, getsecurity, getsecurityid, getsecurityids, getsymbol
import Base: getindex

"""
global definition of mongodb client
"""
const client = MongoClient()
const securitycollection = MongoCollection(client, "aimsquant", "security_test") 
const datacollection = MongoCollection(client , "aimsquant", "data_test")

function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::String="")#DateTime = getcurrentdatetime())
    ids = Vector{Int}(length(securities))

    for i = 1:length(ids)
        ids[i] = securities[i].symbol.id    
    end

    #=if enddate > getcurrentdatetime()
        Logger.warn("Cannot access data from future")
        return
    end=#

    history(ids, datatype, frequency, horizon, enddate = enddate)

end

#=function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime()) 

    history(securitycollection, datacollection,
            secids, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country) 
end=#


function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::String="") 
   
    if frequency!=:Day
        Logger.info("""Only ":Day" frequency supported in history()""")
        exit()
    end

    if enddate == ""
        checkforparent(:history, :ondata)
        enddate = string(getcurrentdatetime())
     elseif hasparent(:ondata) &&  enddate != ""
        Logger.warn("history() can not be called with enddate argument")
        exit()
    end

    df = history(securitycollection, datacollection, secids, datatype, frequency,
            horizon, enddate)

    return sort(df, cols = :Date, rev=true)

end


function history(secid::Int,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::String="")

    #=if enddate == ""
        enddate = getcurrentdatetime()
    else 
        enddate = DateTime(enddate)
    end=#
    
    history([secid], datatype, frequency,
            horizon, enddate = enddate)
end


# Based on symbols

#=function history(symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime=getcurrentdatetime(),                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 

    history(securitycollection, datacollection,
            symbols, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)  
end=#



function history(symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::String="",                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")
    
    if frequency!=:Day
        Logger.info("""Only ":Day" frequency supported in history()""")
        exit()
    end

    if enddate == ""
        checkforparent(:history, :ondata)
        enddate = string(getcurrentdatetime())
    elseif hasparent(:ondata) &&  enddate != ""
        Logger.warn("history() can not be called with enddate argument")
        exit()
    end

    df = history(securitycollection, datacollection, symbols, datatype, frequency,
            horizon, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country) 

    return sort(df, cols = :Date, rev=true)
end

#=function history(symbol::String,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime=getcurrentdatetime(),                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 

    history([symbol], datatype, frequency,
            horizon, enddate = enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country)  
end=#



function history(symbol::String,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::String="",                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 

    #=if enddate == ""
        enddate = getcurrentdatetime()
    else 
        enddate = DateTime(enddate)
    end=#
   
    history([symbol], datatype, frequency,
            horizon, enddate = enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country)  
end

function getsecurityids(tickers::Array{String,1}; 
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
end

function getsecurity(secid::Int)
   convert(Raftaar.Security, getsecurity(securitycollection, secid))
end

function convert(::Type{Raftaar.Security}, security::Yojak.Security)
    return Security(security.symbol.id, security.symbol.ticker, security.name,
                      exchange = security.exchange,
                      country = security.exchange,
                      securitytype = security.securitytype)
end


function getsecurity(ticker::String; 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")

    convert(Raftaar.Security, getsecurity(securitycollection, ticker, 
                securitytype = securitytype,
                exchange = exchange,
                country = country))
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
