# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

import Base: ==, convert, hash

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

SecuritySymbol(id::Int64) = SecuritySymbol(id, "")

function SecuritySymbol(s::String) 
    ss = JSON.parse(s)

    if(typeof(ss) == String) 
        return SecuritySymbol(0, s)
    else
        return SecuritySymbol(ss)
    end  
end

SecuritySymbol(data::Dict{String, Any}) = SecuritySymbol(data["id"], data["ticker"])

tostring(ss::SecuritySymbol) = JSON.json(serialize(ss))

"""
Definition of empty SecuritySymbol
"""
empty(symbol::SecuritySymbol) = (symbol.id==0 && symbol.ticker=="")
# Let's check only the symbol ids (and not tickers) because the ids are unique.
# ==(symbol_one::SecuritySymbol, symbol_two::SecuritySymbol) = symbol_one.id == symbol_two.id && symbol_one.ticker == symbol_two.ticker
==(symbol_one::SecuritySymbol, symbol_two::SecuritySymbol) = symbol_one.id == symbol_two.id
hash(symbol::SecuritySymbol, h::UInt) = Base.hash(symbol.id)


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
  detail::Dict{String,Any}
  #currency::Symbol
end

empty(security::Security) = empty(security.symbol)

Security() = Security(SecuritySymbol(),"","","","", DateTime(), DateTime(), Dict{String,Any}())
Security(ticker::String; securitytype::String = "EQ", exchange::String="NSE", country::String="IN") =
                  Security(SecuritySymbol(0,ticker), "",
                            exchange, securitytype,
                            DateTime(), DateTime(), Dict{String,Any}())

Security(ticker::String, detail::Dict{Any,Any}; securitytype::String = "EQ", exchange::String="NSE", country::String="IN") =
                  Security(SecuritySymbol(0,ticker), "",
                            exchange, securitytype,
                            DateTime(), DateTime(), todict(detail))

Security(id::Int64, ticker::String, name::String; exchange::String="NSE", country::String = "IN", securitytype::String = "EQ") =
          Security(SecuritySymbol(id, ticker), name, exchange, country, securitytype, DateTime(), DateTime(), Dict{String,Any}())

Security(id::Int64, ticker::String, name::String, detail::Dict{Any,Any}; exchange::String="NSE", country::String = "IN", securitytype::String = "EQ") =
          Security(SecuritySymbol(id, ticker), name, exchange, country, securitytype, DateTime(), DateTime(), todict(detail))

#==(sec_one::Security, sec_two::Security) = sec_one.symbol == sec_two.symbol=#



"""
Serialize the security to dictionary object
"""
function serialize(symbol::SecuritySymbol)
  return Dict{String,Any}("id" => symbol.id, "ticker" => symbol.ticker)
end

function serialize(security::Security)
  return Dict{String, Any}("symbol"        => serialize(security.symbol),
                            "name"         => security.name,
                            "exchange"     => security.exchange,
                            "country"      => security.country,
                            "securitytype" => security.securitytype,
                            "startdate"    => security.startdate,
                            "enddate"      => security.enddate)
end

==(sr1::Security, sr2::Security) = sr1.symbol == sr2.symbol &&
                                    sr1.name == sr2.name &&
                                    sr1.exchange == sr2.exchange &&
                                    sr1.country == sr2.country &&
                                    sr1.securitytype == sr2.securitytype &&
                                    sr1.startdate == sr2.startdate &&
                                    sr1.enddate == sr2.enddate


Security(data::Dict{String, Any}) = Security(SecuritySymbol(data["symbol"]["id"], data["symbol"]["ticker"]),
                                      data["name"], data["exchange"], data["country"], data["securitytype"], DateTime(data["startdate"]), DateTime(data["enddate"]), Dict{String,Any}())


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


function todict(x::Dict{Any,Any})
  y = Dict{String, Any}()
  
  for (k,v) in x
    y[string(k)] = v
  end

  return y
end
