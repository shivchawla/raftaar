function downloadFundamentalData(ticker::String, country::String)
	
	tkr = ""
	
	#Fetch the fundamental data from eodh
    if country == "US"
    	tkr =  "$(ticker).US"
	elseif country == "IN"
		tkr =  "$(ticker).NSE"
	end
	
	if tkr != ""
	    downloadUrl = "https://eodhistoricaldata.com/api/fundamentals/$(tkr)?api_token=$(EODH_API_KEY)"
	  
	    file = "$(Base.source_dir())/USFundmentalData/$(tkr)/$(tkr)_$(Dates.format(now(), "yyyymmdd"))"
	    # "https://eodhistoricaldata.com/api/fundamentals/AAPL.US?api_token={your_api_key}

	    #Create a file
	    touch(file)
	    download(downloadUrl, file)

	    return file
    end
end

function updateFundamentalAll(;skipExist::Bool = true)
	#1. Get all the tickers in batch of 10 from DB
	#2. Download from EODH in ticker specific folder
	#3. Rename the older data by date
	#4. Dump the file in database (and other security specific info)

	skp = 0 #Number of documents to skip
	lmt = 10 #Limit on number of documents at once

	numSecurities = Mongoc.count_documents(securitycollection(), Mongoc.BSON(Dict()))

	while skp < numSecurities
		docs = Mongoc.collect(Mongoc.find(securitycollection(), Mongoc.BSON(Dict()), Mongoc(Dict("skip" => skp, "limit" => lmt)))) 

		for d in docs
			doc = JSON.parse(Mongoc.as_json(d))

	        securityid = doc["securityid"]
	        ticker = doc["ticker"]
	        country = doc["country"]

        	fundamentalFile = updateFundamentalForTicker(ticker, country, securityid, skipExist = skipExist)
        	
        end

        #Increase the skip counter
        skp = skp + 10

    end

end

function updateFundamentalForTicker(ticker::String, country::String == "US", securityid::Int64 = -1; skipExist::Bool = true)
	
	if securityid == -1
		securityid = getsecurityid(ticker, exchange = country == "US" ? "US" : "NSE", country = country)
	end

	if securityid == -1
		println("OOPS! No security found for $(ticker)/$(country)")
		return
	end

	exists = Mongoc.count(fundamentaldatacollection(), Mongoc.BSON(Dict("securityid" => securityid))) > 0

	if exists && skipExist
		println("Skipping as data exists and skipExists is true")
		return
	end

	fData = nothing
	if ticker != ""
		fundamentalFile = downloadFundamentalData(tkr)
		fData = JSON.parseFile(fundamentalFile)
	end

	if fData != nothing
		if exists
			Mongoc.update_one(fundamentaldatacollection(), Mongoc.BSON(Dict("securityid" => securityid)), Mongoc.BSON(fData))
		else
			Mongoc.insert_one(fundamentaldatacollection(), Mongoc.BSON(Dict("securityid" => securityid, "data" => fData)))
		end 	
	end
end