# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include("../Engine/API.jl")
#using API

function initialize()
	
	#setstartdate(DateTime("01/01/2016","dd/mm/yyyy"))
	#setenddate(DateTime("20/07/2016","dd/mmm/yyyy"))
	setcash(100000.0)
	setresolution(Resolution(Daily))
	setcancelpolicy(CancelPolicy(EOD))
	setuniverse(["CNX_BANK"])#,"CNX_100","CNX_ENERGY"]])
end

function beforeopen()
end

function ondata()
	port = getportfolio()
	for security in getuniverse()
		if port[security].quantity == 0
			#println("Placing order:$(security.symbol)")	
			placeorder(security, 1)
		end
	end	
	
	track("portfoliovalue", getportfoliovalue())

	return true
end

function beforeclose()
	cancelallorders()
end






