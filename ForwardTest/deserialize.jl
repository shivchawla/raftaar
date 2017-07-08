using Mongo
using LibBSON

t2s = Dict{String, SecuritySymbol}() # ticker to symbol list

function deserialize!(algorithm::Algorithm, data::BSONObject)
  algorithm.name = data["name"]
  algorithm.algorithmid   = data["id"]
  algorithm.status = eval(parse(data["status"]))
end

function deserialize!(account::Account, data::BSONObject)
  account.seedcash = data["seedcash"]
  account.cash     = data["cash"]
  account.netvalue = data["netvalue"]
  account.leverage = data["leverage"]
end

function deserialize!(portfolio::Portfolio, data::BSONObject)
  function deserialize!(metrics::PortfolioMetrics, data::BSONObject)
    metrics.netexposure   = data["netexposure"]
    metrics.grossexposure = data["grossexposure"]
    metrics.shortexposure = data["shortexposure"]
    metrics.longexposure  = data["longexposure"]
    metrics.shortcount    = data["shortcount"]
    metrics.longcount     = data["longcount"]
  end

  function deserialize!(positions::Dict{SecuritySymbol, Position}, ticker::String, data::BSONObject)
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
  deserialize!(portfolio.metrics, data["metrics"])
  for (ticker, posData) in data["positions"]
    deserialize!(portfolio.positions, ticker, posData)
  end
end

function deserialize!(universe::Universe, data::BSONObject)
  function deserialize!(securities::Dict{SecuritySymbol, Security}, ticker::String, data::BSONObject)
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

  function deserialize!(tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, ticker::String, data::BSONArray)
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

  function deserialize!(adjustments::Dict{SecuritySymbol, Adjustment}, ticker::String, data::BSONObject)
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
    deserialize!(universe.securities, ticker, securityData)
  end

  for (ticker, tradebarData) in data["tradebars"]
    deserialize!(universe.tradebars, ticker, tradebarData)
  end

  for (ticker, adjData) in data["adjustments"]
    deserialize!(universe.adjustments, ticker, adjData)
  end
end

function deserialize!(tradeenv::TradingEnvironment, data::BSONObject)
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

function deserialize!(brokerage::BacktestBrokerage, data::BSONObject)
  function deserialize!(blotter::Blotter, data::BSONObject)
    deserialize!(blotter.ordertracker, data["ordertracker"])

    blotter.openorders[t2s[ticker]] = Vector{Order}()
    for (ticker, orders) in data["openorders"]
      for order in orders
        temp = Order()
        deserialize!(temp, order)
        push!(blotter.openorders[t2s[ticker]], temp)
      end
    end
  end

  function deserialize!(commission::Commission, data::BSONObject)
    commission.model = eval(parse(data["model"]))
    commission.value = data["value"]
  end

  function deserialize!(margin::Margin, data::BSONObject)
    margin.initialmargin = data["initialmargin"]
    margin.maintenancemargin = data["maintenancemargin"]
  end

  function deserialize!(slippage::Slippage, data::BSONObject)
    slippage.model = eval(parse(data["model"]))
    slippage.value = data["value"]
  end

  # deserialize!(brokerage.blotter, data["blotter"])
  deserialize!(brokerage.commission, data["commission"])
  deserialize!(brokerage.margin, data["margin"])
  deserialize!(brokerage.slippage, data["slippage"])
  brokerage.cancelpolicy = eval(parse(data["cancelpolicy"]))
  brokerage.participationrate = data["participationrate"]
end

function deserialize!(accounttracker::AccountTracker, data::BSONObject)
  for (date, account) in data
    if date!="object" && date!="_id"
      accounttracker[myDate(date)] = Account()
      deserialize!(accounttracker[myDate(date)], account)
    end
  end
end

function deserialize!(cashtracker::CashTracker, data::BSONObject)
  for (date, cash) in cashtracker
    if date!="object" && date!="_id"
      cashtracker[myDate(date)] = cash
    end
  end
end

function deserialize!(performancetracker::PerformanceTracker, data::BSONObject)
  # The same function definition works for benchmarktracker too
  for (date, perfData) in data
    if date!="object" && date!="_id"
      performancetracker[myDate(date)] = Performance()
      deserialize!(performancetracker[myDate(date)], perfData)
    end
  end
end

function deserialize!(transactiontracker::TransactionTracker, data::BSONObject)
  for (date, fills) in data
    if date=="object" || date=="_id"; continue; end
    transactiontracker[myDate(date)] = Vector{OrderFill}()
    for fillData in fills
      temp = OrderFill()
      deserialize!(temp, fillData)
      push!(transactiontracker[myDate(date)], temp)
    end
  end
end

function deserialize!(ordertracker::OrderTracker, data::BSONObject)
  for (date, orders) in data
    if date=="object" || date=="_id"; continue; end
    ordertracker[myDate(date)] = Vector{Order}()
    for orderData in orders
      temp = Order()
      deserialize!(temp, orderData)
      push!(ordertracker[myDate(date)], temp)
    end
  end
end

