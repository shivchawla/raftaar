# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#Lean Functions to expose Raftar API without any need
#of initialzing algorithm object

using Raftaar
using DataFrames

import Logger: warn, info

#Import list of functions to be overloaded
import Raftaar: getuniverse

algorithm = Raftaar.Algorithm()
 
function setlogmode(mode::Symbol)
    Logger.configure(print_mode = mode) 
end

include("YojakAPI.jl")
include("TradingEnvAPI.jl")
include("AccountAPI.jl")
include("UniverseAPI.jl")
include("BrokerageAPI.jl")

"""
Functions to expose the tracking API
""" 
function track(name::String, value::Float64)
    addvariable!(algorithm, name, value)
end

"""
Functions to support the backtest logic
""" 
function _updatependingorders()
   updateaccountforfills!(algorithm.account, updatependingorders!(algorithm.brokerage, algorithm.universe, algorithm.account))
end
    
function _updateaccountforprice()
    updateaccountforprice!(algorithm.account, algorithm.universe.tradebars, algorithm.tradeenv.currentdatetime)
end

function _updateprices(tradebars::Dict{SecuritySymbol, Vector{TradeBar}})
    updateprices!(algorithm.universe, tradebars)
end 

function _updateaccounttracker()
    updateaccounttracker!(algorithm)
end

function _calculateperformance()
    calculateperformance(algorithm.accounttracker, algorithm.cashtracker)
    Raftaar.reset(algorithm)
end

function _updateperformance()
    updateperformance(algorithm.accounttracker, algorithm.cashtracker, algorithm.performancetracker, Date(getcurrentdatetime()))
end

function _outputperformance()
    outputperformance(algorithm.tradeenv, algorithm.performancetracker, Date(getcurrentdatetime()))
end

function _updateuniverse(date::String)
    updateuniverseforid()
    updateuniverseforprices(date)
end


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

function fetchprices(date::DateTime)
    ids = Vector{Int}()

    for security in getuniverse()
        id = security.symbol.id  
        push!(ids, id)
    end

    prices = history(ids, "Close", :A, 1, enddate = date)
end

function updatepricestores(date::DateTime, prices::DataFrame)
    
    tradebars = Dict{SecuritySymbol, Vector{TradeBar}}()
    for security in getuniverse()
    
        close = prices[Symbol(security.symbol.ticker)][1]

        tradebar = TradeBar(date, close, close, close, close, 1000000)
      
        ss = security.symbol
        tradebars[ss] = Vector{TradeBar}()
        push!(tradebars[ss], tradebar) 
    end

  _updateprices(tradebars)
end
