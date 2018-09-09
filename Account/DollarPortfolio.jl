# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

"""
Type to encapsulate positions and aggregated metrics
"""
type DollarDollarPortfolio
  positions::Dict{SecuritySymbol, DollarPosition}
  metrics::PortfolioMetrics
  cash::Float64
end

DollarPortfolio() = DollarPortfolio(Dict(), PortfolioMetrics(), 0.0)
==(p1::DollarPortfolio, p2::DollarPortfolio) = (p1.positions == p2.positions && p1.metrics == p2.metrics && p1.cash == p2.cash)


DollarPortfolio(data::Dict{String, Any}; cash::Float64=0.0) = DollarPortfolio(
                                Dict(
                                  [(SecuritySymbol(sym), Position(pos)) for (sym, pos) in data["positions"]]
                                ),
                                PortfolioMetrics(data["metrics"]),
                                cash !=0.0 ? cash : get(data, "cash", 0.0)
                              )

"""
Indexing function to get position based
on security symbol or security directly from portfolio
"""

getindex(portfolio::DollarPortfolio, symbol::SecuritySymbol) = get(portfolio.positions, symbol, Position(symbol))
getindex(portfolio::DollarPortfolio, security::Security) = get(portfolio.positions, security.symbol, Position(security.symbol))
setindex!(portfolio::DollarPortfolio, position::Position, securitysymbol::SecuritySymbol) =
                      setindex!(portfolio.positions, position, securitysymbol)


"""
function to get all positions in a portfolio
"""
function getallpositions(portfolio::DollarPortfolio)
  values(portfolio.positions)
end

function getposition(portfolio::DollarPortfolio, ss::SecuritySymbol)
  return portfolio[ss]
end

"""
function to update/set position with average price and investment
"""
function setposition!(portfolio::DollarPortfolio, security::Security, avgprice::Float64, investment::Float64)
   setposition!(portfolio, security.symbol, avgprice, investment)
end

"""
function to update/set position with average price and investment
"""
function setposition!(portfolio::DollarPortfolio, symbol::SecuritySymbol, avgprice::Float64, investment::Float64)
  position = getposition(portfolio, symbol)

  if empty(position)
    return
  else
    position.investment = investment
    position.averageprice = avgprice
  end
end

#="""
function to get portfolio value
"""
function getportfoliovalue(portfolio::DollarPortfolio)
  pv = 0
  for (sec, pos) in enumerate(portfolio.positions)
    pv += holdingvalue(pos)
  end
  return pv
end

"""
function to get netexposure of the portfolio
"""
function getnetexposure(portfolio::DollarPortfolio)
  portfolio.metrics.netexposure
end

"""
function to get gross exposure
"""
function getgrossexposure(portfolio::DollarPortfolio)
  portfolio.metrics.grossexposure
end=#

"""
function to get absolute of holding cost
"""
function totalabsoluteholdingscost(portfolio::DollarPortfolio)
  tahc = sum(map(x -> absholdingcost(x), values(portfolio.positions)))
  return tahc
end

function setportfolio_forcash!(portfolio::DollarPortfolio, cash::Float64)
  portfolio.cash = cash
end

function updateportfolio_forcash!(portfolio::DollarPortfolio, cash::Float64)
  portfolio.cash += cash
end

"""
function to update portfolio with multiple fills
"""
function updateportfolio_fills!(portfolio::DollarPortfolio, fills::Vector{OrderFill})
  cash = 0.0
  for fill in fills
    cash += updateportfolio_fill!(portfolio, fill)
  end

  updateportfolio_forcash!(portfolio, cash)
  updateportfoliometrics!(portfolio)
  
end

"""
function to update portfolio for single fill
"""
function updateportfolio_fill!(portfolio::DollarPortfolio, fill::OrderFill)

  securitysymbol = fill.securitysymbol

  if !haskey(portfolio.positions, securitysymbol)
      portfolio[securitysymbol] = Position(securitysymbol)
  end

  position = portfolio[securitysymbol]

  #function to adjust position for fill and update cash in portfolio
  return updateposition_fill!(position, fill)

end

"""
function to update portfolio for a split
"""
function updateportfolioforsplit!(portfolio::DollarPortfolio, split::Split)
  position = portfolio[split.symbol]

  if !empty(position)
  	avgprice = position.averagePrice*split.splitFactor

	setposition!(portfolio, split.symbol, avgprice, investment)
    end
end

"""
function to update portfolio for a split
"""
function updateportfolio_price!(portfolio::DollarPortfolio, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)

  for position in getallpositions(portfolio)
      securitysymbol = position.securitysymbol
      if haskey(tradebars, securitysymbol)
        updateposition_price!(position, tradebars[securitysymbol][1])
      end
  end

  updateportfoliometrics!(portfolio)
end

function updateportfolio_splits_dividends!(portfolio::DollarPortfolio, adjustments::Dict{SecuritySymbol, Adjustment})
    cashfromdividends = 0.0
    for (symbol, adjustment) in adjustments
        if (portfolio[symbol].investment != 0)
            cashfromdividends += updateposition_splits_dividends!(portfolio[symbol], adjustment)
        end
    end

    updateportfolio_forcash!(portfolio, cashfromdividends)
    updateportfoliometrics!(portfolio)
end

"""
function to update portfolio metrics
"""
function updateportfoliometrics!(portfolio::DollarPortfolio)

  portfolio.metrics = PortfolioMetrics()

  for (symbol, position) in portfolio.positions
  	qty = position.averageprice > 0.0 ? position.investment/position.averageprice : 0.0
    portfolio.metrics.netexposure +=  qty*position.lastprice
    portfolio.metrics.grossexposure += abs(qty * position.lastprice)
    portfolio.metrics.shortexposure += qty < 0 ? abs(qty * position.lastprice) : 0.0
    portfolio.metrics.shortcount +=  qty < 0 ? 1 : 0
    portfolio.metrics.longexposure += qty > 0 ? abs(qty * position.lastprice) : 0.0
    portfolio.metrics.longcount += qty > 0 ? 1 : 0
  end

end

"""
Serialize the portfolio to dictionary object
"""

function serialize(metrics::PortfolioMetrics)
  return Dict{String, Any}("netexposure"    => metrics.netexposure,
                            "grossexposure" => metrics.grossexposure,
                            "shortexposure" => metrics.shortexposure,
                            "longexposure"  => metrics.longexposure,
                            "shortcount"    => metrics.shortcount,
                            "longcount"     => metrics.longcount)
end

function serialize(portfolio::DollarPortfolio)
  temp = Dict{String, Any}("metrics"   => serialize(portfolio.metrics),
                            "positions" => Dict{String, Any}(),
                            "cash" => portfolio.cash)
  for (symbol, pos) in portfolio.positions
    #Removing the position with zero investment before serialization
    if(abs(pos.investment) != 0.0)
      temp["positions"][tostring(symbol)] = serialize(pos)
    end
  end

  return temp
end


