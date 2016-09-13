
include("Portfolio.jl")

type Account
	portfolio::Portfolio
	cash::Float64
    metrics::PortfolioMetrics
end

Account() = Account(Portfolio(), 0.0, PortfolioMetrics())

#get positions

function setcash!(account::Account, amount::Float64)
	account.cash = amount
end

function getportfoliovalue(account::Account)
    account.metrics.netvalue
end

function updateportfoliometrics!(account::Account, cashfromfills::Float64 = 0.0) 
  
  account.metrics = PortfolioMetrics()
  metrics = account.metrics
  account.cash += cashfromfills

  for (symbol, position) in account.portfolio.positions
    metrics.netexposure += position.quantity * position.lastprice  
    metrics.grossexposure += abs(position.quantity * position.lastprice)
    metrics.shortexposure += position.quantity < 0 ? abs(position.quantity * position.lastprice) : 0.0
    metrics.shortcount +=  position.quantity < 0 ? 1 : 0
    metrics.longexposure += position.quantity > 0 ? abs(position.quantity * position.lastprice) : 0.0
    metrics.longcount += position.quantity > 0 ? 1 : 0
    #metrics.totalprofit += position.totalpnl
    #metrics.totalfees += position.totalfees 
    #metrics.totalsalevolume += position.totalsalevolume 
    #metrics.totalmarginused = 0
    #metrics.marginremaining = 0
  end

  metrics.netvalue = metrics.netexposure + account.cash 
  metrics.leverage = metrics.grossexposure / metrics.netvalue
  
end
