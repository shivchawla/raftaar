
type AlgorithmParameters
	slippagemodel::SlippageModel
	feemodel::FeeModel
	brokeragemodel::BrokerModel
	marginmodel::MarginModel
	cancelpolicy::OrderDuration
	benchmark::SecuritySymbol
	seedCash::Float64

end

@enum AlgorithmStatus
    DeployError = 1    #Error compiling algorithm at start
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
        
type Algorithm
	algorithmid::ASCIIString
	status::AlgorithmStatus
	portfolio::Portfolio
	universe::Universe
	blotter::Blotter
	tradeenv::TradingEnvironment
	algoparameters::AlgorithmParameters

	Algorithm(algorithmid::ASCIIString, status::AlgorithmStatus, portfolio::Portfolio, universe::Universe, 
				blotter::Blotter, tradeenv::TradingEnvironment, algoparameters::AlgorithmParameters)
	= new(algorithmid, status, portfolio, universe, blotter, tradeenv, algoparameters)

end

Algorithm() = Algorithm(ASCIIString(), AlgorithmStatus.Initializing, Portfolio(), Universe(),
						Blotter(), TradingEnvironment(), AlgorithmParameters())


function getfeemodel(algorithm::Algorithm) 
	return algorithm.algoparameter.feemodel
end

function initialize()
	
end

function setalgorithmid!(algorithm::Algorithm)
	
end





