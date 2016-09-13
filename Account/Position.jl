
include("../Security/Security.jl")
include("../Execution/OrderFill.jl")

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

Position() = Position(SecuritySymbol())

Position(securitysymbol::SecuritySymbol) = Position(securitysymbol, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

Position(fill::OrderFill) = Position(fill.securitysymbol, fill.fillquantity, fill.fillprice, fill.orderfee)

Position(symbol::SecuritySymbol, quantity::Int64, averageprice::Float64, totalfees::Float64) = Position(symbol, quantity, averageprice, totalfees, 0.0,0.0,0.0,0.0)

empty(position::Position) = empty(position.securitysymbol) && position.quantity == 0 && position.averageprice==0.0

function holdingcost(position::Position)
  position.quantity * position.avgprice
end

function absholdingcost(position::Position)
  abs(position.quantity * position.avgprice)
end

function holdingvalue(position::Position)
  position.quantity * position.lastprice
end

function absholdingvalue(position::Position)
  abs(position.quantity * position.lastprice)
end

function islong(position::Position)
  position.quantity > 0
end

function isshort(position::Position)
  position.quantity < 0
end

function unrealizedprofitpercent(position::Position)
  absholdingcost(position) == 0.0 ? 0.0 : unrealizedpnl(position)/absholdingcost(position)
end

function unrealizedpnl(position::Position)
  orderFee = getfees(MarketOrder(position.Security, -position.quantity))
  return position.quantity * (position.lastprice -position.avgprice)  - orderFee
end

function totalpnl(position::Position)
  return position.realizedpnl + unrealizedpnl(position)
end


function updatepositionforprice!(position::Position, tradebar::TradeBar)
  position.lastprice = tradebar.close
  position.lasttradepnl = position.quantity * (position.lastprice - position.averageprice)
end

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

function updatefee!(position::Position, fee::Float64)
  position.totalfees += fee
end


function isclosingtrade(position::Position, fill::OrderFill)
  return (islong(position) && fill.fillquantity < 0) || (isshort(position) && fill.fillquantity > 0)
end

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





