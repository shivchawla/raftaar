# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

"""
Type to encapsulate the aggregated analytics like
various exposures and security counts
"""
type PortfolioMetrics
  netexposure::Float64
  grossexposure::Float64
  shortexposure::Float64
  longexposure::Float64
  shortcount::Float64
  longcount::Float64
end

PortfolioMetrics() = PortfolioMetrics(0.0, 0.0, 0.0, 0.0, 0, 0)
==(pm1::PortfolioMetrics, pm2::PortfolioMetrics) = (pm1.netexposure == pm2.netexposure &&
                                                   pm1.grossexposure == pm2.grossexposure &&
                                                   pm1.shortexposure == pm2.shortexposure &&
                                                   pm1.longexposure == pm2.longexposure &&
                                                   pm1.shortcount == pm2.shortcount &&
                                                   pm1.longcount == pm2.longcount)

PortfolioMetrics(data::Dict{String, Any}) = PortfolioMetrics(data["netexposure"],
                                                      data["grossexposure"],
                                                      data["shortexposure"],
                                                      data["longexposure"],
                                                      data["shortcount"],
                                                      data["longcount"])

"""
Type to encapsulate positions and aggregated metrics
"""
type Portfolio
  positions::Dict{SecuritySymbol, Position}
  metrics::PortfolioMetrics
  cash::Float64
end

Portfolio() = Portfolio(Dict(), PortfolioMetrics(), 0.0)
==(p1::Portfolio, p2::Portfolio) = (p1.positions == p2.positions && p1.metrics == p2.metrics && p1.cash == p2.cash)


Portfolio(data::Dict{String, Any}) = Portfolio(
                                Dict(
                                  [(SecuritySymbol(sym), Position(pos)) for (sym, pos) in data["positions"]]
                                ),
                                PortfolioMetrics(data["metrics"]),
                                get(data, "cash", 0.0)

                              )

"""
Indexing function to get position based
on security symbol or security directly from portfolio
"""

getindex(portfolio::Portfolio, symbol::SecuritySymbol) = get(portfolio.positions, symbol, Position(symbol))
getindex(portfolio::Portfolio, security::Security) = get(portfolio.positions, security.symbol, Position(security.symbol))
setindex!(portfolio::Portfolio, position::Position, securitysymbol::SecuritySymbol) =
                      setindex!(portfolio.positions, position, securitysymbol)


"""
function to get all positions in a portfolio
"""
function getallpositions(portfolio::Portfolio)
  values(portfolio.positions)
end

function getposition(portfolio::Portfolio, ss::SecuritySymbol)
  return portfolio[ss]
end

"""
function to update/set position with average price and quantity
"""
function setposition!(portfolio::Portfolio, security::Security, avgprice::Float64, quantity::Int64)
  #=
  position = getposition(portfolio, security)

  if empty(position)
    return
  else
    position.quantity = quantity
    position.averageprice = avgprice
  end
  =#
  setposition!(portfolio, security.symbol, avgprice, quantity)
end

"""
function to update/set position with average price and quantity
"""
function setposition!(portfolio::Portfolio, symbol::SecuritySymbol, avgprice::Float64, quantity::Int64)
  position = getposition(portfolio, symbol)

  if empty(position)
    return
  else
    position.quantity = quantity
    position.averageprice = avgprice
  end
end

#="""
function to get portfolio value
"""
function getportfoliovalue(portfolio::Portfolio)
  pv = 0
  for (sec, pos) in enumerate(portfolio.positions)
    pv += holdingvalue(pos)
  end
  return pv
end

"""
function to get netexposure of the portfolio
"""
function getnetexposure(portfolio::Portfolio)
  portfolio.metrics.netexposure
end

"""
function to get gross exposure
"""
function getgrossexposure(portfolio::Portfolio)
  portfolio.metrics.grossexposure
end=#

"""
function to get absolute of holding cost
"""
function totalabsoluteholdingscost(portfolio::Portfolio)
  tahc = sum(map(x -> absholdingcost(x), values(portfolio.positions)))
  return tahc
end


function updateportfolio_forcash!(portfolio::Portfolio, cash::Float64)
  portfolio.cash += cash
end

"""
function to update portfolio with multiple fills
"""
function updateportfolio_fills!(portfolio::Portfolio, fills::Vector{OrderFill})
  cash = 0.0
  for fill in fills
    cash += updateportfolio_fill!(portfolio, fill)
  end

  updateportfolio_forcash!(portfolio, cash)
  updateportfoliometrics!(portfolio::Portfolio)
  
end

"""
function to update portfolio for single fill
"""
function updateportfolio_fill!(portfolio::Portfolio, fill::OrderFill)

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
function updateportfolioforsplit!(portfolio::Portfolio, split::Split)
  position = portfolio[split.symbol]

  if !empty(position)
      quantity = position.quantity/split.splitFactor
      avgprice = position.averagePrice*split.splitFactor

      #we'll model this as a cash adjustment
      leftOver = quantity - (Int64)quantity
      extraCash = leftOver*split.ReferencePrice
      updateportfolio_forcash!(portfolio, extraCash);
      setposition!(portfolio, split.symbol, avgprice, (int)quantity)
    end
end

"""
function to update portfolio for a split
"""
function updateportfolio_price!(portfolio::Portfolio, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)

  for position in getallpositions(portfolio)
      securitysymbol = position.securitysymbol
      if haskey(tradebars, securitysymbol)
        updateposition_price!(position, tradebars[securitysymbol][1])
      end
  end

  updateportfoliometrics!(portfolio::Portfolio)
end

function updateportfolio_splits_dividends!(portfolio::Portfolio, adjustments::Dict{SecuritySymbol, Adjustment})
    for (symbol, adjustment) in adjustments
        if (adjustment.adjustmenttype != "17.0" && portfolio[symbol].quantity != 0)
            updateposition_splits_dividends!(portfolio[symbol], adjustment)
        end
    end

    cashfromdividends = 0.0
    for (symbol, adjustment) in adjustments
        cashfromdividends += (adjustment.adjustmenttype == "17.0") ? portfolio[symbol].quantity * adjustment.adjustmentfactor : 0.0
    end

    updateportfolio_forcash!(portfolio, cashfromdividends)
    updateportfoliometrics!(portfolio)
end

"""
function to update portfolio metrics
"""
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

function serialize(portfolio::Portfolio)
  temp = Dict{String, Any}("metrics"   => serialize(portfolio.metrics),
                            "positions" => Dict{String, Any}(),
                            "cash" => portfolio.cash)
  for (symbol, pos) in portfolio.positions
    #Removing the position with zero quantity before serialization
    if(abs(pos.quantity) != 0)
      temp["positions"][tostring(symbol)] = serialize(pos)
    end
  end

  return temp
end


