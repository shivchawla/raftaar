

type PortfolioStats
  netexposure::Float64
  grossvalue::Float64
  grossexposure::Float64
  shortexposure::Float64
  shortcount::Int64
  longexposure::Float64
  longcount::Int64
  netvalue::Float64
  totalprofit::Float64
  totalfees::Float64
  totalsalevolume::Float64
  totalmarginused::Float64
  marginremaining::Float64
end

type Portfolio
  startcash::Float64
  currentcash::Float64
  capitalused::Float64
  positions::Dict{SecuritySymbol, Position}
  portstats::PortfolioStats
  fills::Vector{OrderFill}

  function Portfolio(startCash::Cash, currentCash::Cash, portfolioValue::Float64
            portfolioReturn::Float64, positions::Vector{Position}, capitalUsed::Float64)
      new(startCash, currentCash, portfolioValue, portfolioReturn, positions, capitalUsed)
  end
end

getindex(portfolio::Portfolio, symbol::SecuritySymbol) = get(portfolio, symbol, Position())


getposition(portfolio::Portfolio, symbol::SecuritySymbol) = get(portfolio, symbol, Position())

getposition(portfolio::Portfolio, security::Security) = get(portfolio, security.symbol, Position())

function addcash!(portfolio::Portfolio, cash::Float64)
  portfolio.currentcash += cash
end

function setposition!(portfolio::Portfolio, security::Security, avgprice::Float64, quantity::Int64)
  position = getposition(portfolio, security)

  if isempty(position)
    return
  else
    position.quantity = quantity
    position.averageprice = avgprice  
  end
end

function totalportfoliovalue(portfolio::Portfolio)
  tpv = 0
  for (sec, pos) in enumerate(portfolio.positions)
    tpv += holdingvalue(pos)
  end
  return tpv
end


function totalabsoluteholdingscost(portfolio)
  tahc = 0
  for (sec, pos) in enumerate(portfolio.positions)
    tahc += absholdingcost(pos)
  end
  return tahc
end

function updateportfolioforfill(portfolio::Portfolio, security::Security, fill::OrderFill)
    
  position = portfolio[security]
  if (isempty(position))
    "message"
    return
  end
  
  "Append the fill to the portfolio list of fills"
  append(portfolio.fills, fill)

  "function return cash generated with the fill"
  portfolio.currentCash += updatepositionforfill(position, fill)

  "How to update CAPITAL USED?????"

  "update portfolio statistics"
  "This fucntion can be improved fr efficiency as only one position has changed"
  updateportfoliostats(portfolio)
end


function updateportfoliostats!(portfolio) 

  netexposure = 0   
  grossvalue = 0
  grossexposure = 0  
  shortexposure = 0
  shortcount = 0
  longexposure = 0
  longcount = 0
  netvalue = 0
  totalprofit = 0
  totalfees = 0
  totalsalevolume = 0
  totalmarginused = 0
  marginremaining = 0

  for (sec, pos) in enumerate(portfolio.positions)
    netexposure += pos.quantity * pos.avgprice  
    grossexposure += absholdingvalue(position) 
    shortexposure += position.quantity < 0 ? absholdingvalue(position) : 0
    shortcount +=  position.quantity < 0 ? 1 : 0
    longexposure += position.quantity > 0 ? absholdingvalue(position) : 0
    longcount += position.quantity > 0 ? 1 : 0
    totalpnl += position.totalpnl
    totalfees += position.totalfees 
    totalsalevolume += position.totalsalevolume 
    totalmarginused = 0
    marginremaining = 0
  end

    portfolio.netexposure = netexposure
    portfolio.grossexposure = grossexposure
    portfolio.shortexposure = shortexposure
    portfolio.shortcount = shortcount
    portfolio.longexposure = longexposure
    portfolio.longcount = longcount
    portfolio.totalpnl = totalpnl
    portfolio.totalfees = totalfees
    portfolio.totalsalevolume = totalsalevolume
    portfolio.totalmarginused = totalmarginused
    portfolio.marginremaining = marginremaining
  
end




