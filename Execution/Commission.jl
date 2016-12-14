# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

"""
Encapsulates the commission model
"""
type Commission
  model::CommissionModel
  value::Float64
end

"""
Empty Constructor
"""
Commission() = Commission(CommissionModel(PerTrade), 1.0)

"""
Function to get commission for the order
"""
function getcommission(order::Order, commission::Commission)
  if commission.model == CommissionModel(PerShare)
    return abs(order.quantity) * commission.value
  elseif commission.model == CommissionModel(PerTrade)
    return commission.value  
  end 

  return 0.0
end

"""
Function to get commission for the fill
"""
function getcommission(fill::OrderFill, commission::Commission)
    if commission.model == CommissionModel(PerValue)
        return abs(fill.fillquantity* fill.fillprice) * commission.value
    end
    
    return 0.0
end    
