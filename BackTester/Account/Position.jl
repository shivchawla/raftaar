# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Security/Security.jl")

"""
Position Type
Type to encapsulate details like underlying symbol,
quantity, price etc.
"""
mutable struct Position
  securitysymbol::SecuritySymbol
  quantity::Int64
  averageprice::Float64
  totalfees::Float64
  lastprice::Float64
  lasttradepnl::Float64
  realizedpnl::Float64
  totaltradedvolume::Float64
  advice::String
  dividendcash::Float64
end

export Position

"""
Constructors
"""
Position() = Position(SecuritySymbol())

Position(data::Dict{String, Any}) = Position(SecuritySymbol(data["securitysymbol"]["id"], data["securitysymbol"]["ticker"]),
                                      data["quantity"],
                                      data["averageprice"],
                                      data["totalfees"],
                                      data["lastprice"],
                                      data["lasttradepnl"],
                                      data["realizedpnl"],
                                      data["totaltradedvolume"],
                                      get(data, "advice", ""),
                                      get(data, "dividendcash", 0.0))

Position(securitysymbol::SecuritySymbol) = Position(securitysymbol, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, "", 0.0)

Position(fill::OrderFill) = Position(fill.securitysymbol, fill.fillquantity, fill.fillprice, fill.orderfee)

Position(symbol::SecuritySymbol, quantity::Int64, averageprice::Float64, totalfees::Float64, advice::String="", dividendcash::Float64=0.0) = Position(symbol, quantity, averageprice, totalfees, 0.0, 0.0, 0.0, 0.0, advice, dividendcash)

Position(symbol::SecuritySymbol, quantity::Int64, averageprice::Float64, advice::String="", dividendcash::Float64=0.0) = Position(symbol, quantity, averageprice, 0.0, 0.0, 0.0, 0.0, 0.0, advice, dividendcash)

Position(symbol::SecuritySymbol, quantity::Int64, advice::String="") = Position(symbol, quantity, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, advice, 0.0)

empty(position::Position) = empty(position.securitysymbol) && position.quantity == 0 && position.averageprice==0.0


"""
Serialize the position to dictionary object
"""
function serialize(position::Position)
  return Dict{String, Any}("securitysymbol"   => serialize(position.securitysymbol),
                          "quantity"          => position.quantity,
                          "averageprice"      => position.averageprice,
                          "totalfees"         => position.totalfees,
                          "lastprice"         => position.lastprice,
                          "lasttradepnl"      => position.lasttradepnl,
                          "realizedpnl"       => position.realizedpnl,
                          "totaltradedvolume" => position.totaltradedvolume,
                          "advice"            => position.advice,
                          "dividendcash"      => position.dividendcash)
end

==(pos1::Position, pos2::Position) = pos1.securitysymbol == pos2.securitysymbol &&
                                      pos1.quantity == pos2.quantity &&
                                      pos1.averageprice == pos2.averageprice &&
                                      pos1.totalfees == pos2.totalfees &&
                                      pos1.lastprice == pos2.lastprice &&
                                      pos1.lasttradepnl == pos2.lasttradepnl &&
                                      pos1.realizedpnl == pos2.realizedpnl &&
                                      pos1.totaltradedvolume == pos2.totaltradedvolume &&
                                      pos1.advice == pos2.advice &&
                                      pos1.dividendcash == pos2.dividendcash



"""
Holding cost of position based on average price
"""
function holdingcost(position::Position)
  position.quantity * position.avgprice
end

"""
Absolute of the holding cost
"""
function absholdingcost(position::Position)
  abs(holdingcost(position))
end

"""
Holding value of the position based on the last price
"""
function holdingvalue(position::Position)
  position.quantity * position.lastprice
end

"""
Absolute of the holding value
"""
function absholdingvalue(position::Position)
  abs(holdingvalue(position))
end

"""
Flag whether a long position
"""
function islong(position::Position)
  position.quantity > 0
end

"""
Flag whether a short position
"""
function isshort(position::Position)
  position.quantity < 0
end

"""
Unrealized profit % of the position
"""
function unrealizedprofitpercent(position::Position)
  absholdingcost(position) == round(0.0 ? 0.0 : 100.0 * unrealizedpnl(position)/absholdingcost(position), digits = 2)
end

