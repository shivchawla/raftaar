# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


import Base: contains

import Base: empty

const SIZE = 5

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


empty(tradebar::TradeBar) = tradebar.datetime == DateTime() && tradebar.open == 0.0 && tradebar.high == 0.0 && tradebar.low == 0.0 && tradebar.close == 0.0 && tradebar.volume == 0
TradeBar(datetime::DateTime, open::Float64, high::Float64, low::Float64, close::Float64) = 
				TradeBar(datetime, open, high, low, close, 0)

TradeBar() = TradeBar(DateTime(), 0.0, 0.0, 0.0, 0.0, 0)

"""
type to encapuslate securities and latest prices of the securities
"""
type Universe 
	#securities::Vector{Security}
    securities::Dict{SecuritySymbol, Security}
	tradebars::Dict{SecuritySymbol, Vector{TradeBar}}
end

"""
Empty constructor
"""
Universe() = Universe(Dict(), Dict())

"""
Index function to retrieve the security based on symbol
"""
getindex(universe::Universe, symbol::SecuritySymbol) = get(universe.securities, symbol, Security())
getindex(universe::Universe, security::Security) = get(universe.securities, security.symbol, Security())
setindex!(universe::Universe, security::Security, symbol::SecuritySymbol) = setindex!(universe.securities, security, symbol)

function contains(universe::Universe, symbol::SecuritySymbol) 
    return !empty(universe[symbol])
end

function contains(universe::Universe, security::Security)
    return !empty(universe[security.symbol])
end 
export contains


"""
Function to add security to the universe 
"""
function adduniverse!(universe::Universe, ticker::String;
                                          securitytype::String="EQ",
                                          exchange::String="NSE")

    security = Security(ticker, 
                        securitytype = securitytype,
                        exchange = exchange)
    
    #push!(universe.securities, security)
    universe.securities[security.symbol] = security
end

"""
Function to set universe with list of tickers
"""
function setuniverse!(universe::Universe, tickers::Vector{String};
                                          securitytype::String="EQ",
                                          exchange::String="NSE")
    
    resetuniverse!(universe)
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
end=#

####################

function adduniverse!(universe::Universe, security::Security)	
    if !empty(security)
		if !haskey(universe.securities, security.symbol)
			universe[security.symbol] = security
		end
	end
end

function adduniverse!(universe::Universe, securities::Vector{Security})
	for security in securities
		adduniverse!(universe, security)
	end
end

function setuniverse!(universe::Universe, security::Security)
	resetuniverse!(universe)
	adduniverse!(universe, security)
end

function setuniverse!(universe::Universe, securities::Vector{Security})
	resetuniverse!(universe) 
	adduniverse!(universe, securities)
end
#=
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

"""
Function to update prices of the securities in the universe
"""
function updateprices!(universe::Universe, newtradebars::Dict{SecuritySymbol, TradeBar})
    
    for symbol in keys(universe.securities)
        
        if !haskey(universe.tradebars, symbol)     
            
            universe.tradebars[symbol] = Vector{TradeBar}(SIZE)
            for i = 1:SIZE
               universe.tradebars[symbol][i] = TradeBar()
            end 
        end    
        
        tradebar = haskey(newtradebars, symbol) ? newtradebars[symbol] : TradeBar() 
        
        shiftforwardandinsert!(universe.tradebars[symbol], tradebar)
        
    end

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
    tradebars = universe.tradebars
    
    if haskey(tradebars, symbol)
        if length(tradebars[symbol]) > 0
            # Latest Bar
            bar = tradebars[symbol][1]
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
    end

    return -999
end


function getlatesttradebar(universe::Universe, symbol::SecuritySymbol)
    tradebars = universe.tradebars
    
    if haskey(tradebars, symbol)
        return deepcopy(tradebars[symbol][1])
    end

    return TradeBar()
end 
export getlatesttradebar

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
	return collect(values(universe.securities))
end

"""
Function to reset the universe (empty)
"""
function resetuniverse!(universe::Universe)
	universe.securities = Dict()
    universe.tradebars = Dict()
end

function updatesecurity!(universe::Universe, security::Security, id::Int)
    
    if haskey(universe.securities, security.symbol)
        delete!(universe.securities, security.symbol)
        security.symbol.id = id
        universe.securities[security.symbol] = security
    end
end
export updatesecurity!

function shiftforwardandinsert!(tradebars::Vector{TradeBar}, newtradebar::TradeBar)
    
    for i = SIZE:-1:2
        tradebars[i] = tradebars[i-1]
    end

    if !empty(newtradebar)
        tradebars[1] = newtradebar
    end 

end


