##################
# Basic stock reversal strategy 
# Rebalances portfolio every week 
# Invest in bottom (least performing) 5 stocks of NIFTY based on
# last 22 days return
##################
using UtilityAPI
using OptimizeAPI

# Intialize the strategy with various settings and/or parameters
function initialize(state)
	
	universe = ["ACC","ADANIPORTS","AMBUJACEM",
	"ASIANPAINT","AUROPHARMA","AXISBANK","BAJAJ_AUTO",
	"BANKBARODA","BHEL","BPCL",	"BHARTIARTL","INFRATEL",
	"BOSCHLTD","CIPLA","COALINDIA","DRREDDY","EICHERMOT"]
	# "GAIL","GRASIM","HCLTECH","HDFCBANK","HEROMOTOCO","HINDALCO",
	# "HINDUNILVR","HDFC","ITC","ICICIBANK","IDEA",
	# "INDUSINDBK","INFY","KOTAKBANK","LT","LUPIN","M_M",
	# "MARUTI","NTPC","ONGC","POWERGRID","RELIANCE","SBIN",
	# "SUNPHARMA","TCS","TATAMTRDVR","TATAMOTORS","TATAPOWER",
	# "TATASTEEL","TECHM","ULTRACEMCO","WIPRO","YESBANK","ZEEL"]
	# NIFTY 50 stock universe as of 25/01/2017
	# This universe has Survivorship bias
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
	
	names = [sec.symbol.ticker for sec in universe]
	
	# Fetch returns of stocks over last 22 days
	priceTA = history(universe, "Close", :Day, 22)
	
	vs = values(priceTA[1])./values(priceTA)
	
	coeff= mean(vs, dims=1)
	
	# Create vector with two columns (Name and Returns) 
	rets = [colnames(priceTA) vec(coeff)]
	
	# Sorted returns
	#sortedrets = sortrows(rets, by=x->(-x[2]))
	
	# Get 5 names with lowest retursn
	# this is a problem
	# Can be fixed by adding support for Any struct array in optimization
	#topnames = [String(name) for name in sortedrets[1:5, 1]]
	
	#sortedrets = sortrows(rets, by=x->(-x[2]))
	
	#bottomnames = [String(name) for name in sortedrets[1:5, 1]]
	
	#port = [(name, 1.0/length(topnames)) for name in topnames]
	#s_port = [(name, -0.5/length(bottomnames)) for name in bottomnames]
	
	#port = append!(l_port, s_port)
	
	nstocks = length(universe)
	
	initial = zeros(nstocks)
	uniform = ones(nstocks)/nstocks
	
	nav = getportfoliovalue()
	for (i,position) in enumerate(getallpositions())
		initial[i] = position.lastprice*position.quantity/nav
	end
	
	flag = [pos==0.0 ? 1 : 0 for pos in initial]
	
	if sum(flag) == nstocks
		initial = uniform
	end
	
	#Optimize
	(obj, opt_port, status) = OptimizeAPI.optimize(universe, 
									method="norm", 
									initialportfolio=initial,
									linearrestrictions=[LinearRestriction(vec(coeff),1.005, 2.0)])
	
	#targetportfolio(opt_port)
	if status == :Optimal
		targetportfolio(opt_port)
	end
	
	# Track the portfolio value
	track("Portfolio Value", state.account.netvalue)
	
	# Output information to console
	Logger.info("Portofolio value = $(state.account.netvalue)")
end
        