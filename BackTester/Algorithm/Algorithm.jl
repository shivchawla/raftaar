# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#=    DeployError = 1    #Error compiling algorithm at start
    InQueue = 2        #Waiting for a server
    Running = 3        #Running algorithm
    Stopped = 4        #Stopped algorithm or exited with runtime errors
    Liquidated =  5    #Liquidated algorithm
    Deleted = 6        #Algorithm has been deleted
    Completed = 7      #Algorithm completed running
    RuntimeError = 8   #Runtime Error Stoped Algorithm
    Invalid = 9		   #Error in the algorithm id (not used).
    LoggingIn  = 10    #The algorithm is logging into the brokerage
    Initializing = 11  #The algorithm is initializing
=#

const LogTracker = Dict{String, Dict{String, Vector{String}}}

function LogTracker(data::Dict{String, Any}) 
    return data
end

function serialize(logtracker::LogTracker)
    return logtracker
end

"""
Algorithm type
Encapsulates various entities that characterise an Algorithm
"""
mutable struct Algorithm
    name::String
	algorithmid::String
	status::AlgorithmStatus
	account::Account
	universe::Universe
    universeindex::String
	tradeenv::TradingEnvironment
	brokerage::BacktestBrokerage
    accounttracker::AccountTracker
    cashtracker::CashTracker
    performancetracker::PerformanceTracker
    benchmarktracker::PerformanceTracker
    transactiontracker::TransactionTracker
    tradebook::TradeBook
    ordertracker::OrderTracker
    variabletracker::VariableTracker
    state::AlgorithmState
end

"""
Algorithm empty constructor
"""
Algorithm() = Algorithm("","", Initializing,
                                Account(),
                                #Portfolio(),
                                Universe(),
                                "Nifty 50",
                                TradingEnvironment(),
                                BacktestBrokerage(),
                                AccountTracker(),
                                CashTracker(),
                                PerformanceTracker(),
                                PerformanceTracker(),
                                TransactionTracker(),
                                TradeBook(),
                                OrderTracker(),
                                VariableTracker(),
                                AlgorithmState())

"""
Algorithm deserialize constructor
"""
Algorithm(data::Dict{String,Any}) = Algorithm(data["name"],
                                        data["id"],
                                        eval(parse(data["status"])),
                                        haskey(data, "account") ? Account(data["account"]) : Account(),
                                        haskey(data, "universe") ? Universe(data["universe"]) : Universe(),
                                        haskey(data, "universeindex") ? data["universeindex"] : "Nifty 50",
                                        haskey(data, "tradeenv") ? TradingEnvironment(data["tradeenv"]) : TradingEnvironment(),
                                        haskey(data, "brokerage") ? BacktestBrokerage(data["brokerage"]) : BacktestBrokerage(),
                                        haskey(data, "accounttracker") ? AccountTracker(data["accounttracker"]) : AccountTracker(),
                                        haskey(data, "cashtracker") ? CashTracker(data["cashtracker"]) : CashTracker(),
                                        haskey(data, "performancetracker") ? PerformanceTracker(data["performancetracker"]) : PerformanceTracker(),
                                        haskey(data, "benchmarktracker") ? PerformanceTracker(data["benchmarktracker"]) : PerformanceTracker(),
                                        haskey(data, "transactiontracker") ?  TransactionTracker(data["transactiontracker"]) : TransactionTracker(),
                                        haskey(data, "tradebook") ?  TradeBook(data["tradebook"]) : TradeBook(),
                                        haskey(data, "ordertracker") ? OrderTracker(data["ordertracker"]) : OrderTracker(),
                                        haskey(data, "variabletracker") ? VariableTracker(data["variabletracker"]) : VariableTracker(),
                                        haskey(data, "state") ? AlgorithmState(data["state"]) : AlgorithmState() )

