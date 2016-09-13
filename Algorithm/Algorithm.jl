
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

@enum AlgorithmStatus DeployError InQueue Running Stopped Liquidated Deleted Completed RuntimeError LoggingIn Initializing
        
type Algorithm
	algorithmid::ASCIIString
	status::AlgorithmStatus
	account::Account
	universe::Universe
	tradeenv::TradingEnvironment
	brokerage::BacktestBrokerage
end

Algorithm() = Algorithm("", AlgorithmStatus(Initializing), Account(), Universe(), TradingEnvironment(), BacktestBrokerage())





