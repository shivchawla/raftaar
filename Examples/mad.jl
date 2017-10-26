##################
# Basic stock reversal strategy 
# Rebalances portfolio every week 
# Invest in bottom (least performing) 5 stocks of NIFTY based on
# last 22 days return
##################
using OptimizeAPI

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
	
	# Set Cancel policy to EOD 
	# All open order are canceled at End of Day
	# This is redundant as  default is EOD as well
	setcancelpolicy(CancelPolicy(EOD))
	
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
	
	nstocks = length(universe)
	initialportfolio = zeros(nstocks)

	netvalue = state.account.netvalue

	for i=1:nstocks
		pos = getposition(universe[i])
		initialportfolio[i] = (pos.quantity * pos.lastprice)/netvalue
	end

	#Optimize
	#(obj, opt_port) = Optimize.minimumabsolutesemideviation(universe, 22, getcurrentdatetime())
	#(obj, opt_port) = Optimize.minimumloss(universe, 22, getcurrentdatetime())
	(obj, port, status) = OptimizeAPI.optimize(universe, window = 22, method="meanvar", initialportfolio=initialportfolio)

	#=for v in port
		#Logger.info("Portfolio Wt. $stock = $(opt_port[i])")
		setholdingpct(v[1], v[2]) # -0.2)#(6-i)*(1.0/15.0))
	end=#

	targetportfolio(port)
	
	# Track the portfolio value
	track("Portfolio Value", state.account.netvalue)
	
	# Output information to console
	info("Portofolio value = $(state.account.netvalue)")

end
        