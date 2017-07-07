using Mongo
using LibBSON

t2s = Dict{String, SecuritySymbol}() # ticker to symbol list

function loadAlgorithm(algorithm::Algorithm, data::BSONObject)
  algorithm.name = data["name"]
  algorithm.algorithmid   = data["id"]
  algorithm.status = eval(parse(data["status"]))
end

function loadAccount(account::Account, data::BSONObject)
  account.seedcash = data["seedcash"]
  account.cash     = data["cash"]
  account.netvalue = data["netvalue"]
  account.leverage = data["leverage"]
end

function loadPortfolio(portfolio::Portfolio, data::BSONObject)
  function loadPortfolioMetrics(metrics::PortfolioMetrics, data::BSONObject)
    metrics.netexposure   = data["netexposure"]
    metrics.grossexposure = data["grossexposure"]
    metrics.shortexposure = data["shortexposure"]
    metrics.longexposure  = data["longexposure"]
    metrics.shortcount    = data["shortcount"]
    metrics.longcount     = data["longcount"]
  end

  function loadPosition(positions::Dict{SecuritySymbol, Position}, ticker::String, data::BSONObject)
    symbol    = t2s[ticker]
    position  = Position()

    position.securitysymbol     = symbol
    position.quantity           = data["quantity"]
    position.averageprice       = data["averageprice"]
    position.totalfees          = data["totalfees"]
    position.lastprice          = data["lastprice"]
    position.lasttradepnl       = data["lasttradepnl"]
    position.realizedpnl        = data["realizedpnl"]
    position.totaltradedvolume  = data["totaltradedvolume"]

    positions[symbol] = position
  end

  portfolio.positions = Dict{SecuritySymbol, Position}()
  loadPortfolioMetrics(portfolio.metrics, data["metrics"])
  for (ticker, posData) in data["positions"]
    loadPosition(portfolio.positions, ticker, posData)
  end
end

function loadUniverse(universe::Universe, data::BSONObject)
  function loadSecurity(securities::Dict{SecuritySymbol, Security}, ticker::String, data::BSONObject)
    security = Security()
    security.symbol.ticker = data["symbol"]
    security.symbol.id = data["id"]
    security.name = data["name"]
    security.exchange = data["exchange"]
    security.country = data["country"]
    security.securitytype = data["securitytype"]
    security.startdate = data["startdate"]
    security.enddate = data["enddate"]

    securities[security.symbol] = security
    t2s[ticker] = security.symbol
  end

  function loadTradebar(tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, ticker::String, data::BSONArray)
    symbol = t2s[ticker]
    tradebars[symbol] = Vector{TradeBar}()

    for tbData in data
      tradebar = TradeBar(tbData["datetime"],
                          tbData["open"],
                          tbData["high"],
                          tbData["low"],
                          tbData["close"],
                          tbData["volume"])
      push!(tradebars[symbol], tradebar)
    end
  end

  function loadAdjustments(adjustments::Dict{SecuritySymbol, Adjustment}, ticker::String, data::BSONObject)
    adj = Adjustment()
    adj.close = data["close"]
    adj.adjustmenttype = data["adjustmenttype"]
    adj.adjustmentfactor = data["adjustmentfactor"]

    symbol = t2s[ticker]
    adjustments[symbol] = adj
  end

  universe.securities = Dict()
  universe.tradebars = Dict()
  universe.adjustments = Dict()

  for (ticker, securityData) in data["securities"]
    loadSecurity(universe.securities, ticker, securityData)
  end

  for (ticker, tradebarData) in data["tradebars"]
    loadTradebar(universe.tradebars, ticker, tradebarData)
  end

  for (ticker, adjData) in data["adjustments"]
    loadAdjustments(universe.adjustments, ticker, adjData)
  end
end

function loadTradeEnv(tradeenv::TradingEnvironment, data::BSONObject)
  tradeenv.startdate = data["startdate"]
  tradeenv.enddate = data["enddate"]
  tradeenv.currentdate = data["currentdate"]
  tradeenv.livemode = data["livemode"]
  tradeenv.benchmark.ticker = data["benchmark"]
  tradeenv.resolution = eval(parse(data["resolution"]))
  tradeenv.rebalance = eval(parse(data["rebalance"]))
  tradeenv.investmentplan = eval(parse(data["investmentplan"]))
  tradeenv.fullrun = data["fullrun"]
  tradeenv.defaultsecuritytype = eval(parse(data["defaultsecuritytype"]))
  tradeenv.defaultmarket = data["defaultmarket"]
  for (date, value) in data["benchmarkvalues"]
    tradeenv.benchmarkvalues[date] = value
  end
