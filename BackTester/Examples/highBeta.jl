##################
# Invest in High Beta Stocks
##################
using UtilityAPI

# Intialize the strategy with various settings and/or parameters
function initialize(state)
	
	# NIFTY 50 stock universe as of 25/01/2017
	# Set universe (mandatory before placing any orders)
	# ***Dynamic universe is not allowed yet*** 
	#setuniverse(universe)
end

function ondata(data, state)
	# Get Universe
	universe = getuniverse()
    
	bta =  UtilityAPI.beta(universe, :Day, window = 252)
	
	# Create vector with two columns (Name and Returns) 
	rets = [colnames(bta) vec(values(bta))]

	# Sorted Neta
	sortedBeta = sortslices(rets, dims = 1, rev=true, by=x->(x[2]))
	
	# Get 5 names with lowest returns
	topnames = [String(name) for name in sortedBeta[1:min(5, size(sortedBeta)[1]), 1]]

	opt_port = [(name, 1.0/length(topnames)) for name in topnames]
	
	settargetportfolio(opt_port)
	
	# Track the portfolio value
	track("Portfolio Value", state.account.netvalue)
	
end