"""
Reset algorithm variable to default
"""
function resetAlgo(algorithm::Algorithm)
    algorithm.algorithmid = ""
    algorithm.name = ""
    algorithm.status = Initializing
    algorithm.account = Account()
    algorithm.universe = Universe()
    algorithm.universeindex = "Nifty 50"
    algorithm.tradeenv = TradingEnvironment()
    algorithm.brokerage = BacktestBrokerage()
    algorithm.accounttracker = AccountTracker() #To track evolution of account with time
    algorithm.cashtracker = CashTracker()
    algorithm.performancetracker = PerformanceTracker()
    algorithm.benchmarktracker = PerformanceTracker()
    algorithm.transactiontracker = TransactionTracker()
    algorithm.tradebook = TradeBook()
    algorithm.ordertracker = OrderTracker()
    algorithm.variabletracker = VariableTracker()
    algorithm.state = AlgorithmState()
end


function updateaccount_price!(algorithm::Algorithm)
    updateaccount_price!(algorithm.account, algorithm.universe.tradebars, DateTime(algorithm.tradeenv.currentdate))
    updateTradeBook!(algorithm.tradebook, algorithm.universe.tradebars)
    end

function updatependingorders_price!(algorithm::Algorithm)
    
    fills = updatependingorders!(algorithm.brokerage, algorithm.universe, algorithm.account)
    
    updateTransactionTracker!(algorithm.transactiontracker, fills)
    updateTradeBook!(algorithm.tradebook, fills)
    updateaccount_fills!(algorithm.account, fills)
    updateorders_cancelpolicy!(algorithm.brokerage)
end

function updatependingorders_splits!(algorithm::Algorithm)
    updatependingorders_splits!(algorithm.brokerage, algorithm.universe.adjustments)
end

function updatedatastores!(algorithm::Algorithm, tradebars::Dict{SecuritySymbol, TradeBar}, adjustments::Dict{SecuritySymbol, Adjustment})
    updateprices!(algorithm.universe, tradebars)
    updateadjustments!(algorithm.universe, adjustments)
end

function updateaccount_splits_dividends!(algorithm::Algorithm)
    updateaccount_splits_dividends!(algorithm.account, algorithm.universe.adjustments)
end

function outputperformance(algorithm::Algorithm)
    outputperformance(algorithm.tradeenv, algorithm.performancetracker, algorithm.benchmarktracker, algorithm.variabletracker)
end

"""
Function to track the account at each time step
"""
function updateaccounttracker!(algorithm::Algorithm)
    accountcopy = deepcopy(algorithm.account)
    algorithm.accounttracker[getcurrentdate(algorithm.tradeenv)] = accountcopy
end

"""
Function to track the cash inflow/outflow at each time step
"""
function updatecashtracker!(algorithm::Algorithm, cash::Float64)
    algorithm.cashtracker[getcurrentdate(algorithm.tradeenv)] = cash
end


"""
Function to track the performance at each time step
"""
function updateperformancetracker!(algorithm::Algorithm)
    date = getcurrentdate(algorithm.tradeenv)
    latestbenchmarkvalue = getbenchmarkvalue(algorithm.tradeenv, date)
    updatelatestperformance_benchmark(algorithm.benchmarktracker, latestbenchmarkvalue, date)
    updatelatestperformance_algorithm(algorithm.accounttracker, algorithm.cashtracker, algorithm.performancetracker, algorithm.benchmarktracker, date)
end

#precompile(updateperformancetracker!, (Algorithm,))

export updateperformancetracker!

"""
Function to set initial cash in the algorithm
"""
function setcash!(algorithm::Algorithm, cash::Float64)
    updatecashtracker!(algorithm, cash)
    setcash!(algorithm.account, cash)
end

"""
Function to add more cash to the algorithm
"""
function addcash!(algorithm::Algorithm, cash::Float64)
    updatecashtracker!(algorithm, cash)
    addcash!(algorithm.account, cash)
end

"""
Function to add new variable to variable tracker (at current algorithm time)
"""
function addvariable!(algorithm::Algorithm, name::String, value::Float64)
    addvariable!(algorithm.variabletracker, name, value, getcurrentdate(algorithm.tradeenv))
end

"""
Function to add new variable to variable tracker (at the defined time)
"""
function addvariable!(variabletracker::VariableTracker, name::String, value::Float64, date::Date)
    if (!haskey(variabletracker, date))
        variabletracker[date] = Dict{String,Any}()
    end

    variabletracker[date][name] = value

