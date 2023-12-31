# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include(\"../Engine/API.jl\")
#using API

# using BackTester

function initialize(state)
	#setstartdate(DateTime(\"01/01/2016\",\"dd/mm/yyyy\"))
	#setenddate(DateTime(\"20/07/2016\",\"dd/mmm/yyyy\"))
	setuniverse(["TCS"]) #,\"CNX_100\",\"CNX_ENERGY\"]])
	setcancelpolicy("EOD")
	setresolution("Day")
	setcash(1000000.0)

end

function beforeopen(state)
end

function ondata(data, state)

	setholdingpct(securitysymbol("TCS"), 0.2)

	track("Net Value", state.account.netvalue)

end

function beforeclose(state)
	cancelallorders()
end
