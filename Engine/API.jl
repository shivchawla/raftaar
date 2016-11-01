# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#__precompile__(true)
#module API
#include("Raftaar.jl")



#Lean Functions to expose Raftar API without any need
#of initialzing algorithm object

include("../../Yojak/src/api.jl")

using Raftaar
using DataFrames


#Import list of functions to be overloaded
import Raftaar: getuniverse, log

const algorithm = Algorithm()
 

"""
Functions to expose trading environment API
""" 
function setresolution(resolution::Resolution)
    checkforparent(:setresolution, :initialize)
    setresolution!(algorithm.tradeenv, resolution)
end

function setstartdate(datetime::DateTime)    
    setstartdate!(algorithm.tradeenv, datetime)
end

function setenddate(datetime::DateTime)
    setenddate!(algorithm.tradeenv, datetime)
end

function setcurrentdatetime(datetime::DateTime)
    setcurrentdatetime!(algorithm.tradeenv, datetime) 
end

function getstartdate()
    algorithm.tradeenv.startdate
end

function getenddate()
    algorithm.tradeenv.enddate
end

function getcurrentdatetime()
    algorithm.tradeenv.currentdatetime
end


"""
Functions to expose Universe API
""" 
function adduniverse(ticker::String;
                        securitytype::String="EQ",
                        exchange::String="NSE")
    adduniverse!(algorithm.universe, ticker, 
                    securitytype = securitytype,
                    exchange = exchange)
end

function adduniverse(tickers::Vector{String};
                        securitytype::String="EQ",
                        exchange::String="NSE")
    
    for ticker in tickers
        adduniverse(tickers, securitytype = securitytype, exchange = exchange)
    end
end

function setuniverse(ticker::String;
                        securitytype::String="EQ",
                        exchange::String="NSE")
    
    #checkforparent(:setuniverse, :initialize)
   
    setuniverse!(algorithm.universe, [ticker],
                    securitytype = securitytype,
                    exchange = exchange)
end

function setuniverse(tickers::Vector{String};
                        securitytype::String="EQ",
                        exchange::String="NSE")
    
    #checkforparent(:setuniverse, :initialize)
   
    setuniverse!(algorithm.universe, tickers,
                    securitytype = securitytype,
                    exchange = exchange)
end


#=function adduniverse(ticker::String, securitytype::SecurityType = SecurityType(InValid))
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
    adduniverse!(algorithm.universe, ticker, securitytype)
end

function adduniverse(tickers::Vector{String}, securitytype::SecurityType = SecurityType(InValid))
    for ticker in tickers
        adduniverse(ticker, securitytype)
    end
end


function adduniverse(ticker::String, securitytype::SecurityType = SecurityType(InValid))
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
    adduniverse!(algorithm.universe, ticker, securitytype)
end

function adduniverse(tickers::Vector{String}, securitytype::SecurityType = SecurityType(InValid))
    for ticker in tickers
        adduniverse(ticker, securitytype)
    end
end

function setuniverse(ticker::String, securitytype::SecurityType = SecurityType(InValid))
    checkforparent(:setuniverse, :initialize)
   
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
    
    setuniverse1!(algorithm.universe, ticker, securitytype)
end

function setuniverse(tickers::Vector{String}, securitytype::SecurityType = SecurityType(InValid))
    checkforparent(:setuniverse, :initialize)
  
    if (securitytype == SecurityType(InValid))
        securitytype = algorithm.tradeenv.defaultsecuritytype
    end
      
    setuniverse2!(algorithm.universe, tickers, securitytype)
end=#

function getuniverse()  #return array of security symbol
    getuniverse(algorithm.universe)
end

function updatesecurity(security::Security, id::Int)

end

function cantrade(ticker::String)
    cantrade(symbol, algorithm.tradeenv.defaultsecuritytype, algorithm.tradeenv.datetime)
end 

function cantrade(symbol::SecuritySymbol)
    cantrade(symbol, algorithm.tradeenv.datetime)
end 