"""
Unrealized profit in position (value)
"""
function unrealizedpnl(position::Position)
  orderFee = getfees(MarketOrder(position.Security, -position.quantity))
  return round(position.quantity * (position.lastprice -position.avgprice)  - orderFee, digits = 2)
end

"""
Total pnl in the position (value)
"""
function totalpnl(position::Position)
  return round(position.realizedpnl + unrealizedpnl(position), digits = 2)
end

"""
Function to update position for latest price
"""
function updateposition_price!(position::Position, tradebar::TradeBar)
  if(tradebar.close > 0.0000000001 && !isnan(tradebar.close))
    position.lastprice = tradebar.close
    position.lasttradepnl = round(position.quantity * (position.lastprice - position.averageprice), digits = 2)
  end
end

"""
Function to update position for order fill
"""
function updateposition_fill!(position::Position, fill::OrderFill)

  #apply sales value to holdings
  position.totaltradedvolume += fill.fillprice*abs(fill.fillquantity)
  position.totaltradedvolume = round(position.totaltradedvolume, digits = 2)

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

  return round(cashgenerated, digits = 2)

end

"""
function to update totoal fee for the position
"""
function updatefee!(position::Position, fee::Float64)
  position.totalfees += fee
end

"""
function to find whether a closing trade or extending trade
"""
function isclosingtrade(position::Position, fill::OrderFill)
  return (islong(position) && fill.fillquantity < 0) || (isshort(position) && fill.fillquantity > 0)
end

"""
function to update the trade profit
"""
function updatetradeprofit!(position::Position, fill::OrderFill)
  #did we close or open a position further?

  if isclosingtrade(position, fill)
    absquantityclosed = min(abs(fill.fillquantity), abs(position.quantity))
    closedsalevalue = sign(-fill.fillquantity) * fill.fillprice * absquantityclosed
    closedcost = sign(-fill.fillquantity) * absquantityclosed * position.averageprice

    lasttradepnl_wofee = (closedsalevalue - closedcost)
    #*conversionFactor
    position.lasttradepnl = round(lasttradepnl_wofee - fill.orderfee, digits = 2)
    position.realizedpnl += position.lasttradepnl
    position.realizedpnl = round(position.realizedpnl, digits = 2)
  end

end

"""
funtion to update the average price after an order fill
"""
function updateaverageprice!(position::Position, fill::OrderFill)

  if position.quantity == 0
      position.quantity = fill.fillquantity
      position.averageprice = fill.fillprice
      position.lastprice = fill.fillprice

  #Long position
  elseif position.quantity > 0
    #Sell Trade
    if fill.fillquantity < 0
      position.quantity = position.quantity + fill.fillquantity
      #cover and short sell
      if position.quantity < 0
        position.averageprice = fill.fillprice
      elseif position.quantity == 0
        position.averageprice = 0
      end
    else
      #Buy Trade
      if fill.fillquantity > 0
        position.averageprice = (position.averageprice * position.quantity + fill.fillprice * fill.fillquantity)/(position.quantity + fill.fillquantity)
        position.quantity = position.quantity + fill.fillquantity
      end
    end

  #Short position
  elseif position.quantity < 0

    #Buy Trade
    if fill.fillquantity > 0
      position.quantity = position.quantity + fill.fillquantity
      #Buy-to-cover and Buy Long
      if position.quantity > 0
        position.averageprice = fill.fillprice
      elseif position.quantity == 0
        position.averageprice = 0
      end
    else
      #Sell Trade
      if fill.fillquantity < 0
        position.averageprice = (position.averageprice * position.quantity + fill.fillprice * fill.fillquantity)/(position.quantity + fill.fillquantity)
        position.quantity = position.quantity + fill.fillquantity
      end
    end

  end

  position.averageprice = round(position.averageprice, digits = 2)
  position.lastprice = round(position.lastprice, digits = 2)

end

"""
Function to update position for corporate adjustment (not cash dividend)
"""
function updateposition_splits_dividends!(position::Position, adjustment::Adjustment)
    cash = 0.0
    if(adjustment.adjustmenttype != "17.0")
        position.averageprice = round(position.averageprice * adjustment.adjustmentfactor, digits = 2)
        position.lastprice = round(position.lastprice * adjustment.adjustmentfactor, digits = 2)
        position.quantity = Int(round(position.quantity * (1.0/adjustment.adjustmentfactor)))
    else
        cash = position.quantity*adjustment.adjustmentfactor
        position.dividendcash += cash
    end

    return cash
end

