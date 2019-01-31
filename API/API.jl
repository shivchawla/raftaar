# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#Lean Functions to expose Raftar API without any need
#of initialzing algorithm object
__precompile__(true)
module API

using BackTester
using TimeSeries
using Logger
using YRead
using JSON
using Dates

#Import list of functions to be overloaded
import BackTester: getuniverse, getopenorders
import BackTester: Security, SecuritySymbol
import Base: getindex, convert

_currentparent = Symbol()

algorithm = BackTester.Algorithm()

function setlogmode(style::Symbol, print::Symbol, save::Bool)
    Logger.configure(style_mode = style, print_mode = print, save_mode = save)
end

# function setlogmode(style::Symbol, print::Symbol, save::Bool, client::WebSocket)
#     Logger.configure(client, style_mode = style, print_mode = print, save_mode = save)
# end
# export setlogmode

function setparent(parent::Symbol)
    if (parent == :ondata && !hasparent(:initialize)) || (parent == :initialize && !hasparent(:ondata)) || parent == :all
        global _currentparent = parent
    else
        Base.error("Can't set parent from the context")
        return
    end
end

function __IllegalContextMessage(func::Symbol, context::Symbol)
    if _currentparent == context
        Base.error("Can't call $func from the context of $context")
    end
end
export __IllegalContextMessage

include("TradingEnvAPI.jl")
#include("HistoryAPI.jl")
include("AccountAPI.jl")
include("UniverseAPI.jl")
include("BrokerageAPI.jl")
#include("UtilityAPI.jl")
#include("OptimizeAPI.jl")

export  setstartdate,
        setenddate,
        setresolution,
        setenddate,
        setcurrentdate,
        setbenchmark,
        getbenchmark,
        getstartdate,
        getenddate,
        getcurrentdate,
        adduniverse,
        getuniverse,
        cantrade,
        setcash,
        addcash,
        getposition,
        getportfolio,
        getportfoliovalue,
        setcancelpolicy,
        setcommission,
        setslippage,
        setparticipationrate,
        liquidate,
        placeorder,
        liquidateportfolio,
        setholdingpct,
        setholdingvalue,
        setholdingshares,
        hedgeportfolio,
        getopenorders,
        cancelallorders,
        checkforparent


"""
Function to set benchmark
"""
function setbenchmark(secid::Int)
    #removeuniverse(getbenchmark())
    setbenchmark!(algorithm.tradeenv, securitysymbol(secid))
    #adduniverse(secid)
end

function setbenchmark(ticker::String)
    #removeuniverse(getbenchmark())
    setbenchmark!(algorithm.tradeenv, securitysymbol(ticker))
    #adduniverse(ticker)
end

function setbenchmark(symbol::SecuritySymbol)
    #removeuniverse(getbenchmark())
    setbenchmark!(algorithm.tradeenv, symbol)
    #adduniverse(symbol.ticker)
end

export setbenchmark

"""
Functions to expose the tracking API
"""
function track(name::String, value::Float64)
    addvariable!(algorithm, name, value)
end

export track

"""
Functions to support the backtest logic
"""
function _updatestate()
    updatestate(algorithm)
end

export _updatestate

function _updatependingorders_price()
    updatependingorders_price!(algorithm)
end

export _updatependingorders_price

function _updatependingorders_splits()
    updatependingorders_splits!(algorithm)
end
export _updatependingorders_splits

function _updateaccount_price()
    updateaccount_price!(algorithm)
end

export _updateaccount_price

function _updatedatastores(tradebars::Dict{SecuritySymbol, TradeBar}, adjustments::Dict{SecuritySymbol, Adjustment})
    updatedatastores!(algorithm, tradebars, adjustments)
end
export _updatedatastores

function _updateaccount_splits_dividends()
    updateaccount_splits_dividends!(algorithm)
end
export _updateaccount_splits_dividends

function _updateaccounttracker()
    updateaccounttracker!(algorithm)
end
export _updateaccounttracker

function _updatedailyperformance()
    updateaccounttracker!(algorithm)
    updateperformancetracker!(algorithm)
end

export _updatedailyperformance

function _outputbackteststatistics()
    outputbackteststatistics(algorithm)
end

export _outputbackteststatistics

function _outputbacktestlogs()
    outputbacktestlogs(algorithm)
end

export _outputbacktestlogs

function _updatelogtracker()
    updatelogtracker(algorithm)
end

export _updatelogtracker

function _outputdailyperformance()
    outputperformance(algorithm)
