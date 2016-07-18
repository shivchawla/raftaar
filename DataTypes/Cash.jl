type Cash
  symbol::ASCIIString
  name::ASCIIString
  conversionRate::Float64

  function Cash(symbol::ASCIIString, name::ASCIIString, conversionRate::Float64)
    new(symbol, name, conversionRate)
)
end

Cash(symbol::ASCIIString, name::ASCIIString) = Cash(symbol, name, 1.0)
Cash() = Cash("","", 1.0)