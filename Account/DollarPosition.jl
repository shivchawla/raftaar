# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Security/Security.jl")

"""
DollarPosition Type - Modelling position pbject in terms of money invested (assuming 100% invested)
Type to encapsulate details like underlying symbol,
invesment, price etc.
"""
type DollarPosition
  securitysymbol::SecuritySymbol
  investment::Float64
  averageprice::Float64
  totalfees::Float64
  lastprice::Float64
  lasttradepnl::Float64
  realizedpnl::Float64
  totaltradedvolume::Float64
  advice::String
  dividendcash::Float64
end

export DollarPosition

"""
Constructors
"""
DollarPosition() = DollarPosition(SecuritySymbol())

DollarPosition(data::Dict{String, Any}) = DollarPosition(SecuritySymbol(data["securitysymbol"]["id"], data["securitysymbol"]["ticker"]),
                                      data["investment"],
                                      data["averageprice"],
                                      data["totalfees"],
                                      data["lastprice"],
                                      data["lasttradepnl"],
                                      data["realizedpnl"],
                                      data["totaltradedvolume"],
                                      get(data, "advice", ""),
                                      get(data, "dividendcash", 0.0))

DollarPosition(securitysymbol::SecuritySymbol) = DollarPosition(securitysymbol, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, "", 0.0)


DollarPosition(symbol::SecuritySymbol, averageprice::Float64, totalfees::Float64, advice::String="", dividendcash::Float64=0.0) = DollarPosition(symbol, investment, averageprice, totalfees, 0.0, 0.0, 0.0, 0.0, advice, dividendcash)

DollarPosition(symbol::SecuritySymbol, averageprice::Float64, advice::String="", dividendcash::Float64=0.0) = DollarPosition(symbol, investment, averageprice, 0.0, 0.0, 0.0, 0.0, 0.0, advice, dividendcash)

empty(position::DollarPosition) = empty(position.securitysymbol) && position.investment == 0 && position.averageprice==0.0


"""
Serialize the position to dictionary object
"""
function serialize(position::DollarPosition)
  return Dict{String, Any}("securitysymbol"   => serialize(position.securitysymbol),
                          "investment"        => position.investment,
                          "averageprice"      => position.averageprice,
                          "totalfees"         => position.totalfees,
                          "lastprice"         => position.lastprice,
                          "lasttradepnl"      => position.lasttradepnl,
                          "realizedpnl"       => position.realizedpnl,
                          "totaltradedvolume" => position.totaltradedvolume,
                          "advice"            => position.advice,
                          "dividendcash"      => position.dividendcash)
end

==(pos1::DollarPosition, pos2::DollarPosition) = pos1.securitysymbol == pos2.securitysymbol &&
                                      pos1.investment == pos2.investment &&
                                      pos1.averageprice == pos2.averageprice &&
                                      pos1.totalfees == pos2.totalfees &&
                                      pos1.lastprice == pos2.lastprice &&
                                      pos1.lasttradepnl == pos2.lasttradepnl &&
                                      pos1.realizedpnl == pos2.realizedpnl &&
                                      pos1.totaltradedvolume == pos2.totaltradedvolume &&
                                      pos1.advice == pos2.advice &&
                                      pos1.dividendcash == pos2.dividendcash


"""
Function to update position for latest price
"""
function updateposition_price!(position::DollarPosition, tradebar::TradeBar)
  if(tradebar.close > 0.0000000001 && !isnan(tradebar.close))
    position.lastprice = tradebar.close
    position.lasttradepnl = round(positions.averageprice > 0 ? (position.investment * (position.lastprice - position.averageprice)/pos.averageprice), 2)
  end
end

