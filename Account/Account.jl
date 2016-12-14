# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.
 

"""
Account type
An account encapsulates the underlying portfolio and
cash  
"""
type Account
    cash::Float64
    netvalue::Float64
    leverage::Float64
end

Account() = Account(0.0, 0.0, 0.0) 

"""
function to reset the cash position of the account
"""
function setcash!(account::Account, portfolio::Portfolio, amount::Float64)
    account.cash = amount 
    updateaccount!(account, portfolio)  
end

"""
function to add more cash to the account 
"""
function addcash!(account::Account, porfolio::Portfolio, amount::Float64)
    account.cash += amount 
    updateaccount!(account, portfolio)   
end

"""
function to get the net portfolio value of the account
"""
function getaccountnetvalue(account::Account)
    account.netvalue
end

"""
function to update the account with cash generated from orderfills
"""
function updateaccount!(account::Account, portfolio::Portfolio, cashfromfills::Float64 = 0.0)
    account.cash += cashfromfills
    account.netvalue = getnetexposure(portfolio) + account.cash
    account.leverage = getgrossexposure(portfolio) / account.netvalue
end

"""
function to update the account portfolio with latest prices
"""
function updateaccountforprice!(account::Account, portfolio::Portfolio, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)
    updateportfolioforprice!(portfolio, tradebars, datetime)
    updateaccount!(account, portfolio)
end

"""
function to update the account with from orderfills (adding/removing positions)
"""
function updateaccountforfills!(account::Account, portfolio::Portfolio, fills::Vector{OrderFill})
    if !isempty(fills)
        cashgenerated = updateportfolioforfills!(portfolio, fills)
        updateaccount!(account, portfolio, cashgenerated)
    end
end
