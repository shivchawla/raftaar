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
using Logger

import Logger: warn, info

#Import list of functions to be overloaded
import Raftaar: getuniverse, getopenorders


const algorithm = Raftaar.Algorithm()
 
function setlogmode(mode::Symbol, save::Bool = false)
    Logger.configure(print_mode = mode, save_mode = save, save_limit = 10) 
end

export setlogmode

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
        setcurrentdatetime,
        setbenchmark,
        getbenchmark,
        getstartdate,
        getenddate,
        getcurrentdatetime,
        adduniverse,
        setuniverse,
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
function setbenchmark(ticker::String)
    setbenchmark!(algorithm.tradeenv, securitysymbol(ticker))
    adduniverse(ticker)
end

function setbenchmark(symbol::SecuritySymbol)
    setbenchmark!(algorithm.tradeenv, symbol) 
    adduniverse(symbol.ticker)
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

function _updatependingorders()
   updateaccountforfills!(algorithm.account, algorithm.portfolio, updatependingorders!(algorithm.brokerage, algorithm.universe, algorithm.account))
end

export _updatependingorders

    
function _updateaccountforprice()
    updateaccountforprice!(algorithm.account, algorithm.portfolio, algorithm.universe.tradebars, algorithm.tradeenv.currentdatetime)
end

export _updateaccountforprice

function _updateprices(tradebars::Dict{SecuritySymbol, TradeBar})
    updateprices!(algorithm.universe, tradebars)
end 

export _updateprices

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
    outputperformance(algorithm.tradeenv, algorithm.performancetracker, algorithm.benchmarktracker, algorithm.variabletracker, Date(getcurrentdatetime()))
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
    ticker = getsymbol(id)
    
    if ticker == "NULL"  
        Logger.warn("Not a valid ticker: $(id)")
    end

    return SecuritySymbol(id, ticker)
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

function updatepricestores(date::DateTime, prices::DataFrame)
    
    tradebars = Dict{SecuritySymbol, TradeBar}()
    for security in getuniverse()
    
        close = prices[Symbol(security.symbol.ticker)][1]

        #check if price is DataArray NA
        tradebar =  isna(close) ? TradeBar() : TradeBar(date, close, close, close, close, 1000000)
        ss = security.symbol
        tradebars[ss] = tradebar
    end

  _updateprices(tradebars)
end

#precompile(updatepricestores, (DateTime, DataFrame))
export updatepricestores

end