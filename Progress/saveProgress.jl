using Mongo

function saveAlgorithm(algorithm::Algorithm)
  return Dict{String, Any}("object"   => "algorithm",
                            "name"    => algorithm.name,
                            "id"      => algorithm.algorithmid,
                            "status"  => string(algorithm.status))
end

function saveAccount(account::Account)
  return Dict{String, Any}("object"    => "account",
                            "seedcash" => account.seedcash,
                            "cash"     => account.cash,
                            "netvalue" => account.netvalue,
                            "leverage" => account.leverage)
end

function savePortfolio(portfolio::Portfolio)
  function savePortfolioMetrics(metrics::PortfolioMetrics)
    return Dict{String, Any}("object"         => "portfoliometrics",
                              "netexposure"   => metrics.netexposure,
                              "grossexposure" => metrics.grossexposure,
                              "shortexposure" => metrics.shortexposure,
                              "longexposure"  => metrics.longexposure,
                              "shortcount"    => metrics.shortcount,
                              "longcount"     => metrics.longcount)
  end

  function savePosition(symbol::SecuritySymbol, position::Position)
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
                            "metrics"   => savePortfolioMetrics(portfolio.metrics),
                            "positions" => Dict{String, Any}())
  for symbol in keys(portfolio.positions)
    temp["positions"][symbol.ticker] = savePosition(symbol, portfolio.positions[symbol])
  end

  return temp
end

function saveUniverse(universe::Universe)
  function saveSecurity(security::Security)
    return Dict{String, Any}("symbol"        => security.symbol.ticker,
                              "id"           => security.symbol.id,
                              "name"         => security.name,
                              "exchange"     => security.exchange,
                              "country"      => security.country,
                              "securitytype" => security.securitytype,
                              "startdate"    => security.startdate,
                              "enddate"      => security.enddate)
  end

  function saveTradebar(tradebars::Vector{TradeBar})
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

  function saveAdjustments(adj::Adjustment)
    return Dict{String, Any}("close"              => adj.close,
                              "adjustmenttype"    => adj.adjustmenttype,
                              "adjustmentfactor"  => adj.adjustmentfactor)
  end

  temp = Dict{String, Any}("object"       => "universe",
                            "securities"    => Dict{String, Any}(),
                            "tradebars"   => Dict{String, Any}(),
                            "adjustments" => Dict{String, Any}())
  for (symbol, security) in universe.securities
    temp["security"][symbol.ticker] = saveSecurity(security)
  end
  for (symbol, vec) in universe.tradebars
    temp["tradebars"][symbol.ticker] = saveTradebar(vec)
  end
  for (symbol, adj) in universe.adjustments
    temp["adjustments"][symbol.ticker] = saveAdjustments(adj)
  end

  return temp
end

function saveTradeEnv(tradeenv::TradingEnvironment)
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

function saveBrokerage(brokerage::BacktestBrokerage)
  function saveBlotter(blotter::Blotter)
    temp = Dict{String, Any}()
    for (symbol, orders) in blotter.openorders
      temp[symbol.ticker] = [saveOrder(order) for order in orders]
    end
    return Dict{String, Any}("object"         => "blotter",
                              "openorders"    => temp,
                              "ordertracker"  => saveOrderTracker(blotter.ordertracker))
  end

  function saveCommission(commission::Commission)
    return Dict{String, Any}("object" => "commission",
                              "model" => string(commission.model),
                              "value" => commission.value)
  end

  function saveMargin(margin::Margin)
    return Dict{String, Any}("object"             => "margin",
                              "initialmargin"     => margin.initialmargin,
                              "maintenancemargin" => margin.maintenancemargin)
  end

  function saveSlippage(slippage::Slippage)
    return Dict{String, Any}("object" => "slippage",
                              "model" => string(slippage.model),
                              "value" => slippage.value)
  end

  temp = Dict{String, Any}("object"             => "backtestbrokerage",
                            # "blotter"           => saveBlotter(brokerage.blotter),
                            "commission"        => saveCommission(brokerage.commission),
                            "margin"            => saveMargin(brokerage.margin),
                            "slippage"          => saveSlippage(brokerage.slippage),
                            "cancelpolicy"      => string(brokerage.cancelpolicy),
                            "participationrate" => brokerage.participationrate)

  return temp
end

function saveAccountTracker(accounttracker::AccountTracker)
  temp = Dict{String, Any}("object" => "accounttracker")
  for (date, account) in accounttracker
    temp[string(date)] = saveAccount(account)
  end
  return temp
end

function saveCashTracker(cashtracker::CashTracker)
  temp = Dict{String, Any}("object" => "cashtracker")
  for (date, cash) in cashtracker
    temp[string(date)] = cash
  end
  return temp
end

function savePerformanceTracker(performancetracker::PerformanceTracker)
  temp = Dict{String, Any}("object" => "performancetracker")
  for (date, perf) in performancetracker
    temp[string(date)] = savePerformance(perf)
  end
  return temp
end

function saveBenchmarkTracker(benchmarktracker::PerformanceTracker)
  temp = Dict{String, Any}("object" => "benchmarktracker")
  for (date, perf) in benchmarktracker
    temp[string(date)] = savePerformance(perf)
  end
  return temp
end

