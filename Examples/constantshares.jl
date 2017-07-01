# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.
using Raftaar
#=function initialize(state)	
	setcash(1000000.0)
	setresolution("Day")
	setcancelpolicy(CancelPolicy(EOD))
	#setuniverse(["CNX_BANK","CNX_100","CNX_ENERGY"])
	setuniverse([818, 99246, 92665, 58793])
end

function ondata(data, state)

	universe = getuniverse()
	numsecurities = length(universe)
	
	for security in universe
		setholdingpct(security, 1.0/numsecurities)
	end	
	
	track("Net Value", state.account.netvalue)

end=#

function initialize(state)	
	#setstartdate(DateTime("01/01/2016","dd/mm/yyyy"))
	#setenddate(DateTime("20/07/2016","dd/mmm/yyyy"))
	setcash(1000000.0)
	setresolution("Day")
	setcancelpolicy(CancelPolicy(EOD))
	setbenchmark("CNX_BANK")
	setuniverse("CNX_NIFTY")
end

function ondata(data, state)

	setholdingpct("CNX_NIFTY", 0.5)	
	
	track("portfoliovalue", state.account.netvalue)
end
        