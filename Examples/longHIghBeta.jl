##################
# Basic stock reversal strategy 
# Rebalances portfolio every week 
# Invest in bottom (least performing) 5 stocks of NIFTY based on
# last 22 days return
##################
using Raftaar
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
	
	(bta, alpha, stability) =  beta(universe, :Day, 252)
	
	Logger.info(string(bta))
	
	# Create vector with two columns (Name and Returns) 
	rets = [colnames(bta) vec(values(bta))]

	# Sorted returns
	sortedrets = sortrows(rets, by=x->(-x[2]))
	#info(string(sortedrets))
	
	# Get 5 names with lowest retursn
	topnames = sortedrets[1:5]

	#Liquidate from portfolio if not in bottom 5 anymore
	for (stock, positions) in state.account.portfolio.positions
		if (stock.ticker in topnames)
			continue
		else	
			setholdingpct(stock, 0.0)
		end
	end
	
	#info("$(length(topnames))")
	# Create momemtum portfolio
	for (i,stock) in enumerate(topnames)
		setholdingpct(stock, 1.0/length(topnames)) # -0.2)#(6-i)*(1.0/15.0))
	end
	
	# Track the portfolio value
	track("Portfolio Value", state.account.netvalue)
	
	# Output information to console
	info("Portofolio value = $(state.account.netvalue)")

end
        