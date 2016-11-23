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
type Position
  securitysymbol::SecuritySymbol
  quantity::Int64
  averageprice::Float64
  totalfees::Float64
  lastprice::Float64
  lasttradepnl::Float64
  realizedpnl::Float64 
  totaltradedvolume::Float64
end

export Position

"""
Constructors
"""
Position() = Position(SecuritySymbol())

Position(securitysymbol::SecuritySymbol) = Position(securitysymbol, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

Position(fill::OrderFill) = Position(fill.securitysymbol, fill.fillquantity, fill.fillprice, fill.orderfee)

Position(symbol::SecuritySymbol, quantity::Int64, averageprice::Float64, totalfees::Float64) = Position(symbol, quantity, averageprice, totalfees, 0.0,0.0,0.0,0.0)

empty(position::Position) = empty(position.securitysymbol) && position.quantity == 0 && position.averageprice==0.0

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
  absholdingcost(position) == 0.0 ? 0.0 : 100.0 * unrealizedpnl(position)/absholdingcost(position)
end

"""
Unrealized profit in position (value) 
"""
function unrealizedpnl(position::Position)
  orderFee = getfees(MarketOrder(position.Security, -position.quantity))
  return position.quantity * (position.lastprice -position.avgprice)  - orderFee
end

"""
Total pnl in the position (value)
"""
function totalpnl(position::Position)
  return position.realizedpnl + unrealizedpnl(position)
end

"""
Function to update position for latest price
"""
function updatepositionforprice!(position::Position, tradebar::TradeBar)
  position.lastprice = tradebar.close
  position.lasttradepnl = position.quantity * (position.lastprice - position.averageprice)
end

"""
Function to update position for order fill
"""
function updatepositionforfill!(position::Position, fill::OrderFill)

  #apply sales value to holdings
  position.totaltradedvolume += fill.fillprice*abs(fill.fillquantity)
  
  #update total fees paid
  position.totalfees += fill.orderfee
  
  #calculate the last trade profit
  updatetradeprofit!(position, fill)

  #Update the average price
  updateaverageprice!(position, fill)

  #calculate cash generated
  cashgenerated = -(fill.fillquantity*fill.fillprice) - fill.orderfee
  
  return cashgenerated

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
    position.lasttradepnl = lasttradepnl_wofee - fill.orderfee
    position.realizedpnl += position.lasttradepnl
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
end  





