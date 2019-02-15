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
mutable struct TradingEnvironment
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
  stopLoss::Float64
  profitTarget::Float64

  #calendar::TradingCalendar
  #WHAT IS A TRADING CALENDAR
end

"""
Empty constructor for the trading environment
"""
TradingEnvironment() = TradingEnvironment(
                          Date(1), Date(1), Date(1), false,
                          SecuritySymbol(), Resolution_Day, Rebalance_Daily, IP_AllIn, true,
                          Equity, "IN", Dict{Date, Float64}(), 0.05, 0.05)

TradingEnvironment(data::Dict{String, Any}) = TradingEnvironment(Date(data["startdate"]),
                                                          Date(data["enddate"]),
                                                          Date(data["currentdate"]),
                                                          data["livemode"],
                                                          SecuritySymbol(data["benchmark"]["id"], data["benchmark"]["ticker"]),
                                                          eval(Meta.parse(data["resolution"])),
                                                          eval(Meta.parse(data["rebalance"])),
                                                          eval(Meta.parse(data["investmentplan"])),
                                                          data["fullrun"],
                                                          eval(Meta.parse(data["defaultsecuritytype"])),
                                                          data["defaultmarket"],
                                                          Dict(data["benchmarkvalues"]),
                                                          get(data, "stopLoss", 0.05),
                                                          get(data, "profitTarget", 0.05))


"""
Function to set time resolution of the backtest
"""
function setresolution!(tradeenv::TradingEnvironment, resolution::Resolution)
  tradeenv.resolution = resolution
end

function setresolution!(tradeenv::TradingEnvironment, resolution::String)
  tradeenv.resolution = eval(Meta.parse("Resolution_"*resolution))
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
    tradeenv.investmentplan = eval(Meta.parse("IP_"*plan))
end

function setrebalance!(tradeenv::TradingEnvironment, rebalance::String)
    tradeenv.rebalance = eval(Meta.parse("Rebalance_"*rebalance))
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

function setProfitTarget!(tradeenv::TradingEnvironment, profitTarget::Float64 = 0.05)
  println("Tradenv profit target: $(profitTarget)")
  tradeenv.profitTarget = profitTarget
end

function setStopLoss!(tradeenv::TradingEnvironment, stopLoss::Float64 = 0.05)
  println("Tradenv stopLoss: $(stopLoss)")
  tradeenv.stopLoss = stopLoss
end

export setinvestmentplan!, setrebalance!, setbenchmarkvalues!, setProfitTarget!, setStopLoss!


"""
Function to get current date time of the algorithm
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

# function getStopLoss(tradeenv::TradingEnvironment)
#   return tradeenv.stopLoss
# end

# function getProfitTarget(tradeenv::TradingEnvironment)
#   return tradeenv.profitTarget
# end


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
function outputperformance(tradeenv::TradingEnvironment, performancetracker::PerformanceTracker, benchmarktracker::PerformanceTracker, variabletracker::VariableTracker)
    outputperformanceJSON(performancetracker, benchmarktracker, variabletracker, getcurrentdate(tradeenv))
end

"""
Function to find the parent function of a the called function
helps in limiting the use of API functions
"""
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
      str = str*string(reqparents[j])*"()" * (j<nparents ? ", " : "");
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
                            "benchmarkvalues"     => tradeenv.benchmarkvalues,
                            "stopLoss" => tradeenv.stopLoss,
                            "profitTarget" => tradeenv.profitTarget)
end

==(te1::TradingEnvironment, te2::TradingEnvironment) =  te1.startdate == te2.startdate &&
                                                          te1.enddate == te2.enddate &&
                                                          te1.currentdate == te2.currentdate &&
                                                          te1.livemode == te2.livemode &&
                                                          te1.benchmark == te2.benchmark &&
                                                          te1.resolution == te2.resolution &&
                                                          te1.rebalance == te2.rebalance &&
                                                          te1.investmentplan == te2.investmentplan &&
                                                          te1.fullrun == te2.fullrun &&
                                                          te1.defaultsecuritytype == te2.defaultsecuritytype &&
                                                          te1.defaultmarket == te2.defaultmarket &&
                                                          te1.benchmarkvalues == te2.benchmarkvalues &&
                                                          te1.stopLoss == te2.stopLoss &&
                                                          te1.profitTarget == te2.profitTarget
