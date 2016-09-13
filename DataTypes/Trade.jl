type Trade
  id::ASCIIString
  security::Security
  quantity::Int64
  entryPrice::Float64
  exitPrice::Float64
  entryTime::DateTime
  exitTime::DateTime
  direction::TradeDirection
  profitloss::Float64
  totalfees::Float64
  mae::Float64
  mfe::Float64
  endtradedrawdown::Float64
end
