	
include("../Algorithm/Algorithm.jl")
include("../Data/History.jl")
include("../Execution/Commission.jl")
include("../Execution/Slippage.jl")


const algorithm = Algorithm()

export setstartdate, 
		setenddate	

# Algorithm settings API 
function setresolution(resolution::Resolution)
	setresolution!(algorithm.tradeenv, resolution)
end

function setstartdate(datetime::DateTime)
	setstartdate!(algorithm.tradeenv, datetime)
end

function setenddate(datetime::DateTime)
	setenddate!(algorithm.tradeenv, datetime)
end

function _setcurrentdatetime(datetime::DateTime)
	setcurrentdatetime!(algorithm.tradeenv, datetime) 
end

function getstartdate()
	algorithm.tradeenv.startdate
end

function getenddate()
	algorithm.tradeenv.enddate
end

function getcurrentdatetime()
	algorithm.tradeenv.currentdatetime
end

#Universe API
function adduniverse(ticker::ASCIIString, securitytype::SecurityType = SecurityType(InValid))
	if (securitytype == SecurityType(InValid))
		securitytype = algorithm.tradeenv.defaultsecuritytype
	end
	adduniverse!(algorithm.universe, ticker, securitytype)
end

function adduniverse(tickers::Vector{ASCIIString}, securitytype::SecurityType = SecurityType(InValid))
	for ticker in tickers
		adduniverse(ticker, securitytype)
	end
end

function setuniverse(ticker::ASCIIString, securitytype::SecurityType = SecurityType(InValid))
	if (securitytype == SecurityType(InValid))
		securitytype = algorithm.tradeenv.defaultsecuritytype
	end
	setuniverse!(algorithm.universe, ticker, securitytype)
end

function setuniverse(tickers::Vector{ASCIIString}, securitytype::SecurityType = SecurityType(InValid))
	if (securitytype == SecurityType(InValid))
		securitytype = algorithm.tradeenv.defaultsecuritytype
	end

	setuniverse!(algorithm.universe, tickers, securitytype)
end

function getuniverse()	#return array of security symbol
	values(algorithm.universe.securities)
end

function cantrade(ticker::ASCIIString)
	cantrade(symbol, algorithm.tradeenv.defaultsecuritytype, algorithm.tradeenv.datetime)
end	

function cantrade(symbol::SecuritySymbol)
	cantrade(symbol, algorithm.tradeenv.datetime)
end	

function cantrade(security::Security)
	cantrade(security, algorithm.tradeenv.datetime)
end	

#Account API
function setcash(cash::Float64)
	setcash!(algorithm.account, cash)
end

function getposition(ticker::ASCIIString)
	getposition(algorithm.account.portfolio, ticker)
end

function getposition(symbol::SecuritySymbol)
	getposition(algorithm.account.portfolio, symbol)
end

function getposition(security::Security)
	getposition(algorithm.account.portfolio, security)
end

function getportfolio()
	algorithm.account.portfolio
end

function getportfoliovalue()
	getportfoliovalue(algorithm.account)
end

# Brokerage API functions
function setcancelpolicy(cancelpolicy::CancelPolicy)
	setcancelpolicy!(algorithm.brokerage, CancelPolicy(EOD))
end

function setcommission(commission::Commission)
	setcommission!(algorithm.brokerage, commission)
end

function setslippage(slippage::Slippage)
	setslippage!(algorithm.brokerage, slippage)
end

function setparticipationrate(participationrate::Float64)
	setparticipationrate!(algorithm.brokerage, participationrate)
end

function liquidate(symbol::ASCIIString)
	setholdingpct(symbol, 0.0)
end 

function placeorder(security::Security, quantity::Int64)
	placeorder(security.symbol, quantity)
end	

function placeorder(symbol::SecuritySymbol, quantity::Int64)
	placeorder(Order(symbol, quantity))
end

function placeorder(order::Order)
	if !algorithm.tradeenv.livemode
		order.datetime = getcurrentdatetime()
	else 
		order.datetime = now()
	end

	placeorder(algorithm.brokerage, order)	
end

function liquidate(symbol::ASCIIString)
	setholdingshares(symbol, 0)  
end

function liquidateportfolio()
end

#Order function to set holdings to a specific level in pct/value/shares
function setholdingpct(symbol::ASCIIString, target::Float64)
	#get current position
end

function setholdingvalue(symbol::ASCIIString, target::Float64)
	#get current position
end

function setholdingshares(symbol::ASCIIString, target::Int64)
	#get current hares
end

function hedgeportfolio()
end

function getopenorders()
	getopenorders(algorithm.brokerage)
end

function cancelallorders!(symbol::SecuritySymbol)
	cancelallorders(algorithm.brokerage, symbol)
end

function cancelallorders!()
	cancelallorders(algorithm.brokerage)	
end

function _updatependingorders(datetime::DateTime)
	updatependingorders!(algorithm.brokerage, algorithm.universe)
end

function _updateportfolioforfills(fills::Vector{OrderFill})
	cash = updateportfolioforfills!(algorithm.account.portfolio, fills)
	updateportfoliometrics!(algorithm.account, cash)
end	

function _updateportfolioforprice(datetime::DateTime)
	updateportfolioforprice!(algorithm.account.portfolio, algorithm.universe.tradebars, datetime)
	updateportfoliometrics!(algorithm.account)
end

function _updateprices(tradebars::Dict{SecuritySymbol, Vector{TradeBar}})
	updateprices!(algorithm.universe, tradebars)
end	





