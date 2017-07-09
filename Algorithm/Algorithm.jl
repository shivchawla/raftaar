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

"""
Algorithm type
Encapsulates various entities that characterise an Algorithm
"""
type Algorithm
    name::String
	algorithmid::String
	status::AlgorithmStatus
	account::Account
    portfolio::Portfolio
	universe::Universe
	tradeenv::TradingEnvironment
	brokerage::BacktestBrokerage
    accounttracker::AccountTracker
    cashtracker::CashTracker
    performancetracker::PerformanceTracker
    benchmarktracker::PerformanceTracker
    transactiontracker::TransactionTracker
    ordertracker::OrderTracker
    variabletracker::VariableTracker
    state::AlgorithmState
end

"""
Algorithm empty constructor
"""
Algorithm() = Algorithm("","", AlgorithmStatus(Initializing),
                                            Account(),
                                            Portfolio(),
                                            Universe(),
                                            TradingEnvironment(),
                                            BacktestBrokerage(),
                                            AccountTracker(),
                                            CashTracker(),
                                            PerformanceTracker(),
                                            PerformanceTracker(),
                                            TransactionTracker(),
                                            OrderTracker(),
                                            VariableTracker(),
                                            AlgorithmState())

"""
Algorithm deserialize constructor
"""
Algorithm(data::BSONObject) = Algorithm(data["name"],
                                        data["id"],
                                        eval(parse(data["status"])),
                                        Account(data["account"]),
                                        Portfolio(data["portfolio"]),
                                        Universe(data["universe"]),
                                        TradingEnvironment(data["tradeenv"]),
                                        BacktestBrokerage(data["brokerage"]),
                                        AccountTracker(data["accounttracker"]),
                                        CashTracker(data["cashtracker"]),
                                        PerformanceTracker(data["performancetracker"]),
                                        PerformanceTracker(data["benchmarktracker"]),
                                        TransactionTracker(data["transactiontracker"]),
                                        OrderTracker(data["ordertracker"]),
                                        VariableTracker(data["variabletracker"]),
                                        AlgorithmState(data["state"]))

"""
Reset algorithm variable to default
"""
function resetAlgo(algorithm::Algorithm)
    println("Resetting Algo")
    algorithm.algorithmid = ""
    algorithm.name = ""
    algorithm.status = AlgorithmStatus(Initializing)
    algorithm.account = Account()
    algorithm.portfolio = Portfolio()
    algorithm.universe = Universe()
    algorithm.tradeenv = TradingEnvironment()
    algorithm.brokerage = BacktestBrokerage()
    algorithm.accounttracker = AccountTracker() #To track evolution of account with time
    algorithm.cashtracker = CashTracker()
    algorithm.performancetracker = PerformanceTracker()
    algorithm.benchmarktracker = PerformanceTracker()
    algorithm.transactiontracker = TransactionTracker()
    algorithm.ordertracker = OrderTracker()
    algorithm.variabletracker = VariableTracker()
    algorithm.state = AlgorithmState()
    #return
end

"""
Function to track the orders at each time step
"""
function updateordertracker!(algorithm::Algorithm, order::Order)
    currentdate = getcurrentdate(algorithm.tradeenv)
    if haskey(algorithm.ordertracker, currentdate)
        push!(algorithm.ordertracker[currentdate], order)
    else
        algorithm.ordertracker[currentdate] = [order]
    end
end

"""
Function to track the transactions at each time step (single transaction)
"""
function updatetransactiontracker!(algorithm::Algorithm, fill::OrderFill)
    currentdate = getcurrentdate(algorithm.tradeenv)
    tracker = algorithm.transactiontracker
    if haskey(tracker, currentdate)
        push!(tracker[currentdate], fill)
    else
        tracker[currentdate] = [fill]
    end
end


"""
Function to track the transactions at each time step
"""
function updatetransactiontracker!(algorithm::Algorithm, fills::Vector{OrderFill})
    currentdate = getcurrentdate(algorithm.tradeenv)
    tracker = algorithm.transactiontracker
    if haskey(tracker, currentdate)
        append!(tracker[currentdate], fills)
    else
        tracker[currentdate] = fills
    end
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
    setcash!(algorithm.account, algorithm.portfolio, cash)
end

"""
Function to add more cash to the algorithm
"""
function addcash!(algorithm::Algorithm, cash::Float64)
    updatecashtracker!(algorithm, cash)
    addcash!(algorithm.account, algorithm.portfolio, cash)
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
    algorithm.state.portfolio = deepcopy(algorithm.portfolio)
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
                        algorithm.ordertracker)
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

# Additional functions for (de)serialization

function serialize(algorithm::Algorithm)
  return Dict{String, Any}("object"   => "algorithm",
                            "name"    => algorithm.name,
                            "id"      => algorithm.algorithmid,
                            "status"  => string(algorithm.status),
                            "account" => serialize(algorithm.account),
                            "universe" => serialize(algorithm.universe),
                            "portfolio" => serialize(algorithm.portfolio),
                            "tradeenv" => serialize(algorithm.tradeenv),
                            "brokerage" => serialize(algorithm.brokerage),
                            "accounttracker" => serialize(algorithm.accounttracker),
                            "cashtracker" => serialize(algorithm.cashtracker),
                            "performancetracker" => serialize(algorithm.performancetracker),
                            "benchmarktracker" => serialize(algorithm.benchmarktracker),
                            "transactiontracker" => serialize(algorithm.transactiontracker),
                            "ordertracker" => serialize(algorithm.ordertracker),
                            "variabletracker" => serialize(algorithm.variabletracker),
                            "state" => serialize(algorithm.state),
                            "startdate" => algorithm.tradeenv.startdate,
                            "enddate" => algorithm.tradeenv.enddate)
end

Base.Date(s::String) = Date(map(x->parse(Int64, x), split(s, "-"))...)
