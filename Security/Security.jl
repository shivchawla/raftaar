# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#include("SecurityExchange.jl")

"""
Definition of Security Type 
"""
@enum SecurityType Equity Futur Option Commodity Forex Cfd InValid

"""
Combination of stock ticker and integer id
"""
type SecuritySymbol
  id::Int64
  ticker::String
end

"""
Empty Constructor
"""
SecuritySymbol() = SecuritySymbol(0, "")

"""
Definition of empty SecuritySymbol
"""
empty(symbol::SecuritySymbol) = (symbol.id==0 && symbol.ticker=="")
==(symbol_one::SecuritySymbol, symbol_two::SecuritySymbol) = symbol_one.id == symbol_two.id && symbol_one.ticker == symbol_two.ticker
Base.hash(symbol::SecuritySymbol, h::UInt) = hash(symbol.id, h)


"""
Security Type
"""
type Security
  symbol::SecuritySymbol
  name::String
  exchange::String
  securitytype::String
  startdate::DateTime
  enddate::DateTime
  #currency::Symbol
end


#Security(ticker::String) = Security(SecuritySymbol(0,ticker), "", "EQ", "NSE",DateTime(), DateTime())
            
                          #=securitytype = securitytype,
                          exchange = exchange, DateTime(), DateTime())=#
#; securitytype::String = "EQ", exchange::String="NSE")

Security(ticker::String; securitytype::String = "EQ", exchange::String="NSE") = 
                  Security(SecuritySymbol(0,ticker), "",
                            exchange, securitytype,
                            DateTime(), DateTime())
            

"""
Function to set security id for security
"""        
function setsecurityid!(security::Security, id::Int)
    setsecurityid(security.symbol, id)
end

"""
Function to set security id for security symbol
"""
function setsecurityid!(symbol::SecuritySymbol, id::Int)
    symbol.id = id
end


#=Security(symbol::SecuritySymbol, securitytype::SecurityType) = 
              Security(symbol, securitytype, "", DateTime(), 
                       DateTime())

empty(security::Security) = empty(security.symbol)

function Security(ticker::String, securitytype::SecurityType)
  Security(createsymbol(ticker, securitytype), securitytype)
end=#

"""
Function to check whether security is active
"""
function cantrade(security::Security, datetime::DateTime)
  return datetime >= security.startdate && datetime <= security.enddate
end


