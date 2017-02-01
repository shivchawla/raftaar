# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.
using Raftaar

function initialize(state)	
	setstartdate(DateTime("01/01/2010","dd/mm/yyyy"))
	setenddate(DateTime("01/01/2012","dd/mmm/yyyy"))
	setcash(1000000.0)
	setresolution("Day")
	setcancelpolicy(CancelPolicy(EOD))
	#setbenchmark(56502)
	setuniverse([56502])
	#setuniverse(["CNX_NIFTY"])#,"CNX_100","CNX_ENERGY"]])
end

function beforeopen()
end

function ondata(data, state)

	#setholdingshares(56502, 100)	
	setholdingpct(56502, 0.95)	
	
	track("portfoliovalue", state.account.netvalue)

	return true
end

function beforeclose()
	cancelallorders()
end
