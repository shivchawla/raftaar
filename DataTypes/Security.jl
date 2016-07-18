"Definition of Security type"

@enum SecurityType
    Base = 0
    Equity = 1
    Option = 2
    Commodity = 3
    Forex = 4
    Future = 5
    Cfd = 6


type SecuritySymbol
  id::Int64
  ticker::ASCIIString
end

type SecurityCache
  lastDatetime::DateTime
  lastprice::Float64
  openprice::Float64
  highPrice::Float64
  lowPrice::Float64
  closePrice::Float64
  volume::Int64
  bidPrice::Float64
  askPrice::Float64
  bidSize::Int64
  askSize::Int64
end


function updateprice(cache::SecurityCache, tick::Tick)

end

function updateprice(cache::SecurityCache, bar::Bar)
end

type Security
  symbol::SecuritySymbol
  name::ASCIIString
  exchange::SecurityExchange
  startDate::DateTime
  endDate::DateTime
  currency::Symbol
  sType::SecurityType
  isTradable::Bool
  cache::SecurityCache
  dateTime::DateTime


  function Security(id::ASCIIString, symbol::ASCIIString, name::ASCIIString,
                    exchange::SecurityExchange, startDate::DateTime, endDate::DateTime,
                    currency::ASCIIString, sType::SecurityType, isTradable::Bool, cache::SecurityCache)
    new(id, symbol, name, exchange, startDate, endDate, currency, sType)
  end
end

function getlastprice(security::Security)
  security.cache.lastprice
end

function updateprice(security::Security, tick::Tick)
  updatecache(security.cache, tick)
end

function updateprice(security::Security, bar::Bar)
  updatecache(security.cache, bar)
end

