using API
using Raftaar
using YRead
using Mongo

client = MongoClient()

YRead.configure(client)

# security
# SecuritySymbol
# Id
# Ticker


# Horizon based History

#=function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime())
=#

sArray = [getsecurity("CNX_BANK"), getsecurity("CNX_NIFTY")] 

setcurrentdatetime(DateTime("2013-01-01"))
println(history(sArray, "Close", :Day, 100))


#=function history(secids::Array{SecuritySymbol,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime()) 
=#

sArray = [getsecurity("CNX_BANK").symbol, getsecurity("CNX_NIFTY").symbol] 

setcurrentdatetime(DateTime("2014-01-01"))
println(history(sArray, "Close", :Day, 50))   

#=function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime()) 
=#

sArray = [getsecurity("CNX_BANK").symbol.id, getsecurity("CNX_NIFTY").symbol.id] 

setcurrentdatetime(DateTime("2014-01-01"))
println(history(sArray, "Close", :Day, 50))   


#=function history(symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime = getcurrentdatetime(),
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")
=#

sArray = ["CNX_BANK", "CNX_NIFTY"] 

setcurrentdatetime(DateTime("2012-01-01"))
println(history(sArray, "Close", :Day, 50))   


# Period based History

#=function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")=#

sArray = [getsecurity("CNX_BANK"), getsecurity("CNX_NIFTY")] 
println(history(sArray, "Close", :Day, 
            startdate = DateTime("2016-04-01"),
            enddate = DateTime("2016-09-01")))   


#=function history(symbols::Vector{SecuritySymbol},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")=#


sArray = [getsecurity("CNX_BANK").symbol, getsecurity("CNX_NIFTY").symbol] 
println(history(sArray, "Close", :Day, 
            startdate = DateTime("2016-04-01"),
            enddate = DateTime("2016-09-01")))   


#=function history(ids::Vector{Int},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")=#


sArray = [getsecurity("CNX_BANK").symbol.id, getsecurity("CNX_NIFTY").symbol.id] 
println(history(sArray, "Close", :Day, 
            startdate = DateTime("2016-04-01"),
            enddate = DateTime("2016-09-01")))   


#=function history(ticker::Vector{String},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")=#

sArray = ["CNX_BANK", "CNX_NIFTY"] 

println(history(sArray, "Close", :Day, 
            startdate = DateTime("2016-04-01"),
            enddate = DateTime("2016-09-01")))   











