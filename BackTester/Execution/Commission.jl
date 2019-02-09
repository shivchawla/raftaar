# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

"""
Encapsulates the commission model
"""
mutable struct Commission
  model::CommissionModel
  value::Float64
end

"""
Empty Constructor
"""
Commission() = Commission(PerTrade, 1.0)

Commission(data::Dict{String, Any}) = Commission(eval(parse(data["model"])), data["value"])

"""
Function to get commission for the order
"""
function getcommission(order::Order, commission::Commission)
  if commission.model == PerShare
    return round(abs(order.quantity) * commission.value, digits = 2)
  elseif commission.model == PerTrade
    return round(commission.value, digits = 2)
  end

  return 0.0
end

"""
Function to get commission for the fill
"""
function getcommission(fill::OrderFill, commission::Commission)
    if commission.model == PerTrade
        return min(20.0, round(abs(fill.fillquantity* fill.fillprice) * commission.value, digits = 2))
    end

    return 0.0
end

function getcommission(fillquantity::Int, fillprice::Float64, commission::Commission)
    if commission.model == PerTrade
        return min(20.0, round(abs(fillquantity*fillprice) * commission.value, digits = 2))
    end

    return 0.0
end

function serialize(commission::Commission)
  return Dict{String, Any}("model" => string(commission.model),
                            "value" => commission.value)
end

==(cm1::Commission, cm2::Commission) = cm1.model == cm2.model && cm1.value == cm2.value
