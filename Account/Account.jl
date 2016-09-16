
include("Portfolio.jl")

type Account
	portfolio::Portfolio
	cash::Float64
    netvalue::Float64
    grossvalue::Float64
    leverage::Float64
end

Account() = Account(Portfolio(), 0.0, 0.0, 0.0, 0.0) 

function setcash!(account::Account, amount::Float64)
	account.cash = amount 
    updateaccount!(account)  
end

function addcash!(account::Account, amount::Float64)
    account.cash += amount 
    updateaccount!(account)   
end

function getportfoliovalue(account::Account)
    account.metrics.netvalue
end

function updateaccount!(account::Account, cashfromfills::Float64 = 0.0)
    account.cash += cashfromfills
    account.netvalue = getnetexposure(account.portfolio) + account.cash
    account.leverage = getgrossexposure(account.portfolio) / account.netvalue
end

function updateaccountforprice!(account::Account, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)
    updateportfolioforprice!(account.portfolio, tradebars, datetime)
    updateaccount!(account)
end

function updateaccountforfills!(account::Account, fills::Vector{OrderFill})
    if !isempty(fills)
        updateaccount!(account, updateportfolioforfills!(account.portfolio, fills))
    end
end


#metrics.totalprofit += position.totalpnl
    #metrics.totalfees += position.totalfees 
    #metrics.totalsalevolume += position.totalsalevolume 
    #metrics.totalmarginused = 0
    #metrics.marginremaining = 0
