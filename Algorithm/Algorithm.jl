
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

using DataStructures

@enum AlgorithmStatus DeployError InQueue Running Stopped Liquidated Deleted Completed RuntimeError LoggingIn Initializing
  
type Algorithm
	algorithmid::ASCIIString
	status::AlgorithmStatus
	account::Account
	universe::Universe
	tradeenv::TradingEnvironment
	brokerage::BacktestBrokerage
    accounttracker::AccountTracker #To track evolution of account with time
    cashtracker::CashTracker
end

Algorithm() = Algorithm("", AlgorithmStatus(Initializing), Account(), 
                                            Universe(), TradingEnvironment(), 
                                            BacktestBrokerage(), Dict{DateTime, Account}(), 
                                            Dict{DateTime, Float64}())

function updateaccounttracker!(algorithm::Algorithm)
    accountcopy = deepcopy(algorithm.account)
    algorithm.accounttracker[getcurrentdatetime(algorithm.tradeenv)] = accountcopy
end

function setcash!(algorithm::Algorithm, cash::Float64)
    algorithm.cashtracker[getcurrentdatetime(algorithm.tradeenv)] = cash    
    setcash!(algorithm.account, cash)
end
 
function addcash!(algorithm::Algorithm, cash::Float64)
    algorithm.cashtracker[getcurrentdatetime(algorithm.tradeenv)] = cash    
    addcash!(algorithm.account, cash)
end



