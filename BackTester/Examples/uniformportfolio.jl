# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


function initialize()	
	#setstartdate(DateTime("01/01/2016","dd/mm/yyyy"))
	#setenddate(DateTime("20/07/2016","dd/mmm/yyyy"))
	setcash(1000000.0)
	setresolution(Resolution(Daily))
	setcancelpolicy(CancelPolicy(EOD))
	setuniverse(["CNX_BANK","CNX_100","CNX_ENERGY"])
end

function beforeopen()
end

function ondata()

	universe = getuniverse()
	numsecurities = length(universe)
	
	for security in universe
		setholdingpct(security, 1.0/numsecurities)
	end	
	
	track("portfoliovalue", getportfoliovalue())

	return true
end

function beforeclose()
	cancelallorders()
end






