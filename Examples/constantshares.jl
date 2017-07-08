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

function initialize(state)
	setstartdate(DateTime("01/01/2010","dd/mm/yyyy"))
	setenddate(DateTime("31/12/2011","dd/mmm/yyyy"))
	setcash(1000000.0)
	setresolution("Day")
	setcancelpolicy(CancelPolicy(EOD))
	#setbenchmark(56502)
	setuniverse(["RANASUG", "INDNIPPON"])
	#setuniverse(["CNX_NIFTY"])#,"CNX_100","CNX_ENERGY"]])
end

function beforeopen()
end

function ondata(data, state)
	universe = getuniverse()
	numsecurities = length(universe)

	for security in universe
		setholdingpct(security, 1.0/numsecurities)
	end

	track("Net Value", state.account.netvalue)

	# setholdingshares(56502, 100)
	setholdingpct(securitysymbol("RANASUG"), 0.95)
	setholdingpct(securitysymbol("INDNIPPON"), 0.95)
	# setholdingpct(getuniverse(), 0.95)

	track("portfoliovalue", state.account.netvalue)

end=#

function initialize(state)
	setstartdate(DateTime("01/01/2010","dd/mm/yyyy"))
	setenddate(DateTime("31/03/2010","dd/mmm/yyyy"))
	setcash(1000000.0)
	setresolution("Day")
	setcancelpolicy(CancelPolicy(EOD))
	setbenchmark("JBFIND")
	setuniverse("RANASUG")
end

function ondata(data, state)

	setholdingpct("CNX_NIFTY", 0.5)

	track("portfoliovalue", state.account.netvalue)
end
