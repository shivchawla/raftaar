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
    seedcash::Float64
    cash::Float64
    netvalue::Float64
    leverage::Float64
end

Account() = Account(0.0, 0.0, 0.0, 0.0) 

"""
function to reset the cash position of the account
"""
function setcash!(account::Account, portfolio::Portfolio, amount::Float64)
    account.seedcash = amount
    account.cash = amount 
    updateaccount!(account, portfolio)  
end

"""
function to add more cash to the account 
"""
function addcash!(account::Account, portfolio::Portfolio, amount::Float64)
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
function updateaccount!(account::Account, portfolio::Portfolio, cash_fills_dividends::Float64 = 0.0)
    account.cash += cash_fills_dividends
    account.netvalue = portfolio.metrics.netexposure + account.cash
    account.leverage = portfolio.metrics.grossexposure / account.netvalue
end

"""
function to update the account portfolio with latest prices
"""
function updateaccount_price!(account::Account, portfolio::Portfolio, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)
    updateportfolio_price!(portfolio, tradebars, datetime)
    updateaccount!(account, portfolio)
end

"""
function to update the account portfolio with corporate adjustments
"""
function updateaccount_splits_dividends!(account::Account, portfolio::Portfolio, adjustments::Dict{SecuritySymbol, Adjustment})
    updateportfolio_splits_dividends!(portfolio, adjustments)
    
    cashfromdividends = 0.0
    for (symbol, adjustment) in adjustments
        cashfromdividends += (adjustment.adjustmenttype == "17.0") ? portfolio[symbol].quantity * adjustment.adjustmentfactor : 0.0
    end

    updateaccount!(account, portfolio, cashfromdividends)
end

"""
function to update the account with from orderfills (adding/removing positions)
"""
function updateaccount_fills!(account::Account, portfolio::Portfolio, fills::Vector{OrderFill})
    if !isempty(fills)
        cashgenerated = updateportfolio_fills!(portfolio, fills)
        
        updateaccount!(account, portfolio, cashgenerated)
    end
end

#precompile(updateaccountforfills!,(Account, Portfolio, Vector{OrderFill}))
