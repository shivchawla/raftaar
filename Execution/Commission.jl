# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


@enum CommissionType PerTrade PerShare PerValue

"""
Encapsulates the commission model
"""
type Commission
  model::CommissionType
  value::Float64
end

"""
Empty Constructor
"""
Commission() = Commission(CommissionType(PerTrade), 1.0)

"""
Function to get commission for the order
"""
function getcommission(order::Order, commission::Commission)
  if commission.model == CommissionType(PerShare)
    return abs(order.quantity) * commission.value
  elseif commission.model == CommissionType(PerTrade)
    return commission.value  
  end 

  return 0.0
end

"""
Function to get commission for the fill
"""
function getcommission(fill::OrderFill, commission::Commission)
    if commission.model == CommissionType(PerValue)
        return abs(fill.fillquantity* fill.fillprice) * commission.value
    end
    
    return 0.0
end    
