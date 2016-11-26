# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("Order.jl")
#include("../Account/Position.jl")


type Margin
	initialmargin::Float64
  maintenancemargin::Float64
end

Margin() = Margin(1.0, 1.0)

function getmaintenancemargin(position::Position, margin::Margin)
	return  absholdingcost(position) * margin.maintenancemargin	
end


function totalmarginused(portfolio::Portfolio, margin::Margin)
	totalmargin = 0
  for (security, position) in enumerate(portfolio.positions)
    	totalmargin = getmaintenancemargin(position, margin)
	end
                   
    return totalmargin
end


function marginremaininginaccount(account::Account, margin::Margin)
	return getaccountnetvalue(account) - totalmarginused(account.portfolio, margin)
end

function getmarginremaining(account::Account, margin::Margin, order::Order)
    
    position = account.portfolio[order.securitysymbol]
   
    direction = order.quantity < 0 ? :sell : :buy
    
    #Case2 : marginleft = 2 * current value of asset + cash if order direction is opposite to the position
    if islong(position)
      
        if direction == :buy 
          return marginremaininginaccount(account, margin)
        
        elseif direction == :sell
          return 
              #portion of margin to close the existing position
              # + portion of margin to open the new position
              getmaintenancemargin(position, margin) +
                #absholdingsvalue(position) * margin.initialmargin  +
                marginremaininginaccount(account, margin)
        end
        
    elseif isshort(position)
   
        if direction == :buy
            return
              #portion of margin to close the existing position
              #+ portion of margin to open the new position
              getmaintenancemargin(position) +
              #absholdingsvalue(position) * margin.initialmargin +
              marginremaininginaccount(account, margin)
        end

		else direction == :sell
        return marginremaininginaccount(account, margin)

    end
end


function getinitialmarginfororder(margin::Margin, order::Order, commission::Commission)
	orderfee = getcommission(order, commission)
	ordervalue = getordervalue(order) * margin.initialmargin
	return ordervalue + sign(ordervalue) * orderfee
end


function scanformargincall(portfolio::Portfolio, margin::Margin)
		
	totalmarginused = totalmarginused(portfolio, margin)
   
	#don't issue a margin call if we're not using margin
	if totalmarginused <= 0.0
  	return Vector{Order}()
  end  

	#if leverage is less than 1.0, don't issue a margin call
	avgholdingsleverage = totalabsoluteholdingscost(portfolio)/totalmarginused
	if avgholdingsleverage <= 1.0
  	return Vector{Order}()
  end
    
  marginremaining = getmarginremaining(portfolio, margin)
	totalportfoliovalue = totalportfoliovalue(portfolio)
	if marginremaining <= totalportfoliovalue*0.05
  	issuemargincallwarning  = true
  end
    
	if marginremaining  > 0.0
  	return Vector{Order}()
  end
    
	#Generate a list of margin call orders 
	margincallorders = Vector{Order}()
	for (sec, pos) in enumerate(positions)
  
		margincallorder = generatemargincallorder(security, totalportfoliovalue, totalmarginused)
      	if !isempty(margincallorder) && margincallorder.quantity != 0
        	margincallorders.Add(margincallorder)
        end             
	end

	return margincallorders
end



