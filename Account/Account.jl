# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.
 

include("Portfolio.jl")

"""
Account type
An account encapsulates the underlying portfolio and
cash  
"""
type Account
	portfolio::Portfolio
	cash::Float64
    netvalue::Float64
    leverage::Float64
end

Account() = Account(Portfolio(), 0.0, 0.0, 0.0) 

"""
function to reset the cash position of the account
"""
function setcash!(account::Account, amount::Float64)
	account.cash = amount 
    updateaccount!(account)  
end

"""
function to add more cash to the account 
"""
function addcash!(account::Account, amount::Float64)
    account.cash += amount 
    updateaccount!(account)   
end

"""
function to get the net portfolio value of the account
"""
function getportfoliovalue(account::Account)
    account.netvalue
end

"""
function to update the account with cash generated from orderfills
"""
function updateaccount!(account::Account, cashfromfills::Float64 = 0.0)
    account.cash += cashfromfills
    account.netvalue = getnetexposure(account.portfolio) + account.cash
    account.leverage = getgrossexposure(account.portfolio) / account.netvalue
end

"""
function to update the account portfolio with latest prices
"""
function updateaccountforprice!(account::Account, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)
    updateportfolioforprice!(account.portfolio, tradebars, datetime)
    updateaccount!(account)
end

"""
function to update the account with from orderfills (adding/removing positions)
"""
function updateaccountforfills!(account::Account, fills::Vector{OrderFill})
    if !isempty(fills)
        updateaccount!(account, updateportfolioforfills!(account.portfolio, fills))
    end
end
