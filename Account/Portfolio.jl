
include("Position.jl")
include("../DataTypes/Split.jl")

type PortfolioMetrics
  netexposure::Float64
  grossexposure::Float64
  shortexposure::Float64
  shortcount::Float64
  longexposure::Float64
  longcount::Float64
end

PortfolioMetrics() = PortfolioMetrics(
                      0.0, 0.0, 0.0, 
                      0.0, 0.0, 0.0)

type Portfolio
  cash::Float64
  positions::Dict{SecuritySymbol, Position}
  metrics::PortfolioMetrics
end

Portfolio() = Portfolio(0.0, Dict(), PortfolioMetrics())

getindex(portfolio::Portfolio, symbol::SecuritySymbol) = get(portfolio.positions, symbol, Position())
getindex(portfolio::Portfolio, security::Security) = get(portfolio.positions, security.symbol, Position())
setindex!(portfolio::Portfolio, position::Position, securitysymbol::SecuritySymbol) = 
                      setindex!(portfolio.positions, position, securitysymbol)


function getindex(portfolio::Portfolio, ticker::ASCIIString) 
  symbol = createsymbol(ticker, SecurityType(Equity))
  get(portfolio, symbol, Position())
end

function getallpositions(portfolio::Portfolio)
  values(portfolio.positions)
end

function setposition!(portfolio::Portfolio, security::Security, avgprice::Float64, quantity::Int64)
  position = getposition(portfolio, security)

  if empty(position)
    return
  else
    position.quantity = quantity
    position.averageprice = avgprice  
  end
end

function setposition!(portfolio::Portfolio, symbol::SecuritySymbol, avgprice::Float64, quantity::Int64)
  position = getposition(portfolio, symbol)

  if empty(position)
    return
  else
    position.quantity = quantity
    position.averageprice = avgprice  
  end
end

function getportfoliovalue(portfolio::Portfolio)
  pv = 0
  for (sec, pos) in enumerate(portfolio.positions)
    pv += holdingvalue(pos)
  end
  return pv
end


function getnetexposure(portfolio::Portfolio)
  portfolio.metrics.netexposure
end


function getgrossexposure(portfolio::Portfolio)
  portfolio.metrics.grossexposure
end


function totalabsoluteholdingscost(portfolio::Portfolio)
  tahc = 0
  for (sec, pos) in enumerate(portfolio.positions)
    tahc += absholdingcost(pos)
  end
  return tahc
end

function updateportfolioforfills!(portfolio::Portfolio, fills::Vector{OrderFill})
  cash = 0.0 
  for fill in fills 
    cash += updateportfolioforfill!(portfolio, fill)
  end

  updateportfoliometrics!(portfolio::Portfolio)

  return cash
end

function updateportfolioforfill!(portfolio::Portfolio, fill::OrderFill)
   
  securitysymbol = fill.securitysymbol  
  
  if !haskey(portfolio.positions, securitysymbol)
      portfolio[securitysymbol] = Position(securitysymbol)  
  end  

  position = portfolio[securitysymbol]
  
  #function to adjust position for fill and update cash in portfolio
  return updatepositionforfill!(position, fill)

end

function updateportfolioforsplit!(portfolio::Portfolio, split::Split)
  position = portfolio[split.symbol]
   
  if !empty(position)
      quantity = position.quantity/split.splitFactor
      avgprice = position.averagePrice*split.splitFactor

      #we'll model this as a cash adjustment
      leftOver = quantity - (Int64)quantity
      extraCash = leftOver*split.ReferencePrice
      addcash!(portfolio, extraCash);
      setposition!(portfolio, split.symbol, avgprice, (int)quantity)
    end       
end 

function addcash!(portfolio::Portfolio, extraCash::Float64)
  #portfolio.cash += extraCash;
end

function updateportfolioforprice!(portfolio::Portfolio, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)

  for position in getallpositions(portfolio)
      securitysymbol = position.securitysymbol
      if haskey(tradebars, securitysymbol)
        updatepositionforprice!(position, tradebars[securitysymbol][1])
      end
  end 

  updateportfoliometrics!(portfolio::Portfolio)
end


function updateportfoliometrics!(portfolio::Portfolio) 
  
  portfolio.metrics = PortfolioMetrics()

  for (symbol, position) in portfolio.positions
    portfolio.metrics.netexposure += position.quantity * position.lastprice  
    portfolio.metrics.grossexposure += abs(position.quantity * position.lastprice)
    portfolio.metrics.shortexposure += position.quantity < 0 ? abs(position.quantity * position.lastprice) : 0.0
    portfolio.metrics.shortcount +=  position.quantity < 0 ? 1 : 0
    portfolio.metrics.longexposure += position.quantity > 0 ? abs(position.quantity * position.lastprice) : 0.0
    portfolio.metrics.longcount += position.quantity > 0 ? 1 : 0
  end

end



