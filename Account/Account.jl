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
    portfolio::Portfolio
end

Account() = Account(0.0, 0.0, 0.0, 0.0, Portfolio())

Account(data::BSONObject) = Account(data["seedcash"], data["cash"], data["netvalue"], data["leverage"], Portfolio(data["portfolio"]))

"""
function to reset the cash position of the account
"""
function setcash!(account::Account, amount::Float64)
    
    account.seedcash = amount
    account.cash = 0.0
    updateaccount_forcash!(account, amount)
end

"""
function to add more cash to the account
"""
function addcash!(account::Account, amount::Float64)
    #account.cash += amount
    updateaccount_forcash!(account, cash)
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
function updateaccount_forcash!(account::Account, cash::Float64 = 0.0)
    account.cash += cash
    account.netvalue = account.portfolio.metrics.netexposure + account.cash
    account.leverage = account.portfolio.metrics.grossexposure / account.netvalue
end

"""
function to update the account portfolio with latest prices
"""
function updateaccount_price!(account::Account, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)
    updateportfolio_price!(account.portfolio, tradebars, datetime)
    account.netvalue = account.portfolio.metrics.netexposure + account.cash
    account.leverage = account.portfolio.metrics.grossexposure / account.netvalue
end

"""
function to update the account portfolio with corporate adjustments
"""
function updateaccount_splits_dividends!(account::Account, adjustments::Dict{SecuritySymbol, Adjustment})
    updateportfolio_splits_dividends!(account.portfolio, adjustments)

    cashfromdividends = 0.0
    for (symbol, adjustment) in adjustments
        cashfromdividends += (adjustment.adjustmenttype == "17.0") ? account.portfolio[symbol].quantity * adjustment.adjustmentfactor : 0.0
    end

    updateaccount_forcash!(account, cashfromdividends)
end

"""
function to update the account with from orderfills (adding/removing positions)
"""
function updateaccount_fills!(account::Account, fills::Vector{OrderFill})
    if !isempty(fills)
        cashgenerated = updateportfolio_fills!(account.portfolio, fills)

        updateaccount_forcash!(account, cashgenerated)
    end
end

"""
function to get all positions in a portfolio
"""
function getallpositions(account::Account)
  values(account.portfolio)
end

function getposition(account::Account, ss::SecuritySymbol)
  return getposition(account.portfolio, ss)
end

#precompile(updateaccountforfills!,(Account, Portfolio, Vector{OrderFill}))

function serialize(account::Account)
  return Dict{String, Any}("seedcash" => account.seedcash,
                            "cash"     => account.cash,
                            "netvalue" => account.netvalue,
                            "leverage" => account.leverage,
                            "portfolio" => serialize(account.portfolio))
end

==(acc1::Account, acc2::Account) = acc1.seedcash == acc2.seedcash &&
                                    acc1.cash == acc2.cash &&
                                    acc1.netvalue == acc2.netvalue &&
                                    acc1.leverage == acc2.leverage &&
                                    acc1.portfolio == acc2.portfolio
