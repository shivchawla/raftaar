import BackTester: getposition, getallpositions

"""
Functions to expose Account and Portfolio API
"""
function setcash(cash::Float64)
    __IllegalContextMessage(:setcash, :ondata)
    setcash!(algorithm, cash)
end
export setcash

function addcash(cash::Float64)
    addcash!(algorithm, cash)
end
export addcash

####WHY USE STATE??? - 
function getposition(ticker::String)
    getposition(algorithm.account.portfolio, getsecurity(ticker).symbol)
end
export getposition

####WHY USE STATE??? - 
function getposition(symbol::SecuritySymbol)
    getposition(algorithm.account.portfolio, symbol)
end
export getposition

####WHY USE STATE??? - 
function getposition(security::Security)
    getposition(algorithm.account.portfolio, security.symbol)
end
export getposition

####WHY USE STATE??? -
function getallpositions()
    getallpositions(algorithm.account.portfolio)
end
export getallpositions

####WHY USE STATE??? -
function getportfoliovalue()
    algorithm.account.netvalue
end
export getportfoliovalue

getstate() = algorithm.state
export getstate

function getindex(portfolio::Portfolio, ticker::String)
    security = getsecurity(ticker)
    return portfolio[security]
end
