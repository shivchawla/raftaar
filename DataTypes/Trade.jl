type Trade
  id::ASCIIString
  security::Security
  amount::Int64
  entryPrice::Float64
  exitPrice::Float64
  entryTime::DateTime
  exitTime::DateTime

  function Trade(id::ASCIIString, security::Security, amount::Int64, entryPrice::Float64,
                  exitPrice::Float64, entryTime::DateTime, exitTime::DateTime)
    new(id, security, amount, entryPrice, exitPrice, entryTime, exitTime)
  end
end


Trade() = Trade("",Security(), 0, 0.0, 0.0 DateTime.Now(), DateTime.Now())
