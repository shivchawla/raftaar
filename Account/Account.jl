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
    netvalue::Float64
    leverage::Float64
    portfolio::Portfolio
end

Account() = Account(0.0, 0.0, 0.0, Portfolio())

Account(data::Dict{String, Any}) = Account(data["seedcash"], 
                                    data["netvalue"], 
                                    data["leverage"], 
                                    Portfolio(data["portfolio"], cash = Float64(get(data, "cash",0.0)))) 
                                    #adding backward compatibility for cash (cash was part of account)

"""
function to reset the cash position of the account
"""
function setcash!(account::Account, amount::Float64)
    account.seedcash = amount
    updateaccount_forcash!(account, amount)
end

"""
function to add more cash to the account
"""
function addcash!(account::Account, amount::Float64)
    updateaccount_forcash!(account, amount)
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
    updateportfolio_forcash!(account.portfolio, cash)
    account.netvalue = account.portfolio.metrics.netexposure + account.portfolio.cash
    account.leverage = account.portfolio.metrics.grossexposure / account.netvalue
end

"""
function to update the account portfolio with latest prices
"""
function updateaccount_price!(account::Account, tradebars::Dict{SecuritySymbol, Vector{TradeBar}}, datetime::DateTime)
    updateportfolio_price!(account.portfolio, tradebars, datetime)
    account.netvalue = account.portfolio.metrics.netexposure + account.portfolio.cash
    account.leverage = account.portfolio.metrics.grossexposure / account.netvalue
end

"""
function to update the account portfolio with corporate adjustments
"""
function updateaccount_splits_dividends!(account::Account, adjustments::Dict{SecuritySymbol, Adjustment})
    updateportfolio_splits_dividends!(account.portfolio, adjustments)
end

"""
function to update the account with from orderfills (adding/removing positions)
"""
function updateaccount_fills!(account::Account, fills::Vector{OrderFill})
    if !isempty(fills)
        updateportfolio_fills!(account.portfolio, fills)
    end
end

#precompile(updateaccountforfills!,(Account, Portfolio, Vector{OrderFill}))

function serialize(account::Account)
  return Dict{String, Any}("seedcash" => account.seedcash,
                            "netvalue" => account.netvalue,
                            "leverage" => account.leverage,
                            "portfolio" => serialize(account.portfolio))
end

==(acc1::Account, acc2::Account) = acc1.seedcash == acc2.seedcash &&
                                    acc1.netvalue == acc2.netvalue &&
                                    acc1.leverage == acc2.leverage &&
                                    acc1.portfolio == acc2.portfolio
