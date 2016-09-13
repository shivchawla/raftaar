module Execution

function setcommission(feemodel::FeeModel)
  setcommission!(feemodel, brokerage)
end

function setslippage(slippage::Slippage)
  setslippage!(slippage, brokerage)
end

function placeorder(symbol::Security, quantity::Int64, price::Float64)
  placeorder(Order(symbol, quantity, price), brokerage)
end

function placeorder(symbol::Security, quantity::Int64)
  placeorder(Order(symbol, quantity), brokerage)
end

function liquidate(symbol::Security)
  setholdingpct(symbol, 0.0)
end

function placeorder(symbol::ASCIIString, quantity::Int64, price::Float64)
  placeorder(Order(security(symbol), quantity, price))
end

function placeorder(symbol::ASCIIString, quantity::Int64)
  placeorder(Order(security(symbol), quantity))
end

function liquidate(symbol::ASCIIString)
  liquidate(security(symbol))
end

function liquidateportfolio(portfolio::Portfolio)
end

#Order function to set holdings to a specific level in pct/value/shares

function setholdingpct!(security::Security, target::Float64)
end

function setholdingvalue!(security::Security, target::Float64)
end

function setholdingshares!(security::Security, target::Int64)
end

function setholdingpct!(security::ASCIIString, target::Float64)
end

function setholdingvalue!(security::ASCIIString, target::Float64)
end

function setholdingshares!(security::ASCIIString, target::Int64)
end

function hedgeportfolio()
end

#get orders
function getorders()
end

function getopenorders()
end

end