function cantrade(security::Security)
    cantrade(security, algorithm.tradeenv.datetime)
end 

"""
Functions to expose Account and Portfolio API
"""
function setcash(cash::Float64)
    checkforparent(:setcash, :initialize)
    setcash!(algorithm, cash)
end

function addcash(cash::Float64)
    addcash!(algorithm, cash)
end

function getposition(ticker::String)
    getposition(algorithm.account.portfolio, ticker)
end

function getposition(symbol::SecuritySymbol)
    getposition(algorithm.account.portfolio, symbol)
end

function getposition(security::Security)
    getposition(algorithm.account.portfolio, security)
end

function getportfolio()
    algorithm.account.portfolio
end

function getportfoliovalue()
    algorithm.account.netvalue
end

"""
Functions to expose brokerage API
""" 
function setcancelpolicy(cancelpolicy::CancelPolicy)
    checkforparent(:setcancelpolicy, :initialize)
    setcancelpolicy!(algorithm.brokerage, CancelPolicy(EOD))
end

function setcommission(commission::Commission)
    checkforparent(:setcommission, :initialize)
    setcommission!(algorithm.brokerage, commission)
end

function setslippage(slippage::Slippage)
    checkforparent(:setslippage, :initialize)
    setslippage!(algorithm.brokerage, slippage)
end

function setparticipationrate(participationrate::Float64)
    setparticipationrate!(algorithm.brokerage, participationrate)
end

function placeorder(security::Security, quantity::Int64)
    placeorder(security.symbol, quantity)
end 

function placeorder(symbol::SecuritySymbol, quantity::Int64)
    placeorder(Order(symbol, quantity))
end

function placeorder(order::Order)
    if !algorithm.tradeenv.livemode
        order.datetime = getcurrentdatetime()
    else 
        order.datetime = now()
    end
    placeorder!(algorithm.brokerage, order)  
end

function liquidate(symbol::String)
    setholdingshares(symbol, 0)  
end

function liquidateportfolio()
end

#Order function to set holdings to a specific level in pct/value/shares
function setholdingpct(symbol::String, target::Float64)
    #get current position
end

function setholdingvalue(symbol::String, target::Float64)
    #get current position
end

function setholdingshares(symbol::String, target::Int64)
    #get current hares
end

function hedgeportfolio()
end

function getopenorders()
    getopenorders(algorithm.brokerage)
end

function cancelallorders(symbol::SecuritySymbol)
    cancelallorders(algorithm.brokerage, symbol)
end

function cancelallorders()
    cancelallorders(algorithm.brokerage)    
end

"""
Functions to expose the logging API
""" 
function log(msg::String, msgtype::MessageType=MessageType(INFO))
    log!(algorithm.tradeenv, msg, msgtype)
end

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
   updateaccountforfills!(algorithm.account, updatependingorders!(algorithm.brokerage, algorithm.universe))
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

function updateuniverse(date::String)
    updateuniverseforid()
    updateuniverseforprices(date)
end

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
          security.symbol.id = id
        
        end  
    end
end


function getprices(date::DateTime)
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

#=export Algorithm, Universe, Security, SecuritySymbol,
       Commission, Slippage, Order, TradeBar

export Resolution, CancelPolicy, SecurityType, MessageType

for s in instances(Resolution)
    @eval export $(Symbol(s))
end

for s in instances(CancelPolicy)
    @eval export $(Symbol(s))
end

for s in instances(SecurityType)
    @eval export $(Symbol(s))
end

for s in instances(MessageType)
    @eval export $(Symbol(s))
end

export  setresolution,
        setstartdate,
        setenddate,
        setcurrentdatetime,
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
        setholdingpct,
        setholdingvalue,
        setholdingshares,
        hedgeportfolio,
        getopenorders,
        cancelallorders,
        _updatependingorders,
        _updateaccountforprice,
        _updateprices,
        _updateaccounttracker,
        _calculateperformance,
        log,
        track,
        createsymbol,
        updatesecurity;

end=#
