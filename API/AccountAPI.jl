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

function setbenchmark(ticker::String)

end


function getposition(ticker::String)
    
    getposition(algorithm.state.portfolio, ticker)
end
export getposition

function getposition(symbol::SecuritySymbol)
    getposition(algorithm.state.portfolio, symbol)
end
export getposition

function getposition(security::Security)
    getposition(algorithm.state.portfolio, security)
end
export getposition

function getportfoliovalue()
    algorithm.state.account.netvalue
end
export getportfoliovalue