"""
Function to update position for order fill
"""
function updateposition_fill!(position::DollarPosition, fill::OrderFill)

  #apply sales value to holdings
  position.totaltradedvolume += fill.fillprice*abs(fill.fillquantity)
  position.totaltradedvolume = round(position.totaltradedvolume, 2)

  #update total fees paid
  position.totalfees += fill.orderfee

  #calculate the last trade profit
  updatetradeprofit!(position, fill)

  #Update the average price
  updateaverageprice!(position, fill)

  #calculate cash generated (if orderfill is cashlinked)
  #By default cash linked, 
  #Cashlining introduced to support MktPlace portfolios/transactions
  cashgenerated = fill.cashlinked ? -(fill.fillquantity*fill.fillprice) - fill.orderfee : 0.0

  return round(cashgenerated, 2)

end

"""
function to update totoal fee for the position
"""
function updatefee!(position::DollarPosition, fee::Float64)
  position.totalfees += fee
end

"""
function to find whether a closing trade or extending trade
"""
function isclosingtrade(position::DollarPosition, fill::OrderFill)
  return (islong(position) && fill.fillquantity < 0) || (isshort(position) && fill.fillquantity > 0)
end

"""
function to update the trade profit
"""
function updatetradeprofit!(position::DollarPosition, fill::OrderFill)
  #did we close or open a position further?

  if isclosingtrade(position, fill)
    qty = position.averageprice > 0 ? position.investment/position.averageprice : 0.0
    absquantityclosed = min(abs(fill.fillquantity), abs(qty))
    closedsalevalue = sign(-fill.fillquantity) * fill.fillprice * absquantityclosed
    closedcost = sign(-fill.fillquantity) * absquantityclosed * position.averageprice

    lasttradepnl_wofee = (closedsalevalue - closedcost)
    #*conversionFactor
    position.lasttradepnl = round(lasttradepnl_wofee - fill.orderfee,2)
    position.realizedpnl += position.lasttradepnl
    position.realizedpnl = round(position.realizedpnl, 2)
  end
end

"""
funtion to update the average price after an order fill
"""
function updateaverageprice!(position::DollarPosition, fill::OrderFill)

  position.investment = position.investment + fill.fillprice*fill.fillquantity

  if position.investment == 0
      position.averageprice = fill.fillprice
      position.lastprice = fill.fillprice

  #Long position
  elseif position.investment > 0
    #Sell Trade
    if fill.fillquantity < 0
      #cover and short sell
      if position.investment < 0
        position.averageprice = fill.fillprice
      elseif position.investment == 0
        position.averageprice = 0
      end
    else
      #Buy Trade
      if fill.fillquantity > 0
        position.averageprice = (position.investment + fill.fillprice * fill.fillquantity)/(qty + fill.fillquantity)
      end
    end

  #Short position
  elseif position.investment < 0

    #Buy Trade
    if fill.fillquantity > 0
      #Buy-to-cover and Buy Long
      if position.investment > 0
        position.averageprice = fill.fillprice
      elseif position.investment == 0
        position.averageprice = 0
      end
    else
      #Sell Trade
      if fill.fillquantity < 0
        qty = position.investment/position.averageprice
        position.averageprice = (position.investment  + fill.fillprice * fill.fillquantity)/(qty + fill.fillquantity)
      end
    end

  end

  position.averageprice = round(position.averageprice, 2)
  position.lastprice = round(position.lastprice, 2)

end

"""
Function to update position for corporate adjustment (not cash dividend)
"""
function updateposition_splits_dividends!(position::DollarPosition, adjustment::Adjustment)
    cash = 0.0
    if(adjustment.adjustmenttype != "17.0")
        position.averageprice = round(position.averageprice * adjustment.adjustmentfactor,2)
        position.lastprice = round(position.lastprice * adjustment.adjustmentfactor,2)
        position.investment = round(position.investment * (1.0/adjustment.adjustmentfactor))
    else
        cash = positons.averageprice ? (position.investment/position.averageprice)*adjustment.adjustmentfactor : 0.0
        position.dividendcash += cash
    end

    return cash
end

