
#include("SecurityExchange.jl")

#Definition of Security type
@enum SecurityType Equity Futur Option Commodity Forex Cfd InValid

type SecuritySymbol
  id::Int64
  ticker::ASCIIString
end

SecuritySymbol() = SecuritySymbol(0, "")
empty(symbol::SecuritySymbol) = (symbol.id==0 && symbol.ticker=="")
==(symbol_one::SecuritySymbol, symbol_two::SecuritySymbol) = symbol_one.id == symbol_two.id && symbol_one.ticker == symbol_two.ticker
Base.hash(symbol::SecuritySymbol, h::UInt) = hash(symbol.id, h)


type Security
  symbol::SecuritySymbol
  securitytype::SecurityType
  name::ASCIIString
  #exchange::SecurityExchange
  startdate::DateTime
  enddate::DateTime
  #currency::Symbol
end


Security(symbol::SecuritySymbol, securitytype::SecurityType) = 
              Security(symbol, securitytype, "", DateTime(), 
                       DateTime())

empty(security::Security) = empty(security.symbol)

function Security(ticker::ASCIIString, securitytype::SecurityType)
  Security(createsymbol(ticker, securitytype), securitytype)
end


function cantrade(security::Security, datetime::DateTime)
  return datetime >= security.startdate && datetime <= security.enddate
end


function createsymbol(ticker::ASCIIString, securitytype::SecurityType, exchange::ASCIIString="")
  SecuritySymbol(generateid(ticker, securitytype, exchange), ticker)
end


function generateid(ticker::ASCIIString, securitytype::SecurityType, exchange::ASCIIString)
    return 1
end 