end

function loadBrokerage(brokerage::BacktestBrokerage, data::BSONObject)
  function loadBlotter(blotter::Blotter, data::BSONObject)
    loadOrderTracker(blotter.ordertracker, data["ordertracker"])

    blotter.openorders[t2s[ticker]] = Vector{Order}()
    for (ticker, orders) in data["openorders"]
      for order in orders
        temp = Order()
        loadOrder(temp, order)
        push!(blotter.openorders[t2s[ticker]], temp)
      end
    end
  end

  function loadCommission(commission::Commission, data::BSONObject)
    commission.model = eval(parse(data["model"]))
    commission.value = data["value"]
  end

  function loadMargin(margin::Margin, data::BSONObject)
    margin.initialmargin = data["initialmargin"]
    margin.maintenancemargin = data["maintenancemargin"]
  end

  function loadSlippage(slippage::Slippage, data::BSONObject)
    slippage.model = eval(parse(data["model"]))
    slippage.value = data["value"]
  end

  # loadBlotter(brokerage.blotter, data["blotter"])
  loadCommission(brokerage.commission, data["commission"])
  loadMargin(brokerage.margin, data["margin"])
  loadSlippage(brokerage.slippage, data["slippage"])
  brokerage.cancelpolicy = eval(parse(data["cancelpolicy"]))
  brokerage.participationrate = data["participationrate"]
end

function loadAccountTracker(accounttracker::AccountTracker, data::BSONObject)
  for (date, account) in data
    if date!="object" && date!="_id"
      accounttracker[myDate(date)] = Account()
      loadAccount(accounttracker[myDate(date)], account)
    end
  end
end

function loadCashTracker(cashtracker::CashTracker, data::BSONObject)
  for (date, cash) in cashtracker
    if date!="object" && date!="_id"
      cashtracker[myDate(date)] = cash
    end
  end
end

function loadPerformanceTracker(performancetracker::PerformanceTracker, data::BSONObject)
  for (date, perfData) in data
    if date!="object" && date!="_id"
      performancetracker[myDate(date)] = Performance()
      loadPerformance(performancetracker[myDate(date)], perfData)
    end
  end
end

function loadBenchmarkTracker(benchmarktracker::PerformanceTracker, data::BSONObject)
  for (date, benchData) in data
    if date!="object" && date!="_id"
      benchmarktracker[myDate(date)] = Performance()
      loadPerformance(benchmarktracker[myDate(date)], benchData)
    end
  end
end

function loadTransactionTracker(transactiontracker::TransactionTracker, data::BSONObject)
  for (date, fillData) in data
    if date!="object" && date!="_id"
      transactiontracker[myDate(date)] = Vector{OrderFill}()
      loadOrderFill(transactiontracker[myDate(date)], fillData)
    end
  end
end

function loadOrderTracker(ordertracker::OrderTracker, data::BSONObject)
  for (date, orderData) in data
    if date!="object" && date!="_id"
      ordertracker[myDate(date)] = Vector{Order}()
      loadOrder(ordertracker[myDate(date)], orderData)
    end
  end
end

function loadVariableTracker(variabletracker::VariableTracker, data::BSONObject)
  for (date, varData) in data
    if date=="object" || date=="_id"; continue; end
    variabletracker[myDate(date)] = Dict{String, Float64}()
    for (str, flt) in varData
      variabletracker[myDate(date)][str] = flt
    end
  end
end

function loadAlgorithmState(state::AlgorithmState, data::BSONObject)
  loadAccount(state.account, data["account"])
  loadPortfolio(state.portfolio, data["portfolio"])
  loadPerformance(state.performance, data["performance"])
  for (str, dat) in data["params"]
    state.params[str] = dat
  end
end

