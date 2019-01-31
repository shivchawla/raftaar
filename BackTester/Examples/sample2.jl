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
end

# Define strategy logic: Calculate 22 days return, sort 
# and invest 20% of wealth in bottom 5 stocks

# All order based functions are called 
# every DAY/WEEK/MONTH (depends on rebalance frequency)
# Default rebalance Frequency: Daily
function ondata(data, state)
	
	# Get Universe
	universe = getuniverse()
	
	# Fetch prices for last 22 days
	prices = history(universe, "Close", :Day, 22)
	
	# Logic to calculate returns over last month
	# Output: TimeArray
	# http://timeseriesjl.readthedocs.io/en/latest/
	logpricesdiff = diff(log.(prices))
	
	returns = cumsum(values(logpricesdiff), dims=1)[end, :]

	# Create vector with two columns (Name and Returns) 
	rets = [colnames(prices) vec(returns)]

	# Sorted returns
	sortedrets = sortslices(rets, dims=1, rev=true, by=x->(x[2]))

	# Get 5 names with lowest retursn
	topnames = sortedrets[1:min(5, size(sortedrets)[1]), 1]

	#Liquidate from portfolio if not in bottom 5 anymore
	for (stock, positions) in state.account.portfolio.positions
		if (stock.ticker in topnames)
			continue
		else	
			setholdingpct(stock, 0.0)
		end
	end
	
	# Create momemtum portfolio
	for (i,stock) in enumerate(topnames)
		setholdingpct(stock, 1.0/length(topnames)) 
	end
	
	# Track the portfolio value
	track("Portfolio Value", state.account.netvalue)
	
	# Output information to console
	#Logger.info("Portfolio value = $(state.account.netvalue)")
	
end