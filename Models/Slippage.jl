@enum SlippageType
	ConstantSlippage = 1
	SpreadSlippage = 2


type SlippageModel
	model::SlippageType
	value::Float64
end

function getslippage(order::Order, security::Security, slippage::SlippageModel)
	if slippage.model == SlippageType.ConstantSlippage
		return getslippageforconstantslippagemodel(order, security, slippage.value)
	else if slippage.model == SlippageType.SpreadSlippage
		return getslippageforspreadslippagemodel(order, security, slippage.value)
end

function getslippageforconstantslippagemodel(order::Order, security::Security, value::Float64)
	lastprice = getlastprice(security)
	return lastprice * value
end


function getslippageforspreadslippagemodel(order::Order, security::Security, value::Float64)

	"Return the half of bid-ask spread"
end