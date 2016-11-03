using Base.Test
include("../API/API.jl")

cash = 10000.0
setcash(cash)
@test algorithm.account.cash == cash

addncash = 5000.0
addcash(addncash)
@test algorithm.account.cash == cash + addncash

netvalue = getportfoliovalue()
@test netvalue == algorithm.account.cash