function deserialize!(variabletracker::VariableTracker, data::BSONObject)
  for (date, varData) in data
    if date=="object" || date=="_id"; continue; end
    variabletracker[myDate(date)] = Dict{String, Float64}()
    for (str, flt) in varData
      variabletracker[myDate(date)][str] = flt
    end
  end
end

function deserialize!(state::AlgorithmState, data::BSONObject)
  deserialize!(state.account, data["account"])
  deserialize!(state.portfolio, data["portfolio"])
  deserialize!(state.performance, data["performance"])
  for (str, dat) in data["params"]
    state.params[str] = dat
  end
end

function deserializeData!(algorithm::Algorithm; UID::String = "anonymous", backtestID::String = "backtest0")
  deserializeClient = MongoClient()
  deserializeCollection = MongoCollection(deserializeClient, UID, backtestID)

  deserialize!(algorithm, first(find(deserializeCollection, Dict("object" => "algorithm"))))
  deserialize!(algorithm.account, first(find(deserializeCollection, Dict("object" => "account"))))
  deserialize!(algorithm.universe, first(find(deserializeCollection, Dict("object" => "universe"))))
  deserialize!(algorithm.portfolio, first(find(deserializeCollection, Dict("object" => "portfolio"))))
  deserialize!(algorithm.tradeenv, first(find(deserializeCollection, Dict("object" => "tradeenv"))))
  deserialize!(algorithm.brokerage, first(find(deserializeCollection, Dict("object" => "backtestbrokerage"))))
  deserialize!(algorithm.accounttracker, first(find(deserializeCollection, Dict("object" => "accounttracker"))))
  deserialize!(algorithm.cashtracker, first(find(deserializeCollection, Dict("object" => "cashtracker"))))
  deserialize!(algorithm.performancetracker, first(find(deserializeCollection, Dict("object" => "performancetracker"))))
  deserialize!(algorithm.benchmarktracker, first(find(deserializeCollection, Dict("object" => "benchmarktracker"))))
  deserialize!(algorithm.transactiontracker, first(find(deserializeCollection, Dict("object" => "transactiontracker"))))
  deserialize!(algorithm.ordertracker, first(find(deserializeCollection, Dict("object" => "ordertracker"))))
  deserialize!(algorithm.variabletracker, first(find(deserializeCollection, Dict("object" => "variabletracker"))))
  deserialize!(algorithm.state, first(find(deserializeCollection, Dict("object" => "algorithmstate"))))

end

## AUXILLARY LOAD FUNCTIONS

function deserialize!(order::Order, data::BSONObject)
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

function deserialize!(orderfill::OrderFill, data::BSONObject)
  orderfill.orderid = data["orderid"]
	orderfill.securitysymbol = t2s[data["securitysymbol"]]
	orderfill.datetime = data["datetime"]
	orderfill.orderfee = data["orderfee"]
	orderfill.fillprice = data["fillprice"]
	orderfill.fillquantity = data["fillquantity"]
	orderfill.message = data["message"]
end

function deserialize!(performance::Performance, data::BSONObject)
  function deserialize!(dw::Drawdown, data::BSONObject)
    dw.currentdrawdown = data["currentdrawdown"]
    dw.maxdrawdown = data["maxdrawdown"]
  end

  function deserialize!(dv::Deviation, data::BSONObject)
    dv.annualstandarddeviation = data["annualstandarddeviation"]
    dv.annualvariance = data["annualvariance"]
    dv.annualsemideviation = data["annualsemideviation"]
    dv.annualsemivariance = data["annualsemivariance"]
    dv.squareddailyreturn = data["squareddailyreturn"]
    dv.sumsquareddailyreturn = data["sumsquareddailyreturn"]
    dv.sumdailyreturn = data["sumdailyreturn"]
  end

  function deserialize!(rt::Ratios, data::BSONObject)
    rt.sharperatio = data["sharperatio"]
    rt.informationratio = data["informationratio"]
    rt.calmarratio = data["calmarratio"]
    rt.sortinoratio = data["sortinoratio"]
    rt.treynorratio = data["treynorratio"]
    rt.beta = data["beta"]
    rt.alpha = data["alpha"]
    rt.stability = data["stability"]
  end

  function deserialize!(rs::Returns, data::BSONObject)
    rs.dailyreturn = data["dailyreturn"]
    rs.dailyreturn_benchmark = data["dailyreturn_benchmark"]
    rs.averagedailyreturn = data["averagedailyreturn"]
    rs.annualreturn = data["annualreturn"]
    rs.totalreturn = data["totalreturn"]
    rs.peaktotalreturn = data["peaktotalreturn"]
  end

  function deserialize!(ps::PortfolioStats, data::BSONObject)
    ps.netvalue = data["netvalue"]
    ps.leverage = data["leverage"]
    ps.concentration = data["concentration"]
  end

  performance.period = data["period"]
  deserialize!(performance.returns, data["returns"])
  deserialize!(performance.deviation, data["deviation"])
  deserialize!(performance.ratios, data["ratios"])
  deserialize!(performance.drawdown, data["drawdown"])
  deserialize!(performance.portfoliostats, data["portfoliostats"])
end

function myDate(s::String)
  return Date(map(x->parse(Int64, x), split(s, "-"))...)
end

function myDate(s::Date)
  return s
end
