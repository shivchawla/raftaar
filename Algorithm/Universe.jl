
include("../Security/Security.jl")

@enum Resolution Tick Second Minute Hour Daily
@enum FieldType Open High Low Close Last Volume 

immutable TradeBar
  datetime::DateTime
  open::Float64
  high::Float64
  low::Float64
  close::Float64
  volume::Int64
  #bidPrice::Float64
  #askPrice::Float64
  #bidSize::Int64
  #askSize::Int64
end

TradeBar(datetime::DateTime, open::Float64, high::Float64, low::Float64, close::Float64) = 
				TradeBar(datetime, open, high, low, close, 0)

type Universe 
	securities::Dict{SecuritySymbol, Security}
	tradebars::Dict{SecuritySymbol, Vector{TradeBar}}
end

Universe() = Universe(Dict(), Dict())

getindex(universe::Universe, symbol::SecuritySymbol) = getindex(universe.securities, symbol)
getindex(universe::Universe, security::Security) = get(universe.securities, security.symbol, Security())
setindex!(universe::Universe, security::Security, symbol::SecuritySymbol) = setindex!(universe.securities, security, symbol)

function contains(universe::Universe, symbol::SecuritySymbol) 
	haskey(universe.securities, symbol)
end

function adduniverse1!(universe::Universe, ticker::ASCIIString, securitytype::SecurityType)	
	security = Security(ticker, securitytype)
	adduniverse3!(universe, security)
end

function adduniverse2!(universe::Universe, tickers::Vector{ASCIIString}, securitytype::SecurityType)
	for ticker in tickers
		adduniverse1!(universe, ticker, securitytype)
	end
end

function setuniverse1!(universe::Universe, ticker::ASCIIString, securitytype::SecurityType)
	resetuniverse!(universe)
	adduniverse1!(universe, ticker, securitytype)
end

function setuniverse2!(universe::Universe, tickers::Vector{ASCIIString}, securitytype::SecurityType)
	resetuniverse!(universe)
	adduniverse2!(universe, tickers, securitytype)
end

####################

function adduniverse3!(universe::Universe, security::Security)	
	if !empty(security)
		if !contains(universe, security.symbol)
			universe[security.symbol] = security
		end
	end
end

function adduniverse4!(universe::Universe, securities::Vector{Security})
	for security in securities
		adduniverse3!(universe, security)
	end
end

function setuniverse3!(universe::Universe, security::Security)
	resetuniverse!(universe)
	adduniverse3!(universe, security)
end

function setuniverse4!(universe::Universe, securities::Vector{Security})
	resetuniverse!(universe) 
	adduniverse4!(universe, securities)
end

function getsecurity(universe::Universe, ticker::ASCIIString, securitytype::SecurityType)
	symbol = createsymbol(ticker, securitytype)
	getsecurity(symbol, universe)
end

function getsecurity(universe::Universe, symbol::SecuritySymbol)
	get!(universe, symbol, Security())
end

function removesecurity!(universe::Universe, symbol::SecuritySymbol)
	delete(universe, symbol)
end

function removesecurity!(universe::Universe, ticker::ASCIIString, securitytype::SecurityType)
	symbol = createsymbol(ticker, securitytype)
	removesecurity(symbol, universe)
end

function contains(universe::Universe, ticker::ASCIIString, securitytype::SecurityType)
	contains(universe, createsymbol(ticker, securitytype))
end

function contains(universe::Universe, security::Security)
	contains(universe, security.symbol)
end 

function updateprices!(universe::Universe, newtradebars::Dict{SecuritySymbol, Vector{TradeBar}})
	universe.tradebars = newtradebars 
end	

function getlatestprice(universe::Universe, ticker::ASCIIString, securitytype::SecurityType = SecurityType(Equity), field::FieldType=FieldType(Close))
	ss = createsymbol(ticker, securitytype) 	
	getlatestprice(universe, ss, field)   
end

function getlatestprice(universe::Universe, security::Security, field::FieldType=FieldType(Close))
	getlatestprice(universe, security.symbol, field)   
end

function getlatestprice(universe::Universe, symbol::SecuritySymbol, field::FieldType=FieldType(Close))
    bar = universe.tradebars[symbol]

    if(field==FieldType(Open))
   		return bar.open	
    elseif(field==FieldType(High))
   		return bar.high
	elseif(field==FieldType(Low))
   		return bar.low
   	elseif(field==FieldType(Close))
   		return bar.close
   	elseif(field==FieldType(Volume))
   		return bar.volume
	end
end

function cantrade(universe::Universe, ticker::ASCIIString, datetime::DateTime, securitytype::SecurityType=SecurityType(Equity))
	securitysymbol = createsymbol(ticker, securitytype)
	cantrade(universe, securitysymbol, datetime)	
end

function cantrade(universe::Universe, security::Security, datetime::DateTime)
	if empty(security)
		#Log message that symbol is not in the universe and return False as the default value
		return false
	else
		cantrade(security, datetime)
	end	
end

function cantrade(universe::Universe, symbol::SecuritySymbol, datetime::DateTime)
	security = universe[symbol]
	cantrade(universe, security, datetime)
end

function getuniverse(universe::Universe)
	values(universe.securities)
end

function resetuniverse!(universe::Universe)
	universe.securities = Dict()
end



