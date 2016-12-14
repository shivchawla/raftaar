# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Security/Security.jl")


"""
Slippage Model
"""
type Slippage
	model::SlippageModel
	value::Float64
end

"""
Empty Constructor
"""
Slippage() = Slippage(SlippageModel(Variable), 0.001)

"""
Function to get slippage for the order based on latest price and slippage model
"""
function getslippage(order::Order, slippage::Slippage, latestprice::Float64)
	if slippage.model == SlippageModel(Variable)
		return getslippageforvariableslippagemodel(slippage.value, latestprice)
	elseif slippage.model == SlippageModel(Fixed)
		return getslippageforspreadslippagemodel(order, security, slippage.value)
	end	
end

"""
Function to get slippage for constant slippage model
"""
function getslippageforvariableslippagemodel(value::Float64, latestprice::Float64)
	return latestprice * value
end


#function getslippageforspreadslippagemodel(order::Order, value::Float64)

	#Return the half of bid-ask spread3
#end