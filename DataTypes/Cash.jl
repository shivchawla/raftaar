# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

type Cash
  symbol::String
  name::String
  conversionRate::Float64

  function Cash(symbol::String, name::String, conversionRate::Float64)
    new(symbol, name, conversionRate)
)
end

Cash(symbol::String, name::String) = Cash(symbol, name, 1.0)
Cash() = Cash("","", 1.0)
