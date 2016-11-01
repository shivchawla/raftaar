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

include("Universe.jl")
include("TradingEnvironment.jl")
include("../Account/Account.jl")
include("../Execution/Brokerage.jl")
include("../Performance/Performance.jl")

@enum AlgorithmStatus DeployError InQueue Running Stopped Liquidated Deleted Completed RuntimeError LoggingIn Initializing

typealias VariableTracker Dict{String, Dict{DateTime, Float64}}

"""
Algorithm type 
Encapsulates various entities that characterise an Algorithm    
"""  
type Algorithm
	algorithmid::String
	status::AlgorithmStatus
	account::Account
	universe::Universe
	tradeenv::TradingEnvironment
	brokerage::BacktestBrokerage
    accounttracker::AccountTracker #To track evolution of account with time
    cashtracker::CashTracker
    variabletracker::VariableTracker
end

"""
Algorithm empty constructor
"""
Algorithm() = Algorithm("", AlgorithmStatus(Initializing), Account(), 
                                            Universe(), TradingEnvironment(), 
                                            BacktestBrokerage(),AccountTracker(), 
                                            CashTracker(), VariableTracker())


"""
Reset algorithm variable to default
"""
function reset(algorithm::Algorithm) 
    algorithm.algorithmid=""
    algorithm.status = AlgorithmStatus(Initializing) 
    algorithm.account = Account()
    algorithm.universe = Universe()
    algorithm.tradeenv = TradingEnvironment()
    algorithm.brokerage = BacktestBrokerage()
    algorithm.accounttracker = AccountTracker() #To track evolution of account with time
    algorithm.cashtracker = CashTracker()
    algorithm.variabletracker = VariableTracker()
    return
end

"""
Function to track the account at each time step
"""
function updateaccounttracker!(algorithm::Algorithm)
    accountcopy = deepcopy(algorithm.account)
    algorithm.accounttracker[getcurrentdatetime(algorithm.tradeenv)] = accountcopy
end

"""
Function to set initial cash in the algorithm
"""
function setcash!(algorithm::Algorithm, cash::Float64)
    algorithm.cashtracker[getcurrentdatetime(algorithm.tradeenv)] = cash    
    setcash!(algorithm.account, cash)
end

"""
Function to add more cash to the algorithm
""" 
function addcash!(algorithm::Algorithm, cash::Float64)
    algorithm.cashtracker[getcurrentdatetime(algorithm.tradeenv)] = cash    
    addcash!(algorithm.account, cash)
end

"""
Function to add new variable to variable tracker (at current algorithm time)
"""
function addvariable!(algorithm::Algorithm, name::String, value::Float64)
    addvariable!(algorithm.variabletracker, name, value, getcurrentdatetime(algorithm.tradeenv))
end

"""
Function to add new variable to variable tracker (at the defined time)
"""
function addvariable!(variabletracker::VariableTracker, name::String, value::Float64, datetime::DateTime)
    if (!haskey(variabletracker, name))
        variabletracker[name] = Dict()
    end

    tracker = variabletracker[name]
    tracker[datetime] = value

end



