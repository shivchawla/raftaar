# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("../Security/Security.jl")

@enum Resolution Tick Second Minute Hour Daily
@enum FieldType Open High Low Close Last Volume 

"""
Type to encapsulate latest trade price
"""
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


"""
type to encapuslate securities and latest prices of the securities
"""
type Universe 
	securities::Vector{Security}
	tradebars::Dict{SecuritySymbol, Vector{TradeBar}}
end

"""
Empty constructor
"""
Universe() = Universe(Vector{Security}(), Dict())

"""
Index function to retrieve the security based on symbol
"""
getindex(universe::Universe, symbol::SecuritySymbol) = getindex(universe.securities, symbol)
getindex(universe::Universe, security::Security) = get(universe.securities, security.symbol, Security())
setindex!(universe::Universe, security::Security, symbol::SecuritySymbol) = setindex!(universe.securities, security, symbol)

function contains(universe::Universe, symbol::SecuritySymbol) 
    #haskey(universe.securities, symbol)
end

"""
Function to add security to the universe 
"""
function adduniverse!(universe::Universe, ticker::String;
                                          securitytype::String="EQ",
                                          exchange::String="NSE")

    security = Security(ticker, 
                        securitytype = securitytype,
                        exchange = exchange)
    
    push!(universe.securities, security)
end

"""
Function to set universe with list of tickers
"""
function setuniverse!(universe::Universe, tickers::Vector{String};
                                          securitytype::String="EQ",
                                          exchange::String="NSE")
    
    universe.securities = []

    for ticker in tickers
        adduniverse!(universe, ticker, securitytype = securitytype, exchange = exchange)
    end

end 

#=function adduniverse1!(universe::Universe, ticker::String, securitytype::SecurityType)	
	security = Security(ticker, securitytype)
	adduniverse3!(universe, security)
end

function adduniverse2!(universe::Universe, tickers::Vector{String}, securitytype::SecurityType)
	for ticker in tickers
		adduniverse1!(universe, ticker, securitytype)
	end
end

function setuniverse1!(universe::Universe, ticker::String, securitytype::SecurityType)
	resetuniverse!(universe)
	adduniverse1!(universe, ticker, securitytype)
end

function setuniverse2!(universe::Universe, tickers::Vector{String}, securitytype::SecurityType)
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

function getsecurity(universe::Universe, ticker::String, securitytype::SecurityType)
	symbol = createsymbol(ticker, securitytype)
	getsecurity(symbol, universe)
end

function getsecurity(universe::Universe, symbol::SecuritySymbol)
	get!(universe, symbol, Security())
end=#

"""
Function to remove security from the universe
"""
function removesecurity!(universe::Universe, symbol::SecuritySymbol)
	delete(universe, symbol)
end

"""
Function to remove security from the universe
"""
function removesecurity!(universe::Universe, ticker::String, securitytype::SecurityType)
	symbol = createsymbol(ticker, securitytype)
	removesecurity(symbol, universe)
end

function contains(universe::Universe, ticker::String, securitytype::SecurityType)
	contains(universe, createsymbol(ticker, securitytype))
end

function contains(universe::Universe, security::Security)
	contains(universe, security.symbol)
end 

"""
Function to update prices of the securities in the universe
"""
function updateprices!(universe::Universe, newtradebars::Dict{SecuritySymbol, Vector{TradeBar}})
	universe.tradebars = newtradebars 
end	

"""
Function to get the latest price of the security
"""
function getlatestprice(universe::Universe, ticker::String, securitytype::SecurityType = SecurityType(Equity), field::FieldType=FieldType(Close))
	ss = createsymbol(ticker, securitytype) 	
	getlatestprice(universe, ss, field)   
end

"""
Function to get the latest price of the security
"""
function getlatestprice(universe::Universe, security::Security, field::FieldType=FieldType(Close))
	getlatestprice(universe, security.symbol, field)   
end

"""
Function to get the latest price of the security
"""
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

"""
Function to check whether price is fresh and security is tradeable
"""
function cantrade(universe::Universe, ticker::String, datetime::DateTime, securitytype::SecurityType=SecurityType(Equity))
	securitysymbol = createsymbol(ticker, securitytype)
	cantrade(universe, securitysymbol, datetime)	
end

"""
Function to check whether price is fresh and security is tradeable
"""
function cantrade(universe::Universe, security::Security, datetime::DateTime)
	if empty(security)
		# Log message that symbol is not in the universe and return False as the default value
		return false
	else
		cantrade(security, datetime)
	end	
end

"""
Function to check whether price is fresh and security is tradeable
"""
function cantrade(universe::Universe, symbol::SecuritySymbol, datetime::DateTime)
	security = universe[symbol]
	cantrade(universe, security, datetime)
end

"""
Function to get all securities in the universe
"""
function getuniverse(universe::Universe)
	return universe.securities
end

"""
Function to reset the universe (empty)
"""
function resetuniverse!(universe::Universe)
	universe.securities = Dict()
end



