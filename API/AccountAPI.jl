import Raftaar: getposition, getallpositions

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

function getposition(ticker::String)
    getposition(algorithm.state.account.portfolio, getsecurity(ticker).symbol)
end
export getposition

function getposition(symbol::SecuritySymbol)
    getposition(algorithm.state.account.portfolio, symbol)
end
export getposition

function getposition(security::Security)
    getposition(algorithm.state.account.portfolio, security.symbol)
end
export getposition

function getallpositions()
    getallpositions(algorithm.state.account.portfolio)
end
export getallpositions

function getportfoliovalue()
    algorithm.state.account.netvalue
end
export getportfoliovalue

getstate() = algorithm.state
export getstate

function getindex(portfolio::Portfolio, ticker::String)
    security = getsecurity(ticker)
    return portfolio[security]
end
