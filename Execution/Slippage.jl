# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("Order.jl")
#include("../Security/Security.jl")

@enum SlippageType ConstantSlippage SpreadSlippage

"""
Slippage Model
"""
type Slippage
	model::SlippageType
	value::Float64
end

"""
Empty Constructor
"""
Slippage() = Slippage(SlippageType(ConstantSlippage), 0.001)

"""
Function to get slippage for the order based on latest price and slippage model
"""
function getslippage(order::Order, slippage::Slippage, latestprice::Float64)
	if slippage.model == SlippageType(ConstantSlippage)
		return getslippageforconstantslippagemodel(slippage.value, latestprice)
	elseif slippage.model == SlippageType(SpreadSlippage)
		return getslippageforspreadslippagemodel(order, security, slippage.value)
	end	
end

"""
Function to get slippage for constant slippage model
"""
function getslippageforconstantslippagemodel(value::Float64, latestprice::Float64)
	return latestprice * value
end


#function getslippageforspreadslippagemodel(order::Order, value::Float64)

	#Return the half of bid-ask spread3
#end