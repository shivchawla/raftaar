import Raftaar: getposition, getallpositions

"""
Functions to expose Account and Portfolio API
"""
function setcash(cash::Float64)
    #checkforparent(:setcash, :initialize)
    setcash!(algorithm, cash)
end

function addcash(cash::Float64)
    addcash!(algorithm, cash)
end

function getallpositions()
    deepcopy(getallpositions(algorithm.account.portfolio))
end

function getposition(ticker::String)
    deepcopy(getposition(algorithm.account.portfolio, ticker))
end

function getposition(symbol::SecuritySymbol)
    deepcopy(getposition(algorithm.account.portfolio, symbol))
end

function getposition(security::Security)
    deepcopy(getposition(algorithm.account.portfolio, security))
end

function getportfolio()
    deepcopy(algorithm.account.portfolio)
end

function getportfoliovalue()
    algorithm.account.netvalue
end