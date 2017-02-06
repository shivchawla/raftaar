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

import Logger: info, error

#Import list of functions to be overloaded
import Raftaar: getuniverse, getopenorders

const algorithm = Raftaar.Algorithm()
 
function setlogmode(mode::Symbol, save::Bool = false)
    Logger.configure(print_mode = mode, save_mode = save, save_limit = 20) 
end
export setlogmode

info(message::String; datetime::DateTime = DateTime()) = 
                    Logger.info(message, :json, datetime = datetime)
export info

warn(message::String; datetime::DateTime = DateTime()) = 
                    Logger.warn(message, :json, datetime = datetime)

export warn

error(message::String; datetime::DateTime = DateTime()) = 
                    Logger.error(message, :json, datetime = datetime)

export error

include("TradingEnvAPI.jl")
include("HistoryAPI.jl")
include("AccountAPI.jl")
include("UniverseAPI.jl")
include("BrokerageAPI.jl")
#include("../Util/Run_Algo.jl")

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
        checkforparent,
        reset
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
   updateaccount_fills!(algorithm.account, algorithm.portfolio, updatependingorders!(algorithm.brokerage, algorithm.universe, algorithm.account))
   updateorders_cancelpolicy!(algorithm.brokerage)
end

export _updatependingorders_price

function _updatependingorders_splits()
    updatependingorders_splits!(algorithm.brokerage, algorithm.universe.adjustments)
end
export _updatependingorders_splits
    
function _updateaccount_price()
    updateaccount_price!(algorithm.account, algorithm.portfolio, algorithm.universe.tradebars, DateTime(algorithm.tradeenv.currentdate))
end

export _updateaccount_price

function _updatedatastores(tradebars::Dict{SecuritySymbol, TradeBar}, adjustments::Dict{SecuritySymbol, Adjustment})
    
    updateprices!(algorithm.universe, tradebars)
    updateadjustments!(algorithm.universe, adjustments)
end
export _updatedatastores

function _updateaccount_splits_dividends()
    updateaccount_splits_dividends!(algorithm.account, algorithm.portfolio, algorithm.universe.adjustments)
end
export _updateaccount_splits_dividends

function _updateaccounttracker()
    updateaccounttracker!(algorithm)
end
export _updateaccounttracker

function _calculateperformance()
    calculateperformance(algorithm.accounttracker, algorithm.cashtracker)
    Raftaar.reset(algorithm)
end

export _calculateperformance

function _updatedailyperformance()
    updateaccounttracker!(algorithm)
    updateperformancetracker!(algorithm)
end

export _updatedailyperformance

function _outputbackteststatistics()
    outputbackteststatistics(algorithm)
end 

export _outputbackteststatistics   

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

function updatedatastores(date::Date, prices::TimeArray, volumes::TimeArray, adjustments)
    
    datetime = DateTime(date)

    tradebars = Dict{SecuritySymbol, TradeBar}()
    adjs = Dict{SecuritySymbol, Adjustment}()

    for security in getuniverse()
        
        close = 0.0
        volume = 10000000

        close_names = colnames(prices)
        volume_names = colnames(volumes)
        #added try to prevent error in case security is not present
        #try 

            colname = security.symbol.ticker

            if colname in close_names
                close = values(prices[colname])[1]
                close = !isnan(close) ? close : -1.0
            end
            
            if colname in volume_names
                volume = values(volumes[colname])[1]
                volume = !isnan(volume) ? volume : 0
            end

            #check if price is DataArray NA
            tradebar =  TradeBar(datetime, close, close, close, close, volume)

            ss = security.symbol
            tradebars[ss] = tradebar

            if haskey(adjustments, security.symbol.id)
                if haskey(adjustments[security.symbol.id], date)
                    adj = adjustments[security.symbol.id][date]
                    adjs[security.symbol] = Adjustment(adj[1], string(adj[3]), adj[2])
                end
            end          

        #end
    end

    _updatedatastores(tradebars, adjs)
end

#precompile(updatepricestores, (DateTime, DataFrame))
export updatedatastores

end