function loadProgress!(algorithm::Algorithm; UID::String = "anonymous", backtestID::String = "backtest0")
  loadProgressClient = MongoClient()
  loadProgressCollection = MongoCollection(loadProgressClient, UID, backtestID)

  loadAlgorithm(algorithm, first(find(loadProgressCollection, Dict("object" => "algorithm"))))
  loadAccount(algorithm.account, first(find(loadProgressCollection, Dict("object" => "account"))))
  loadUniverse(algorithm.universe, first(find(loadProgressCollection, Dict("object" => "universe"))))
  loadPortfolio(algorithm.portfolio, first(find(loadProgressCollection, Dict("object" => "portfolio"))))
  loadTradeEnv(algorithm.tradeenv, first(find(loadProgressCollection, Dict("object" => "tradeenv"))))
  loadBrokerage(algorithm.brokerage, first(find(loadProgressCollection, Dict("object" => "backtestbrokerage"))))
  loadAccountTracker(algorithm.accounttracker, first(find(loadProgressCollection, Dict("object" => "accounttracker"))))
  loadCashTracker(algorithm.cashtracker, first(find(loadProgressCollection, Dict("object" => "cashtracker"))))
  loadPerformanceTracker(algorithm.performancetracker, first(find(loadProgressCollection, Dict("object" => "performancetracker"))))
  loadBenchmarkTracker(algorithm.benchmarktracker, first(find(loadProgressCollection, Dict("object" => "benchmarktracker"))))
  loadTransactionTracker(algorithm.transactiontracker, first(find(loadProgressCollection, Dict("object" => "transactiontracker"))))
  loadOrderTracker(algorithm.ordertracker, first(find(loadProgressCollection, Dict("object" => "ordertracker"))))
  loadVariableTracker(algorithm.variabletracker, first(find(loadProgressCollection, Dict("object" => "variabletracker"))))
  loadAlgorithmState(algorithm.state, first(find(loadProgressCollection, Dict("object" => "algorithmstate"))))

end

## AUXILLARY LOAD FUNCTIONS

function loadOrder(order::Order, data::BSONObject)
  order.id = data["id"]
  order.securitysymbol = t2s[data["securitysymbol"]]
  order.quantity = data["quantity"]
  order.remainingquantity = data["remainingquantity"]
  order.price = data["price"]
  order.ordertype = eval(parse(data["ordertype"]))
  order.datetime = data["datetime"]
  order.orderstatus = eval(parse(data["orderstatus"]))
  order.stopprice = data["stopprice"]
  order.stopReached = data["stopReached"]
  order.tag = data["tag"]
end

function loadOrderFill(orderfill::OrderFill, data::BSONObject)
  orderfill.orderid = data["orderid"]
	orderfill.securitysymbol = t2s[data["securitysymbol"]]
	orderfill.datetime = data["datetime"]
	orderfill.orderfee = data["orderfee"]
	orderfill.fillprice = data["fillprice"]
	orderfill.fillquantity = data["fillquantity"]
	orderfill.message = data["message"]
end

function loadPerformance(performance::Performance, data::BSONObject)
  function loadDrawdown(dw::Drawdown, data::BSONObject)
    dw.currentdrawdown = data["currentdrawdown"]
    dw.maxdrawdown = data["maxdrawdown"]
  end

  function loadDeviation(dv::Deviation, data::BSONObject)
    dv.annualstandarddeviation = data["annualstandarddeviation"]
    dv.annualvariance = data["annualvariance"]
    dv.annualsemideviation = data["annualsemideviation"]
    dv.annualsemivariance = data["annualsemivariance"]
    dv.squareddailyreturn = data["squareddailyreturn"]
    dv.sumsquareddailyreturn = data["sumsquareddailyreturn"]
    dv.sumdailyreturn = data["sumdailyreturn"]
  end

  function loadRatios(rt::Ratios, data::BSONObject)
    rt.sharperatio = data["sharperatio"]
    rt.informationratio = data["informationratio"]
    rt.calmarratio = data["calmarratio"]
    rt.sortinoratio = data["sortinoratio"]
    rt.treynorratio = data["treynorratio"]
    rt.beta = data["beta"]
    rt.alpha = data["alpha"]
    rt.stability = data["stability"]
  end

  function loadReturns(rs::Returns, data::BSONObject)
    rs.dailyreturn = data["dailyreturn"]
    rs.dailyreturn_benchmark = data["dailyreturn_benchmark"]
    rs.averagedailyreturn = data["averagedailyreturn"]
    rs.annualreturn = data["annualreturn"]
    rs.totalreturn = data["totalreturn"]
    rs.peaktotalreturn = data["peaktotalreturn"]
  end

  function loadPortfolioStats(ps::PortfolioStats, data::BSONObject)
    ps.netvalue = data["netvalue"]
    ps.leverage = data["leverage"]
    ps.concentration = data["concentration"]
  end

  performance.period = data["period"]
  loadReturns(performance.returns, data["returns"])
  loadDeviation(performance.deviation, data["deviation"])
  loadRatios(performance.ratios, data["ratios"])
  loadDrawdown(performance.drawdown, data["drawdown"])
  loadPortfolioStats(performance.portfoliostats, data["portfoliostats"])
end

function myDate(s::String)
  return Date(map(x->parse(Int64, x), split(s, "-"))...)
end

function myDate(s::Date)
  return s
end
