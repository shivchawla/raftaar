using Mongo 
using Yojak

import Yojak: history, getsecurity, getsecurityid, getsecurityids, getsymbol


"""
global definition of mongodb client
"""
const client = MongoClient()
const securitycollection = MongoCollection(client, "aimsquant", "security_test") 
const datacollection = MongoCollection(client , "aimsquant", "data_test")


function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::String="",                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")  

    history(securitycollection, datacollection,
            secids, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country) 
end

function history(secid::Int,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    String::String="",                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")

    history(securitycollection, datacollection,
            secid, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)                   
end


function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime=DateTime(),                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")  

    history(securitycollection, datacollection,
            secids, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country) 
end

function history(secids::Int,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime=DateTime(),                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 

    history(securitycollection, datacollection,
            secids, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)  
end

# Based on symbols

function history(symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::String="",                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")

    history(securitycollection, datacollection,
            symbols, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)   
end

function history(symbol::String,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::String="",                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 

     history(securitycollection, datacollection,
            symbol, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)  
end


function history(symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime=DateTime(),                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 

    history(securitycollection, datacollection,
            symbols, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)  
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
   getsecurity(securitycollection, secid)
end

function getsecurity(ticker::String; 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")

    getsecurity(securitycollection, ticker, 
                securitytype = securitytype,
                exchange = exchange,
                country = country)
end


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
