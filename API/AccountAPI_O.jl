import Raftaar: getposition, getallpositions

"""
Functions to expose Account and Portfolio API
"""
function setcash(cash::Float64)
    #checkforparent(:setcash, :initialize)
    setcash!(algorithm, cash)
end
export setcash

function addcash(cash::Float64)
    addcash!(algorithm, cash)
end
export addcash

function getallpositions()
    deepcopy(getallpositions(algorithm.account.portfolio))
end
export getallpositions

function getposition(ticker::String)
    deepcopy(getposition(algorithm.account.portfolio, ticker))
end
export getposition

function getposition(symbol::SecuritySymbol)
    deepcopy(getposition(algorithm.account.portfolio, symbol))
end
export getposition

function getposition(security::Security)
    deepcopy(getposition(algorithm.account.portfolio, security))
end
export getposition

function getportfolio()
    deepcopy(algorithm.account.portfolio)
end
export getportfolio

function getaccount()
    deepcopy(algorithm.account)
end
export getaccount

function getportfoliovalue()
    algorithm.account.netvalue
end
export getportfoliovalue