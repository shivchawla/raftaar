type SecurityExchange
  symbol::ASCIIString
  name::ASCIIString
  startTime::DateTime
  endTime::DateTime
  timePeriod::Period

  function(symbol::ASCIIString, name::ASCIIString, startTime::DateTime, endTime::DateTime, timePeriod::Period)
    new(symbol, name, startTime, endTime, timePeriod)
  end
end

SecurityExchange(symbol::ASCIIString, name::ASCIIString, startTime::DateTime, endTime::DateTime) =
    SecurityExchange(symbol, name, startTime, endTime, endtime - startTime)

SecurityExchange() = SecurityExchange("", "", DateTime(), DateTime(), Dates.Period())

