using Mongo

function serialize(algorithm::Algorithm)
  return Dict{String, Any}("object"   => "algorithm",
                            "name"    => algorithm.name,
                            "id"      => algorithm.algorithmid,
                            "status"  => string(algorithm.status))
end

function serialize(account::Account)
  return Dict{String, Any}("object"    => "account",
                            "seedcash" => account.seedcash,
                            "cash"     => account.cash,
                            "netvalue" => account.netvalue,
                            "leverage" => account.leverage)
end

function serialize(portfolio::Portfolio)
  function serialize(metrics::PortfolioMetrics)
    return Dict{String, Any}("object"         => "portfoliometrics",
                              "netexposure"   => metrics.netexposure,
                              "grossexposure" => metrics.grossexposure,
                              "shortexposure" => metrics.shortexposure,
                              "longexposure"  => metrics.longexposure,
                              "shortcount"    => metrics.shortcount,
                              "longcount"     => metrics.longcount)
  end

  function serialize(symbol::SecuritySymbol, position::Position)
    return Dict{String, Any}("securitysymbol"   => symbol.ticker,
                            "quantity"          => position.quantity,
                            "averageprice"      => position.averageprice,
                            "totalfees"         => position.totalfees,
                            "lastprice"         => position.lastprice,
                            "lasttradepnl"      => position.lasttradepnl,
                            "realizedpnl"       => position.realizedpnl,
                            "totaltradedvolume" => position.totaltradedvolume)
  end

  temp = Dict{String, Any}("object"     => "portfolio",
                            "metrics"   => serialize(portfolio.metrics),
                            "positions" => Dict{String, Any}())
  for symbol in keys(portfolio.positions)
    temp["positions"][symbol.ticker] = serialize(symbol, portfolio.positions[symbol])
  end

  return temp
end

function serialize(universe::Universe)
  function serialize(security::Security)
    return Dict{String, Any}("symbol"        => security.symbol.ticker,
                              "id"           => security.symbol.id,
                              "name"         => security.name,
                              "exchange"     => security.exchange,
                              "country"      => security.country,
                              "securitytype" => security.securitytype,
                              "startdate"    => security.startdate,
                              "enddate"      => security.enddate)
  end

  function serialize(tradebars::Vector{TradeBar})
    arr = []
    for tb in tradebars
      push!(arr, Dict{String, Any}("datetime" => tb.datetime,
                                    "open"    => tb.open,
                                    "high"    => tb.high,
                                    "low"     => tb.low,
                                    "close"   => tb.close,
                                    "volume"  => tb.volume))
    end
    return arr
  end

  function serialize(adj::Adjustment)
    return Dict{String, Any}("close"              => adj.close,
                              "adjustmenttype"    => adj.adjustmenttype,
                              "adjustmentfactor"  => adj.adjustmentfactor)
  end

  temp = Dict{String, Any}("object"       => "universe",
                            "securities"    => Dict{String, Any}(),
                            "tradebars"   => Dict{String, Any}(),
                            "adjustments" => Dict{String, Any}())
  for (symbol, security) in universe.securities
    temp["securities"][symbol.ticker] = serialize(security)
  end
  for (symbol, vec) in universe.tradebars
    temp["tradebars"][symbol.ticker] = serialize(vec)
  end
  for (symbol, adj) in universe.adjustments
    temp["adjustments"][symbol.ticker] = serialize(adj)
  end

  return temp
end

function serialize(tradeenv::TradingEnvironment)
  return Dict{String, Any}("object"               => "tradeenv",
                            "startdate"           => tradeenv.startdate,
                            "enddate"             => tradeenv.enddate,
                            "currentdate"         => tradeenv.currentdate,
                            "livemode"            => tradeenv.livemode,
                            "benchmark"           => tradeenv.benchmark.ticker,
                            "resolution"          => string(tradeenv.resolution),
                            "rebalance"           => string(tradeenv.rebalance),
                            "investmentplan"      => string(tradeenv.investmentplan),
                            "fullrun"             => tradeenv.fullrun,
                            "defaultsecuritytype" => string(tradeenv.defaultsecuritytype),
                            "defaultmarket"       => tradeenv.defaultmarket,
                            "benchmarkvalues"     => tradeenv.benchmarkvalues)
