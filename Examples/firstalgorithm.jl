
function initialize()
	
	#setstartdate(DateTime("01/01/2016","dd/mm/yyyy"))
	#setenddate(DateTime("20/07/2016","dd/mmm/yyyy"))
	setcash(100000.0)
	setresolution(Resolution(Daily))
	setcancelpolicy(EOD)
	setuniverse("GOOG/NASDAQ_QQQ")
end

function beforeopen()
	
end

function ondata()

	port = getportfolio()

	for security in getuniverse()
		#println(security)
		#println(port[security].quantity)
		
			#println("Ordering")
			placeorder(security, 1)
		
	end
	
	#println("I am in ondata()")
end


function beforeclose()
	cancelallorders();
end