end

function updatestate(algorithm::Algorithm)
    algorithm.state.account = deepcopy(algorithm.account)
    #algorithm.state.portfolio = deepcopy(algorithm.portfolio)
    algorithm.state.performance = deepcopy(getlatestperformance(algorithm.performancetracker))
end
export updatestate

function outputbackteststatistics(algorithm::Algorithm)

    outputbackteststatistics_full(algorithm.accounttracker,
                        algorithm.performancetracker,
                        algorithm.benchmarktracker,
                        algorithm.variabletracker,
                        algorithm.cashtracker,
                        algorithm.transactiontracker,
                        algorithm.tradebook,
                        algorithm.ordertracker,
                        DateTime(getcurrentdate(algorithm.tradeenv)))

    #sort the keys in these trackers

    #what stastics calculations do we want?
    #1. Daily Returns and Net value
    #2. Statistics [Monthly window/Yearly window] -
                #based on return and portfolio
        #2a. Average Return
        #2b. Total Return
        #
end
export outputbackteststatistics

function outputbacktestlogs(algorithm::Algorithm)
    outputdict = Dict{String, Any}(
                    "outputtype" => "backtest",
                    "detail" => false,
                    "logs" => Logger.getlogbook())
    
    Logger.print(JSON.json(outputdict), realtime = false)
end
export outputbacktestlogs

function updatelogtracker(algorithm::Algorithm)
    for (date, dict) in Logger.getlogbook()
        if !haskey(algorithm.logtracker, date)
            algorithm.logtracker[date] = Dict{String, Vector{String}}()
        end
        for(et, logs) in dict
            if !haskey(algorithm.logtracker[date], et)
                algorithm.logtracker[date][et] = logs
            else
                push!(algorithm.logtracker[date][et], logs)
            end
        end
    end

    #algorithm.logtracker = Logger.getlogbook()
end

export updatelogtracker

# Additional functions for (de)serialization

function serialize(algorithm::Algorithm)
  return Dict{String, Any}("object"   => "algorithm",
                            "name"    => algorithm.name,
                            "id"      => algorithm.algorithmid,
                            "status"  => string(algorithm.status),
                            "account" => serialize(algorithm.account),
                            "universe" => serialize(algorithm.universe),
                            "universeindex" => algorithm.universeindex,
                            "tradeenv" => serialize(algorithm.tradeenv),
                            "brokerage" => serialize(algorithm.brokerage),
                            "accounttracker" => serialize(algorithm.accounttracker),
                            "cashtracker" => serialize(algorithm.cashtracker),
                            "performancetracker" => serialize(algorithm.performancetracker),
                            "benchmarktracker" => serialize(algorithm.benchmarktracker),
                            "transactiontracker" => serialize(algorithm.transactiontracker),
                            "tradebook" => serialize(algorithm.tradebook),
                            "ordertracker" => serialize(algorithm.ordertracker),
                            "variabletracker" => serialize(algorithm.variabletracker),
                            "state" => serialize(algorithm.state))
end

export serialize

==(algo1::Algorithm, algo2::Algorithm) = algo1.name == algo2.name &&
                                          algo1.algorithmid == algo2.algorithmid &&
                                          algo1.status == algo2.status &&
                                          algo1.account == algo2.account &&
                                          algo1.universe == algo2.universe &&
                                          algo1.universeindex == algo2.universeindex &&
                                          algo1.tradeenv == algo2.tradeenv &&
                                          algo1.brokerage == algo2.brokerage &&
                                          algo1.accounttracker == algo2.accounttracker &&
                                          algo1.cashtracker == algo2.cashtracker &&
                                          algo1.performancetracker == algo2.performancetracker &&
                                          algo1.benchmarktracker == algo2.benchmarktracker &&
                                          algo1.transactiontracker == algo2.transactiontracker &&
                                          algo1.tradebook == algo2.tradebook &&
                                          algo1.ordertracker == algo2.ordertracker &&
                                          algo1.variabletracker == algo2.variabletracker &&
                                          algo1.state == algo2.state

import Dates: Date
Date(s::String) = Date(map(x->parse(Int64, x), split(s, "-"))...)
