# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Security/Security.jl")
#include("../Output/Logger.jl")
#include("../Performance/Performance.jl")

"""
Trading Environment for the algorithm
Encapsulates date range, mode, benchmak etc.
"""
type TradingEnvironment
  startdate::Date
  enddate::Date
  currentdate::Date
  livemode::Bool
  benchmark::SecuritySymbol
  resolution::Resolution
  rebalance::Rebalance
  investmentplan::InvestmentPlan
  fullrun::Bool
  defaultsecuritytype::SecurityType
  defaultmarket::String
  benchmarkvalues::Dict{String, Float64}
  #calendar::TradingCalendar
  #WHAT IS A TRADING CALENDAR
end

"""
Empty constructor for the trading environment
"""
TradingEnvironment() = TradingEnvironment(
                          Date(), Date(), Date(), false,
                          SecuritySymbol(), Resolution(Resolution_Day), Rebalance(Rebalance_Daily), InvestmentPlan(IP_AllIn), true,
                          SecurityType(Equity), "IN", Dict{Date, Float64}())

TradingEnvironment(data::BSONObject) = TradingEnvironment(data["startdate"],
                                                          data["enddate"],
                                                          data["currentdate"],
                                                          data["livemode"],
                                                          SecuritySymbol(data["benchmark"]["id"], data["benchmark"]["ticker"]),
                                                          eval(parse(data["resolution"])),
                                                          eval(parse(data["rebalance"])),
                                                          eval(parse(data["investmentplan"])),
                                                          data["fullrun"],
                                                          eval(parse(data["defaultsecuritytype"])),
                                                          data["defaultmarket"],
                                                          Dict(data["benchmarkvalues"]))

"""
Function to set time resolution of the backtest
"""
function setresolution!(tradeenv::TradingEnvironment, resolution::Resolution)
  tradeenv.resolution = resolution
end

function setresolution!(tradeenv::TradingEnvironment, resolution::String)
  tradeenv.resolution = eval(parse("Resolution_"*resolution))
end

"""
Fuction to set the start date of the backtest
"""
function setstartdate!(tradeenv::TradingEnvironment, date::Date)
  tradeenv.startdate = date
end

"""
Function to set the end date of the backtest
"""
function setenddate!(tradeenv::TradingEnvironment, date::Date)
  tradeenv.enddate = date
end

"""
Function to set the benchmark of the algorithm
"""
function setbenchmark!(tradeenv::TradingEnvironment, symbol::SecuritySymbol)
  tradeenv.benchmark = symbol
end

"""
function to set the current algorithm time (mainly used for backtest)
"""
function setcurrentdate!(tradeenv::TradingEnvironment, date::Date)
  if !tradeenv.livemode
    tradeenv.currentdate = date
  end
end

function setinvestmentplan!(tradeenv::TradingEnvironment, plan::String)
    tradeenv.investmentplan = eval(parse("IP_"*plan))
end

function setrebalance!(tradeenv::TradingEnvironment, rebalance::String)
    tradeenv.rebalance = eval(parse("Rebalance_"*rebalance))
end

function setinvestmentplan!(tradeenv::TradingEnvironment, plan::InvestmentPlan)
    tradeenv.investmentplan = plan
end

function setrebalance!(tradeenv::TradingEnvironment, rebalance::Rebalance)
   tradeenv.rebalance =  rebalance
end

function setbenchmarkvalues!(tradeenv::TradingEnvironment, prices::Dict{String, Float64})
  tradeenv.benchmarkvalues = prices
end

export setinvestmentplan!, setrebalance!, setbenchmarkvalues!


"""
Function to get current date time of the algorithm
"""
function getcurrentdate(tradeenv::TradingEnvironment)
  tradeenv.currentdate
end

"""
Function to get current date of the algorithm
"""
function getcurrentdate(tradeenv::TradingEnvironment)
  tradeenv.currentdate
end

function getbenchmark(tradeenv::TradingEnvironment)
  return tradeenv.benchmark
end

function getinvestmentplan(tradeenv::TradingEnvironment)
  return tradeenv.investmentplan
end

function getrebalancefrequency(tradeenv::TradingEnvironment)
  return tradeenv.rebalance
end

function getbenchmarkvalue(tradeenv::TradingEnvironment, date::Date)
    dstr = string(date)
    return haskey(tradeenv.benchmarkvalues, dstr)  ? tradeenv.benchmarkvalues[dstr] :  0.0
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
function outputperformance(tradeenv::TradingEnvironment, performancetracker::PerformanceTracker, benchmarktracker::PerformanceTracker, variabletracker::VariableTracker, date::Date = Date())
    outputperformanceJSON(performancetracker, benchmarktracker, variabletracker, date)
end

export outputperformance

"""
Function to find the parent function of a the called function
helps in limiting the use of API functions
"""
#=function checkforparent(func::Symbol, reqparent::Symbol)
    frames = Base.stacktrace()
    len = length(frames)

    for i in 1:len
        parent = frames[i].func
        if (parent != reqparent) && i==len
            Logger.error(string(func)*"() can only be called within the context of "*string(reqparent)*"()")
            exit(0)
        elseif parent == reqparent
            return true
        end
    end
end

function checkforparent(reqparent::Symbol)

    frames = Base.stacktrace()
    func = frames[2].func
    len = length(frames)

    parenttree = Vector{Symbol}(len - 2)

    for i = 1:length(parenttree)
      parenttree[i] = frames[i+2].func
    end

    idx = findfirst(parenttree, reqparent)
    if idx == 0
        Logger.error(string(func)*"() can only be called from the context of "*string(reqparent)*"()")
        exit(0)
    end

    return true
end=#

function checkforparent(reqparents::Vector{Symbol})

    return true

    frames = Base.stacktrace()
    func = frames[2].func

    len = length(frames)
    parenttree = Vector{Symbol}(len - 2)

    for i = 1:length(parenttree)
      parenttree[i] = Symbol(strip(string(frames[i+2].func),';'))
    end

    nparents = length(reqparents)

    str="["
    for j = 1:nparents
      str = str*string(reqparents[j])*"()" * (j<nparents ? ", ":"");
      idx = findfirst(parenttree, reqparents[j])

      if idx > 0
        break
      end

      if j == nparents && idx == 0
        Logger.error(string(func)*"() can only be called from the context of "*str*"]")
        exit(0)
      end
    end

    return true
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

function serialize(tradeenv::TradingEnvironment)
  return Dict{String, Any}("startdate"           => tradeenv.startdate,
                            "enddate"             => tradeenv.enddate,
                            "currentdate"         => tradeenv.currentdate,
                            "livemode"            => tradeenv.livemode,
                            "benchmark"           => Dict("id"     => tradeenv.benchmark.id,
                                                          "ticker" => tradeenv.benchmark.ticker),
                            "resolution"          => string(tradeenv.resolution),
                            "rebalance"           => string(tradeenv.rebalance),
                            "investmentplan"      => string(tradeenv.investmentplan),
                            "fullrun"             => tradeenv.fullrun,
                            "defaultsecuritytype" => string(tradeenv.defaultsecuritytype),
                            "defaultmarket"       => tradeenv.defaultmarket,
                            "benchmarkvalues"     => tradeenv.benchmarkvalues)
end