end

function serialize(brokerage::BacktestBrokerage)
  function serialize(blotter::Blotter)
    temp = Dict{String, Any}()
    for (symbol, orders) in blotter.openorders
      temp[symbol.ticker] = [serialize(order) for order in orders]
    end
    return Dict{String, Any}("object"         => "blotter",
                              "openorders"    => temp,
                              "ordertracker"  => serialize(blotter.ordertracker))
  end

  function serialize(commission::Commission)
    return Dict{String, Any}("object" => "commission",
                              "model" => string(commission.model),
                              "value" => commission.value)
  end

  function serialize(margin::Margin)
    return Dict{String, Any}("object"             => "margin",
                              "initialmargin"     => margin.initialmargin,
                              "maintenancemargin" => margin.maintenancemargin)
  end

  function serialize(slippage::Slippage)
    return Dict{String, Any}("object" => "slippage",
                              "model" => string(slippage.model),
                              "value" => slippage.value)
  end

  temp = Dict{String, Any}("object"             => "backtestbrokerage",
                            # "blotter"           => serialize(brokerage.blotter),
                            "commission"        => serialize(brokerage.commission),
                            "margin"            => serialize(brokerage.margin),
                            "slippage"          => serialize(brokerage.slippage),
                            "cancelpolicy"      => string(brokerage.cancelpolicy),
                            "participationrate" => brokerage.participationrate)

  return temp
end

function serialize(accounttracker::AccountTracker)
  temp = Dict{String, Any}("object" => "accounttracker")
  for (date, account) in accounttracker
    temp[string(date)] = serialize(account)
  end
  return temp
end

function serialize(cashtracker::CashTracker)
  temp = Dict{String, Any}("object" => "cashtracker")
  for (date, cash) in cashtracker
    temp[string(date)] = cash
  end
  return temp
end

function serialize(performancetracker::PerformanceTracker, benchmarkPerformance::Bool = false)
  if !benchmarkPerformance
    temp = Dict{String, Any}("object" => "performancetracker")
  else
    temp = Dict{String, Any}("object" => "benchmarktracker")
  end
  for (date, perf) in performancetracker
    temp[string(date)] = serialize(perf)
  end
  return temp
end

function serialize(transactiontracker::TransactionTracker)
  temp = Dict{String, Any}("object" => "transactiontracker")
  for (date, orderfills) in transactiontracker
    temp[string(date)] = [serialize(orderfill) for orderfill in orderfills]
  end
  return temp
end

function serialize(ordertracker::OrderTracker)
  temp = Dict{String, Any}("object" => "ordertracker")
  for (date, orders) in ordertracker
    temp[string(date)] = [serialize(order) for order in orders]
  end
  return temp
end

function serialize(variabletracker::VariableTracker)
  temp = Dict{String, Any}("object" => "variabletracker")
  for (date, var) in variabletracker
    temp[string(date)] = var
  end
  return temp
end

function serialize(as::AlgorithmState)
  return Dict{String, Any}("object"       => "algorithmstate",
                            "account"     => serialize(as.account),
                            "portfolio"   => serialize(as.portfolio),
                            "performance" => serialize(as.performance),
                            "params"      => as.params)
end

