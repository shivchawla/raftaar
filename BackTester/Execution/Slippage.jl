# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Security/Security.jl")


"""
Slippage Model
"""
mutable struct Slippage
	model::SlippageModel
	value::Float64
end

"""
Empty Constructor
"""
Slippage() = Slippage(Variable, 0.001)

Slippage(data::Dict{String, Any}) = Slippage(eval(parse(data["model"])), data["value"])

"""
Function to get slippage for the order based on latest price and slippage model
"""
function getslippage(order::Order, slippage::Slippage, latestprice::Float64)
	if slippage.model == Variable
		return getslippageforvariableslippagemodel(slippage.value, latestprice)
	elseif slippage.model == Fixed
		return getslippageforspreadslippagemodel(order, security, slippage.value)
	end
end

"""
Function to get slippage for constant slippage model
"""
function getslippageforvariableslippagemodel(value::Float64, latestprice::Float64)
	return round(latestprice * value, digits = 2)
end


#function getslippageforspreadslippagemodel(order::Order, value::Float64)

	#Return the half of bid-ask spread3
#end

function serialize(slippage::Slippage)
  return Dict{String, Any}("model" => string(slippage.model),
                            "value" => slippage.value)
end

==(spg1::Slippage, spg2::Slippage) = spg1.value == spg2.value && spg1.model == spg2.model
