type Position
  security::Security
  quantity::Int64
  averageprice::Float64
  lastprice::Float64
  lasttradepnl::Float64
  realizedpnl::Float64
  totalfees::Float64
  totalsalevolume::Float64
  trades::Vector{OrderFill}

  function Position(security::Security, quantity::Int64, averageprice::Float64,
                    lastprice::Float64, lastTrade::Trade, lasttradepnl::Float64,
                    totalProfit::Float64, totalFees::Float64, totalVolume::Float64)
    new(security, quantity, avgprice, lastprice, lastTrade, lasttradepnl, totalProfit, totalFees, totalVolume)
  end
end

Position() = Position(Security(), 0, 0.0, 0.0, Trade(), 0.0, 0.0, 0.0, 0)
Position(security::Security) = Position(security, 0, 0.0, 0.0, Trade(), 0.0, 0.0, 0.0, 0)

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
  if absholdingcost(position) == 0.0 return 0.0
  return unrealizedpnl(position)/absholdingcost(position)
end

function unrealizedpnl(position::Position)
  orderFee = getfees(MarketOrder(position.Security, -position.quantity))
  return position.quantity * (position.lastprice -position.avgprice)  - orderFee
end

function totalpnl(position::Position)
  return position.realizedpnl + unrealizedpnl(position)
end


function updatepositionforfill!(position::Position, fill::OrderFill)
  
  "append last fill to the list of trades"
  append(position.trades, fill)

  "apply sales value to holdings in the account currency"
  salevalue = fill.fillprice * abs(fill.quantity)
  updatesalevalue(position, salevalue);

  "subtract transaction fees from the portfolio (assumes in account currency)"
  "??? what if order execution is composed of multiple fills"
  feethisorder = abs(fill.orderfee)
  updatefee(position, feethisorder)

  "calculate cash generated"
  cashgenerated = isclosingtrade(position, fill) ? (fill.quantity * fill.price) - feethisorder 
                                                 : -(fill.quantity * fill.price) - feethisorder 

  "calculate the last trade profit"
  updatetradeprofit(position, fill)

  "Update the average price"
  updateaverageprice(position, fill)

  return cashgenerated

end    

function updatefee!(position::Position, fee::Float64)
  position.totalfees += fee
end

function updatesalevalue!(position::Position, sale::Float64)
  position.totalsalevolume += sale
end 

function isclosingtrade(position::Position, fill::OrderFill)
  islong = islong(position)
  isshort = isshort(position)
  return (islong && fill.quantity < 0) || (ishort && fill.quantity > 0)
end

function updatetradeprofit!(position::Position, fill::OrderFill)
  "did we close or open a position further?"
  closedposition = isclosedposition(position, fill) 

  if !closedposition return 0;
    absquantityclosed = min(abs(fill.fillquantity), abs(position.quantity))
    closedsalevalue = sign(-fill.fillquantity) * fill.fillprice * absquantityclosed
    closedcost = sign(-fill.fillquantity) * absquantityclosed * position.averageprice

    "conversionfactor = security.QuoteCurrency.ConversionRate*security.SymbolProperties.ContractMultiplier"
    lasttradepnl_wofee = (closedsalevalue - closedcost) "*conversionFactor"
    position.lasttradepnl = lasttradepnl_wofee - fill.orderfee
    position.realizedpnl += lasttradepnl_wofee - fill.orderfee
  end  

end

function updateaverageprice!(position::Position, fill::OrderFill)
  
  if position.quantity = 0  
    position.quantity = fill.quantity
    position.averageprice = fill.price
  
  else if position.quantity > 0 "Long position"
    
    if fill.quantity < 0 "Sell Trade"
      position.quantity = position.quantity + fill.quantity
      if position.quantity < 0 "cover and short sell"
        position.averageprice = fill.price
      else if position.quantity == 0 
        position.averageprice = 0  
      end  
    else 
      if fill.quantity > 0 "Buy Trade"
        position.averageprice = (position.averageprice * position.quantity + fill.price * fill.quantity)/(position.quantity + fill.quantity)
        position.quantity = position.quantity + fill.quantity  
      end      
    end

  else if position.quantity < 0 "Short position"
    
    if fill.quantity > 0 "Buy Trade"
      position.quantity = position.quantity + fill.quantity
      if position.quantity > 0 "Buy-to-cover and Buy Long"
        position.averageprice = fill.price 
      else if position.quantity == 0 
        position.averageprice = 0  
      end  
    else 
      if fill.quantity < 0 "Sell Trade"
        position.averageprice = (position.averageprice * position.quantity + fill.price * fill.quantity)/(position.quantity + fill.quantity)
        position.quantity = position.quantity + fill.quantity         
      end      
    end
  
  end
end  





