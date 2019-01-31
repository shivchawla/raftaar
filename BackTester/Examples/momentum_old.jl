##################
# Basic stock reversal strategy 
# Rebalances portfolio every week 
# Invest in bottom (least performing) 5 stocks of NIFTY based on
# last 22 days return
##################

# Intialize the strategy with various settings and/or parameters
function initialize(state)
	
	# NIFTY 50 stock universe as of 25/01/2017
	# This universe has Survivorship bias
	universe = ["ACC","ADANIPORTS","AMBUJACEM",
	"ASIANPAINT","AUROPHARMA","AXISBANK","BAJAJ_AUTO"]#,
	# "BANKBARODA","BHEL","BPCL",	"BHARTIARTL","INFRATEL",
	# "BOSCHLTD","CIPLA","COALINDIA","DRREDDY","EICHERMOT",
	# "GAIL","GRASIM","HCLTECH","HDFCBANK","HEROMOTOCO","HINDALCO",
	# "HINDUNILVR","HDFC","ITC","ICICIBANK","IDEA",
	# "INDUSINDBK","INFY","KOTAKBANK","LT","LUPIN","M_M",
	# "MARUTI","NTPC","ONGC","POWERGRID","RELIANCE","SBIN",
	# "SUNPHARMA","TCS","TATAMTRDVR","TATAMOTORS","TATAPOWER",
	# "TATASTEEL","TECHM","ULTRACEMCO","WIPRO","YESBANK","ZEEL"]
	
	# Set Cancel policy to EOD 
	# All open order are canceled at End of Day
	# This is redundant as  default is EOD as well
	setcancelpolicy(EOD)
	
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

	println("71")
	# Get Universe
	universe = getuniverse()
	
	println("72")
	# Fetch prices for last 22 days
	prices = history(universe, "Close", :Day, 22)

	println("73")
	logpricesdiff = diff(log.(prices))
	

	println("74")
	#println("Fetching Prices")
	returns = cumsum(values(logpricesdiff), dims=1)[end, :]

	println("75")

	rets = [colnames(prices) vec(returns)]

	println("76")

	# Sorted returns
	sortedrets = sortslices(rets, dims=1, rev=true)
	#info(string(sortedrets))

	println("77")
	
	# Get 5 names with lowest retursn
	topnames = sortedrets[1:5, 1]

	println("78")

	#Liquidate from portfolio if not in bottom 5 anymore
	for (stock, positions) in state.account.portfolio.positions
		if (stock.ticker in topnames)
			continue
		else	
			setholdingpct(stock, 0.0)
		end
	end

	println("79")
	
	#info("$(length(topnames))")
	# Create momemtum portfolio
	for (i,stock) in enumerate(topnames)
		setholdingpct(stock, 1.0/length(topnames)) # -0.2)#(6-i)*(1.0/15.0))
	end

	println("80")
	
	# Track the portfolio value
	track("Portfolio Value", state.account.netvalue)
	
	# Output information to console
	Logger.info("Portofolio value = $(state.account.netvalue)")

end
        