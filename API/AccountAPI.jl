import Raftaar: getposition, getallpositions

"""
Functions to expose Account and Portfolio API
"""
function setcash(cash::Float64)
    checkforparent([:initialize,:_init])
    setcash!(algorithm, cash)
end
export setcash

function addcash(cash::Float64)
    checkforparent([:initialize,:_init])
    addcash!(algorithm, cash)
end
export addcash

function getposition(ticker::String)
    
    getposition(algorithm.state.account, ticker)
end
export getposition

function getposition(symbol::SecuritySymbol)
    getposition(algorithm.state.account, symbol)
end
export getposition

function getposition(security::Security)
    getposition(algorithm.state.account, security)
end
export getposition

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