function saveTransactionTracker(transactiontracker::TransactionTracker)
  temp = Dict{String, Any}("object" => "transactiontracker")
  for (date, orderfills) in transactiontracker
    temp[string(date)] = [saveOrderFill(orderfill) for orderfill in orderfills]
  end
  return temp
end

function saveOrderTracker(ordertracker::OrderTracker)
  temp = Dict{String, Any}("object" => "ordertracker")
  for (date, orders) in ordertracker
    temp[string(date)] = [saveOrder(order) for order in orders]
  end
  return temp
end

function saveVariableTracker(variabletracker::VariableTracker)
  temp = Dict{String, Any}("object" => "variabletracker")
  for (date, var) in variabletracker
    temp[string(date)] = var
  end
  return temp
end

function saveAlgorithmState(as::AlgorithmState)
  return Dict{String, Any}("object"       => "algorithmstate",
                            "account"     => saveAccount(as.account),
                            "portfolio"   => savePortfolio(as.portfolio),
                            "performance" => savePerformance(as.performance),
                            "params"      => as.params)
end

function saveProgress!(algorithm::Algorithm; UID::String = "anonymous", backtestID::String = "backtest0")
  saveProgressClient = MongoClient()
  saveProgressCollection = MongoCollection(saveProgressClient, UID, backtestID)
  insert(saveProgressCollection, saveAlgorithm(algorithm))
  insert(saveProgressCollection, saveAccount(algorithm.account))
  insert(saveProgressCollection, saveUniverse(algorithm.universe))
  insert(saveProgressCollection, savePortfolio(algorithm.portfolio))
  insert(saveProgressCollection, saveTradeEnv(algorithm.tradeenv))
  insert(saveProgressCollection, saveBrokerage(algorithm.brokerage))
  insert(saveProgressCollection, saveAccountTracker(algorithm.accounttracker))
  insert(saveProgressCollection, saveCashTracker(algorithm.cashtracker))
  insert(saveProgressCollection, savePerformanceTracker(algorithm.performancetracker))
  insert(saveProgressCollection, saveBenchmarkTracker(algorithm.benchmarktracker))
  insert(saveProgressCollection, saveTransactionTracker(algorithm.transactiontracker))
  insert(saveProgressCollection, saveOrderTracker(algorithm.ordertracker))
  insert(saveProgressCollection, saveVariableTracker(algorithm.variabletracker))
  insert(saveProgressCollection, saveAlgorithmState(algorithm.state))
end

## AUXILLARY SAVE FUNCTIONS

function saveOrder(order::Order)
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

function saveOrderFill(orderfill::OrderFill)
  return Dict{String, Any}("object" => "orderfill",
                            "orderid" => orderfill.orderid,
                            "securitysymbol" => orderfill.securitysymbol.ticker,
                            "datetime" => orderfill.datetime,
                            "orderfee" => orderfill.orderfee,
                            "fillprice" => orderfill.fillprice,
                            "fillquantity" => orderfill.fillquantity,
                            "message" => orderfill.message)
end

function savePerformance(performance::Performance)
  function saveDrawdown(dw::Drawdown)
    return Dict{String, Any}("currentdrawdown" => dw.currentdrawdown,
                              "maxdrawdown" => dw.maxdrawdown)
  end

  function saveDeviation(dv::Deviation)
    return Dict{String, Any}("annualstandarddeviation" => dv.annualstandarddeviation,
                              "annualvariance" => dv.annualvariance,
                              "annualsemideviation" => dv.annualsemideviation,
                              "annualsemivariance" => dv.annualsemivariance,
                              "squareddailyreturn" => dv.squareddailyreturn,
                              "sumsquareddailyreturn" => dv.sumsquareddailyreturn,
                              "sumdailyreturn" => dv.sumdailyreturn)
  end

  function saveRatios(rt::Ratios)
    return Dict{String, Any}("sharperatio" => rt.sharperatio,
                              "informationratio" => rt.informationratio,
                              "calmarratio" => rt.calmarratio,
                              "sortinoratio" => rt.sortinoratio,
                              "treynorratio" => rt.treynorratio,
                              "beta" => rt.beta,
                              "alpha" => rt.alpha,
                              "stability" => rt.stability)
  end

  function saveReturns(rs::Returns)
    return Dict{String, Any}("dailyreturn" => rs.dailyreturn,
                              "dailyreturn_benchmark" => rs.dailyreturn_benchmark,
                              "averagedailyreturn" => rs.averagedailyreturn,
                              "annualreturn" => rs.annualreturn,
                              "totalreturn" => rs.totalreturn,
                              "peaktotalreturn" => rs.peaktotalreturn)
  end

  function savePortfolioStats(ps::PortfolioStats)
    return Dict{String, Any}("netvalue" => ps.netvalue,
                              "leverage" => ps.leverage,
                              "concentration" => ps.concentration)
  end

  return Dict{String, Any}("object" => "performance",
                            "period" => performance.period,
                            "returns" => saveReturns(performance.returns),
                            "deviation" => saveDeviation(performance.deviation),
                            "ratios" => saveRatios(performance.ratios),
                            "drawdown" => saveDrawdown(performance.drawdown),
                            "portfoliostats" => savePortfolioStats(performance.portfoliostats))
end