function serializeData(algorithm::Algorithm; UID::String = "anonymous", backtestID::String = "backtest0")
  serializeClient = MongoClient()
  serializeCollection = MongoCollection(serializeClient, UID, backtestID)

  insert(serializeCollection, serialize(algorithm))
  insert(serializeCollection, serialize(algorithm.account))
  insert(serializeCollection, serialize(algorithm.universe))
  insert(serializeCollection, serialize(algorithm.portfolio))
  insert(serializeCollection, serialize(algorithm.tradeenv))
  insert(serializeCollection, serialize(algorithm.brokerage))
  insert(serializeCollection, serialize(algorithm.accounttracker))
  insert(serializeCollection, serialize(algorithm.cashtracker))
  insert(serializeCollection, serialize(algorithm.performancetracker))
  insert(serializeCollection, serialize(algorithm.benchmarktracker, true))
  insert(serializeCollection, serialize(algorithm.transactiontracker))
  insert(serializeCollection, serialize(algorithm.ordertracker))
  insert(serializeCollection, serialize(algorithm.variabletracker))
  insert(serializeCollection, serialize(algorithm.state))
end

## AUXILLARY SAVE FUNCTIONS

function serialize(order::Order)
  return Dict{String, Any}("object" => "order",
                            "id" => order.id,
                            "securitysymbol" => order.securitysymbol.ticker,
                            "quantity" => order.quantity,
                            "remainingquantity" => order.remainingquantity,
                            "price" => order.price,
                            "ordertype" => string(order.ordertype),
                            "datetime" => order.datetime,
                            "orderstatus" => string(order.orderstatus),
                            "stopprice" => order.stopprice,
                            "stopReached" => order.stopReached,
                            "tag" => order.tag)
end

function serialize(orderfill::OrderFill)
  return Dict{String, Any}("object" => "orderfill",
                            "orderid" => orderfill.orderid,
                            "securitysymbol" => orderfill.securitysymbol.ticker,
                            "datetime" => orderfill.datetime,
                            "orderfee" => orderfill.orderfee,
                            "fillprice" => orderfill.fillprice,
                            "fillquantity" => orderfill.fillquantity,
                            "message" => orderfill.message)
end

function serialize(performance::Performance)
  function serialize(dw::Drawdown)
    return Dict{String, Any}("currentdrawdown" => dw.currentdrawdown,
                              "maxdrawdown" => dw.maxdrawdown)
  end

  function serialize(dv::Deviation)
    return Dict{String, Any}("annualstandarddeviation" => dv.annualstandarddeviation,
                              "annualvariance" => dv.annualvariance,
                              "annualsemideviation" => dv.annualsemideviation,
                              "annualsemivariance" => dv.annualsemivariance,
                              "squareddailyreturn" => dv.squareddailyreturn,
                              "sumsquareddailyreturn" => dv.sumsquareddailyreturn,
                              "sumdailyreturn" => dv.sumdailyreturn)
  end

  function serialize(rt::Ratios)
    return Dict{String, Any}("sharperatio" => rt.sharperatio,
                              "informationratio" => rt.informationratio,
                              "calmarratio" => rt.calmarratio,
                              "sortinoratio" => rt.sortinoratio,
                              "treynorratio" => rt.treynorratio,
                              "beta" => rt.beta,
                              "alpha" => rt.alpha,
                              "stability" => rt.stability)
  end

  function serialize(rs::Returns)
    return Dict{String, Any}("dailyreturn" => rs.dailyreturn,
                              "dailyreturn_benchmark" => rs.dailyreturn_benchmark,
                              "averagedailyreturn" => rs.averagedailyreturn,
                              "annualreturn" => rs.annualreturn,
                              "totalreturn" => rs.totalreturn,
                              "peaktotalreturn" => rs.peaktotalreturn)
  end

  function serialize(ps::PortfolioStats)
    return Dict{String, Any}("netvalue" => ps.netvalue,
                              "leverage" => ps.leverage,
                              "concentration" => ps.concentration)
  end

  return Dict{String, Any}("object" => "performance",
                            "period" => performance.period,
                            "returns" => serialize(performance.returns),
                            "deviation" => serialize(performance.deviation),
                            "ratios" => serialize(performance.ratios),
                            "drawdown" => serialize(performance.drawdown),
                            "portfoliostats" => serialize(performance.portfoliostats))
end
