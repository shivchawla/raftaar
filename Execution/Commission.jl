
include("Order.jl")

@enum CommissionType PerTrade PerShare PerValue

type Commission
  model::CommissionType
  value::Float64
end

Commission() = Commission(CommissionType(PerTrade), 1.0)

function getcommission(order::Order, commission::Commission)
  if commission.model == CommissionType(PerShare)
    return abs(order.quantity) * commission.value
  elseif commission.model == CommissionType(PerTrade)
    return commission.value  
  end 

  return 0.0
end

function getcommission(fill::OrderFill, commission::Commission)
    if commission.model == CommissionType(PerValue)
        return abs(fill.fillquantity* fill.fillprice) * commission.value
    end
    
    return 0.0
end    
