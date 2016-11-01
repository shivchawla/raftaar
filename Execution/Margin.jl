# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("Order.jl")
include("Commission.jl")
include("../Account/Portfolio.jl")

type Margin
	maintenancemargin::Float64
	initialmargin::Float64
end

Margin() = Margin(0.0, 0.0)

function getmaintenancemargin(position::Position, margin::Margin)
	return  position.absholdingcost * margin.maintenancemargin	
end


function totalmarginused(portfolio::Portfolio, margin::Margin)
	totalmargin = 0;
  for (security, position) in enumerate(portfolio)
    	totalmargin += getmaintenancemargin(position, margin)
	end
                   
    return totalmargin
end


function marginremaining(portfolio::Portfolio, margin::Margin)
	return totalportfoliovalue(portfolio) - unsettledcash(portfolio) - totalmarginused(portfolio, margin)
end


function getmarginremaining(portfolio::Portfolio, order::Order, margin::Margin)
			
	position = portfolio[order.symbol]
   
    direction = order.quantity < 0 ? :sell : :buy
    
    #Case 1: marginleft = remaining cash if order direction is same as position
    #Case2 : marginleft = 2 * current value of asset + cash if order direction is opposite to the position
    if islong(position)
      
        if direction == :buy 
          return marginremaining(portfolio, margin)
        
        elseif direction == :sell
          return 
              #portion of margin to close the existing position
              # + portion of margin to open the new position
              getmaintenancemargin(position, margin) +
                absholdingsvalue(position) * margin.initialmargin  +
                marginremaining(portfolio, margin)
        end
        
    elseif ishort(position)
   
        if direction == :buy
            return
              #portion of margin to close the existing position
              #+ portion of margin to open the new position
              getmaintenancemargin(position) +
              absholdingsvalue(position) * margin.initialmargin +
              marginremaining(portfolio, margin)
        end

		else direction == :sell
        return marginremaining(portfolio, margin)

    end
end


function getinitialmarginfororder(order::Order, margin::Margin, commission::Commission)
	orderfee = getorderfees(order, commission)
	ordervalue = getordervalue(order) * margin.initialmargin
	return ordervalue + sign(ordervalue) * orderfee
end

function getsufficientcapitalfororder(portfolio::Portfolio, order::Order, margin::Margin, commission::Commission)

	if order.quantity == 0 
    return true
  end
    
	freemargin = getmarginremaining(portfolio, security,  order, margin)
    initialmarginfororder = getinitialmarginfororder(order, margin, commission)

    #pro-rate the initial margin required for order based on how much has already been filled
    #percentunfilled = (abs(order.quantity) - abs(ticket.quantityfilled))/abs(order.quantity) 
      
    initialmarginrequiredforremainderoforder = percentunfilled*initialMarginRequiredForOrder

    if abs(initialmarginrequiredforremainderoforder) > freemargin 
    	#MSG
      return false
	  end

	return true     

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



