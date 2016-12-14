# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

import Base: ==
#include("SecurityExchange.jl")


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
  country::String
  securitytype::String
  startdate::DateTime
  enddate::DateTime
  #currency::Symbol
end

empty(security::Security) = empty(security.symbol) 

Security() = Security(SecuritySymbol(),"","","","", DateTime(), DateTime())
Security(ticker::String; securitytype::String = "EQ", exchange::String="NSE", country::String="IN") = 
                  Security(SecuritySymbol(0,ticker), "",
                            exchange, securitytype,
                            DateTime(), DateTime())

Security(id::Int64, ticker::String, name::String; exchange::String="NSE", country::String = "IN", securitytype::String = "EQ") = 
          Security(SecuritySymbol(id, ticker), name, exchange, country, securitytype, DateTime(), DateTime())

#Security(ticker::String) = Security(SecuritySymbol(0,ticker), "", "EQ", "NSE",DateTime(), DateTime())
            
                          #=securitytype = securitytype,
                          exchange = exchange, DateTime(), DateTime())=#
#; securitytype::String = "EQ", exchange::String="NSE")

            
"""
Function to set security id for security
"""        
function setsecurityid!(security::Security, id::Int)
    setsecurityid!(security.symbol, id)
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