end

export _outputdailyperformance

function _updateuniverse(date::String)
    updateuniverseforid()
    updateuniverseforprices(date)
end

export _updateuniverse

function securitysymbol(ticker::String)
    id = getsecurityid(ticker)

    if id == -1
        Logger.warn("Not a valid ticker: $(ticker)")
    end

    return SecuritySymbol(id, ticker)
end


function securitysymbol(id::Int)
    security = getsecurity(id)

    if security == Security()
        Logger.warn("Not a valid secid: $(id)")
    end

    return security.symbol
end

export securitysymbol

isvalid(ss::SecuritySymbol) = ss.ticker!="NULL" && ss.id!=0 && ss.id!=-1

function updateuniverseforids()

    #if dynamic universe
    for security in getuniverse(validprice=false)

        id = getsecurityid(security.symbol.ticker,
                      securitytype = security.securitytype,
                      exchange = security.exchange)
        if id == -1
          warn("Not a valid security")
          removeuniverse(security)
          continue

        else
          updatesecurity(security, id)
        end
    end
end

export updateuniverseforids

function fetchprices(date::DateTime)
    ids = Vector{Int}()

    for security in getuniverse(validprice=false)
        id = security.symbol.id
        push!(ids, id)
    end

    prices = history(ids, "Close", :Day, 1, enddate = date)
end

export fetchprices

function updatedatastores(datetime::DateTime, ohlcv::Dict{String, TimeArray}, adjustments)

    tradebars = Dict{SecuritySymbol, TradeBar}()
    adjs = Dict{SecuritySymbol, Adjustment}()

    for security in getuniverse(validprice=false)
 
        openprices = ohlcv["Open"]
        highprices = ohlcv["High"]
        lowprices = ohlcv["Low"]
        closeprices = ohlcv["Close"]
        volumes = ohlcv["Volume"]
 
        #added try to prevent error in case security is not present
        colname = security.symbol.ticker

        open = __getprices(openprices, Symbol(colname))
        high = __getprices(highprices, Symbol(colname))
        low = __getprices(lowprices, Symbol(colname))
        close = __getprices(closeprices, Symbol(colname))
        
        volume = __getvolume(volumes, Symbol(colname))
        
        #check if price is DataArray NA
        tradebar =  TradeBar(datetime, open, high, low, close, volume)

        ss = security.symbol
        tradebars[ss] = tradebar

        date = Date(datetime)
        if haskey(adjustments, security.symbol.id)
            if haskey(adjustments[security.symbol.id], date)
                adj = adjustments[security.symbol.id][date]
                adjs[security.symbol] = Adjustment(adj[1], string(adj[3]), adj[2])
            end
        end

    end

    _updatedatastores(tradebars, adjs)
end

function __getprices(prices, colname)
    defaultprice = 0.0
    price = 0.0
    if colname in colnames(prices)
        price = values(prices[colname])[1]
        price = !isnan(price) ? price : defaultprice
    end

    return price
end

function __getvolume(volumes, colname)
    defaultvolume = 0.0
    volume = 0.0
    if colname in colnames(volumes)
        volume = values(volumes[colname])[1]
        volume = !isnan(volume) ? volume : defaultvolume
    end
    return volume
end

#precompile(updatepricestores, (DateTime, DataFrame))
export updatedatastores

"""
Function to save progress
"""
function _serializeData()
    #Logs are saved in Logger
    #transfer them to alogorithm object for serialization
    _updatelogtracker() 
    
    s = JSON.json(Dict("outputtype" => "serializedData",
                     "algorithm" => BackTester.serialize(algorithm)))
    Logger.print(string(s), realtime=false)
end

export _serializeData

"""
Function to load previously saved progress
"""
dataAvailable = false
function _deserializeData(s::String)

  temp = JSON.parse(s)
  global algorithm = BackTester.Algorithm(temp)
  global dataAvailable = true
end

export _deserializeData

"""
Indicator for serialized data
"""
function wasDataFound()
  return dataAvailable
end

export wasDataFound

function reset()
    BackTester.resetAlgo(algorithm)
    Logger.resetLog()
    global dataAvailable = false
    YRead.reset()

    # reset parent
    global _currentparent = Symbol()

end

function convert(::Type{BackTester.Security}, security::YRead.Security)
    
    return BackTester.Security(security.symbol.id, security.symbol.ticker, security.name,
                              exchange = security.exchange,
                              country = security.exchange,
                              securitytype = security.securitytype)
end


end
