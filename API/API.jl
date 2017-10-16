# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#Lean Functions to expose Raftar API without any need
#of initialzing algorithm object
__precompile__(true)
module API

using Raftaar
using DataFrames
using TimeSeries
using Logger
using WebSockets
using JSON
using LibBSON

#Import list of functions to be overloaded
import Raftaar: getuniverse, getopenorders

algorithm = Raftaar.Algorithm()

function setlogmode(style::Symbol, print::Symbol, save::Bool)
    Logger.configure(style_mode = style, print_mode = print, save_mode = save)
end

function setlogmode(style::Symbol, print::Symbol, save::Bool, client::WebSocket)
    Logger.configure(client, style_mode = style, print_mode = print, save_mode = save)
end
export setlogmode

include("TradingEnvAPI.jl")
include("HistoryAPI.jl")
include("AccountAPI.jl")
include("UniverseAPI.jl")
include("BrokerageAPI.jl")

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
   updateaccount_fills!(algorithm.account, updatependingorders!(algorithm.brokerage, algorithm.universe, algorithm.account, algorithm.transactiontracker))
   updateorders_cancelpolicy!(algorithm.brokerage)
end

export _updatependingorders_price

function _updatependingorders_splits()
    updatependingorders_splits!(algorithm.brokerage, algorithm.universe.adjustments)
end
export _updatependingorders_splits

function _updateaccount_price()
    updateaccount_price!(algorithm.account, algorithm.universe.tradebars, DateTime(algorithm.tradeenv.currentdate))
end

export _updateaccount_price

function _updatedatastores(tradebars::Dict{SecuritySymbol, TradeBar}, adjustments::Dict{SecuritySymbol, Adjustment})

    updateprices!(algorithm.universe, tradebars)
    updateadjustments!(algorithm.universe, adjustments)
end
export _updatedatastores

function _updateaccount_splits_dividends()
    updateaccount_splits_dividends!(algorithm.account, algorithm.universe.adjustments)
end
export _updateaccount_splits_dividends

function _updateaccounttracker()
    updateaccounttracker!(algorithm)
end
export _updateaccounttracker

# NOT IN USE
# NOT IN USE
function _calculateperformance()
    calculateperformance(algorithm.accounttracker, algorithm.cashtracker)
    Raftaar.resetAlgo(algorithm)
end
export _calculateperformance
# NOT IN USE
# NOT IN USE

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
    outputperformance(algorithm.tradeenv, algorithm.performancetracker, algorithm.benchmarktracker, algorithm.variabletracker, getcurrentdate())
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
    for security in getuniverse()

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

    for security in getuniverse()
        id = security.symbol.id
        push!(ids, id)
    end

    prices = history(ids, "Close", :Day, 1, enddate = date)
end

export fetchprices

function updatedatastores(date::Date, ohlcv::Dict{String, TimeArray}, adjustments)

    datetime = DateTime(date)

    tradebars = Dict{SecuritySymbol, TradeBar}()
    adjs = Dict{SecuritySymbol, Adjustment}()

    for security in getuniverse()
 
        openprices = ohlcv["Open"]
        highprices = ohlcv["High"]
        lowprices = ohlcv["Low"]
        closeprices = ohlcv["Close"]
        volumes = ohlcv["Volume"]

        opennames = colnames(openprices)
        highnames = colnames(highprices)
        lownames = colnames(lowprices)
        closenames = colnames(closeprices)
        volumenames = colnames(volumes)
        
        #added try to prevent error in case security is not present
        colname = security.symbol.ticker

        open = __getprices(opennames, openprices, colname)
        high = __getprices(highnames, highprices, colname)
        low = __getprices(lownames, lowprices, colname)
        close = __getprices(closenames, closeprices, colname)
        
        volume = __getvolume(volumenames, volumes, colname)
        
        #check if price is DataArray NA
        tradebar =  TradeBar(datetime, open, high, low, close, volume)

        ss = security.symbol
        tradebars[ss] = tradebar

        if haskey(adjustments, security.symbol.id)
            if haskey(adjustments[security.symbol.id], date)
                adj = adjustments[security.symbol.id][date]
                adjs[security.symbol] = Adjustment(adj[1], string(adj[3]), adj[2])
            end
        end

    end

    _updatedatastores(tradebars, adjs)
end

function __getprices(names, prices, colname)
    defaultprice = 0.0
    price = 0.0
    if colname in names
        price = values(prices[colname])[1]
        price = !isnan(price) ? price : defaultprice
    end

    return price
end

function __getvolume(names, volumes, colname)
    defaultvolume = 0
    volume = 0
    if colname in names
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
  s = JSON.json(Dict("outputtype" => "serializedData",
                     "algorithm" => Raftaar.serialize(algorithm)))
  Logger.print(string(s))
end

export _serializeData

"""
Function to load previously saved progress
"""
dataAvailable = false
function _deserializeData(s::String)

  temp = JSON.parse(s)
  global algorithm = Raftaar.Algorithm(temp)
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
    Raftaar.resetAlgo(algorithm)
    Logger.resetLog()
    global dataAvailable = false
    for (k,v) in _globaldatastores
        delete!(_globaldatastores, k)
    end
end

end
