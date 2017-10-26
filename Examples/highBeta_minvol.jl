##################
# Basic stock reversal strategy 
# Rebalances portfolio every week 
# Invest in bottom (least performing) 5 stocks of NIFTY based on
# last 22 days return
##################
using OptimizeAPI
using UtilityAPI

# Intialize the strategy with various settings and/or parameters
function initialize(state)
	
	# NIFTY 50 stock universe as of 25/01/2017
	# This universe has Survivorship bias
	universe = ["ACC","ADANIPORTS","AMBUJACEM",
	"ASIANPAINT","AUROPHARMA","AXISBANK","BAJAJ_AUTO",
	"BANKBARODA","BHEL","BPCL",	"BHARTIARTL","INFRATEL",
	"BOSCHLTD","CIPLA","COALINDIA","DRREDDY","EICHERMOT",
	"GAIL","GRASIM","HCLTECH","HDFCBANK","HEROMOTOCO","HINDALCO",
	"HINDUNILVR","HDFC","ITC","ICICIBANK","IDEA",
	"INDUSINDBK","INFY","KOTAKBANK","LT","LUPIN","M_M",
	"MARUTI","NTPC","ONGC","POWERGRID","RELIANCE","SBIN",
	"SUNPHARMA","TCS","TATAMTRDVR","TATAMOTORS","TATAPOWER",
	"TATASTEEL","TECHM","ULTRACEMCO","WIPRO","YESBANK","ZEEL"]
	
	# Set universe (mandatory before placing any orders)
	# ***Dynamic universe is not allowed yet*** 
	setuniverse(universe)
end

# Define strategy logic: Calculate 22 days return, sort 
# and invest 20% of wealth in bottom 5 stocks

# All order based functions are called 
# every DAY/WEEK/MONTH (depends on rebalance frequency)
# Default rebalance Frequency: Daily
function ondata(data, state)
	# Get Universe
	universe = getuniverse()
	
	@time (bta, alpha, stability) =  UtilityAPI.beta(universe, :Day, window=252)
	
	# Create vector with two columns (Name and Returns) 
	rets = [colnames(bta) vec(values(bta)) vec(values(alpha))]

	# Sorted Neta
	sortedBeta = sortrows(rets, by=x->(-x[3]))[1:20,:]
	
	# Get 5 names with lowest returns
	topnames = [String(name) for name in sortedBeta[1:5, 1]]

	#Optimize
	(obj, opt_port, status) = OptimizeAPI.optimize(topnames, window=22)
	
	targetportfolio(opt_port)
	
	# Track the portfolio value
	track("Portfolio Value", state.account.netvalue)
	
	# Output information to console
	info("Portofolio value = $(state.account.netvalue)")

end
        