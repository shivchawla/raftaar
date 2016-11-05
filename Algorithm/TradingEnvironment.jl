# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("../Security/Security.jl")
#include("../Output/Logger.jl")
include("../Output/outputJSON.jl")
include("../Performance/Performance.jl")

"""
Trading Environment for the algorithm
Encapsulates date range, mode, benchmak etc. 
"""
type TradingEnvironment
  startdate::DateTime
  enddate::DateTime
  currentdatetime::DateTime
  livemode::Bool
  benchmark::SecuritySymbol
  resolution::Resolution
  fullrun::Bool
  defaultsecuritytype::SecurityType
  defaultmarket::String

  #calendar::TradingCalendar
  #WHAT IS A TRADING CALENDAR
end

"""
Empty constructor for the trading environment
"""
TradingEnvironment() = TradingEnvironment(
                          DateTime(), DateTime(), DateTime(), false, 
                          SecuritySymbol(), Resolution(Daily), true,
                          SecurityType(Equity), "IN")

"""
Function to set time resolution of the backtest
"""
function setresolution!(tradeenv::TradingEnvironment, resolution::Resolution)
  tradeenv.resolution = resolution
end

"""
Fuction to set the start date of the backtest
"""
function setstartdate!(tradeenv::TradingEnvironment, datetime::DateTime)
  tradeenv.startdate = datetime
end

"""
Function to set the end date of the backtest  
"""
function setenddate!(tradeenv::TradingEnvironment, datetime::DateTime)
  tradeenv.enddate = datetime
end

"""
Function to set the benchmark of the algorithm
"""
function setbenchmark!(tradeenv::TradingEnvironment, symbol::String)
  benchmarksymbol = createsymbol(symbol, tradeenv.defaultsecuritytype)
  tradeenv.benchmark = benchmarksymbol
end

"""
function to set the current algorithm time (mainly used for backtest)
"""
function setcurrentdatetime!(tradeenv::TradingEnvironment, datetime::DateTime)
  if !tradeenv.livemode 
    tradeenv.currentdatetime = datetime
  end 
end

"""
Function to get current date time of the algorithm
"""
function getcurrentdatetime(tradeenv::TradingEnvironment)
  tradeenv.currentdatetime
end

#="""
Function to log values or string from the algorithms
"""
function log!(tradeenv::TradingEnvironment, msg::String, msgType::MessageType)
    dt = getcurrentdatetime(tradeenv)
    
    logJSON!(tradeenv.logger, dt, msg, msgType)
    #log!(tradeenv.logger, dt, msg, msgType)
end=#

using Logger

import Logger: warn, info

"""
Function to output performance in a specified format
"""
function outputperformance(tradeenv::TradingEnvironment, performancetracker::PerformanceTracker, date::Date = Date())
    outputperformanceJSON(performancetracker, date)
end

export outputperformance

"""
Function to find the parent function of a the called function
helps in limiting the use of API functions
"""
function checkforparent(func::Symbol, reqparent::Symbol)
    frames = Base.stacktrace()
    len = length(frames)

    for i in 1:len 
        parent = frames[i].func
        if (parent != reqparent) && i==len
            Logger.warn(string(func)*"() can only be called within the context of "*string(reqparent)*"()")
            return
        elseif parent == reqparent
            break
        end
    end
end
export checkforparent

function hasparent(reqparent::Symbol)
    frames = Base.stacktrace()
    len = length(frames)

    for i in 1:len 
        parent = frames[i].func
        if parent == reqparent
            return true
        end
    end

    return false
end
export hasparent
