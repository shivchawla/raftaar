

function initialize()
	
	#setstartdate(DateTime("01/01/2016","dd/mm/yyyy"))
	#setenddate(DateTime("20/07/2016","dd/mmm/yyyy"))
	setcash(100000.0)
	setresolution(Daily)
	setcancelpolicy(EOD)
	setuniverse("GOOG/NASDAQ_QQQ")
end

function beforeopen()
	
end

function ondata()

	port = getportfolio()
	for security in getuniverse()
		if port[security].quantity == 0	
			placeorder(security, 1)
		end
		
	end	
end

function beforeclose()
	cancelallorders()
end






