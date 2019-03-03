# HOW TO GET DATA OF ALL TRADED STOCKS? - For US markets

# Starting today, 
#1. Download bulk data for today
#2. Then download all historical data for available stocks [LONG TIME]
#3. Go Back one day,
#4. Download bulk data for today
#5. See if there is any symbol for which historical data is not available
#6. If YES, go to 1b and continue
#7. If NO, go to 2

using Dates
using HTTP
using DelimitedFiles

EODH_API_KEY = "5b87e1823a5034.40596433";

function downloadBulkData(date)
    downloadUrl = "http://eodhistoricaldata.com/api/eod-bulk-last-day/US?filter=extended&api_token=$(EODH_API_KEY)";
    file = "$(Base.source_dir())/USData/bulkUS_$(Dates.format(now(), "yyyymmdd"))"

    if date != nothing
	   downloadUrl = "http://eodhistoricaldata.com/api/eod-bulk-last-day/US?filter=extended&api_token=$(EODH_API_KEY)&date=$(date)";
       file = "$(Base.source_dir())/USData/bulkUS_$(Dates.format(DateTime(date), "yyyymmdd"))"         
    end

    #Create a file
    touch(file)
    download(downloadUrl, file)
end

function getValidSecurities(date)
    validSecurities = Vector{Dict{String, Any}}()
    
    file = "$(Base.source_dir())/USData/bulkUS_$(Dates.format(now(), "yyyymmdd"))"

    if date != nothing
       file = "$(Base.source_dir())/USData/bulkUS_$(Dates.format(DateTime(date), "yyyymmdd"))"         
    end

    try 
        (dlm_data, header) = readdlm(file, ',', Any, header=true)
        (nrows,ncols) = size(dlm_data)
        if nrows > 0
            for i = 1:nrows

                #if Volume data is available for the security for the date (non-zero)
                if(dlm_data[i, 11] > 0)
                    push!(tickers, Dict(
                            "dataset_code" => dlm_data[i,1], 
                            "database_code" => "US", 
                            "name" => dlm_data[i,2]))
                end
            end 
        end
    catch err
   		println(err)
    end

    return tickers
end


function alreadyExistsUSData(securitydata::Dict{String, Any}, priority::Int)
    
    securityid = getsecurityid(curatequandlsecurity(securitydata, "US"))

    if securityid == -1
        false
    else
        Mongoc.count_documents(datacollection(), Mongoc.BSON(Dict("securityid"=>securityid, "priority" => priority))) > 0 
    end
end

function updatedb_fromEODH_perUSsecurity(securitydata::Dict{String, Any}, priority::Int, refreshAll::Bool)

 	securityid = getsecurityid(curatequandlsecurity(securitydata, "US"))

    if securityid == -1
        Logger.warn("In updatedb_fromEODH_perUSsecurity(): security is not present. Attempting to INSERT instead!")
        
        #First generate a new id to 
        securityid = generateid()
        Logger.info("Inserting data for securityid:$(securityid)")
        
        success = insertsecuritydata(securitycollection(), securityid, securitydata, "EODH")
        if success == -1
            Logger.warn("updatedb_fromEODH_perUSsecurity():: Failed adding security data for securityid:$securityid")
        end
    end    
   
    #Attempt updating column data from the EODH
    success = updatecolumndata_fromEODH(datacollection(), securityid, securitydata, priority, refreshAll)
        
    if success==-1
        Logger.warn("updatedb_fromEODH_perUSsecurity(): Failed updating column data for securityid :$(securityid)") 
        return -1
    
    else 
        Logger.info("updatedb_fromEODH_persecurity(): Successful update for securityid:$(securityid)")    
        return 1 
    end 
end


function updatedb_fromEODH_US(date = nothing)
    try
    	#1. Download bulk data for date
    	bulkData = downloadBulkData(date) 

        #Get validSecurities with non-zero volume
    	validSecurities = getValidSecurities(date)

        if length(validSecurities) > 0
    		#Read all the symbols and do the historical data from symbol 
    		for validSecurity in validSecurities
    	        updatedb_fromEODH_perUSsecurity(validSecurity, 3, false)
            end
        end
    catch err
        println(err)
        println("Error while upating US data")
    end

end

function initialFullDownload()
    endDate = Date("2019-03-01")
    startDate = Date("1998-01-01")

    for date in endDate:Day(-1):startDate

        if dayofweek(date) != 0 && dayofweek(date) != 6

            #1. Download bulk data for date
            bulkData = downloadBulkData(date) 

            #Get validSecurities with non-zero volume
            validSecurities = getValidSecurities(date)

            if length(validSecurities) > 0
                #Read all the symbols and do the historical data from symbol 
                for validSecurity in validSecurities

                    if !alreadyExistsUSData(validSecurity, 3)
                        updatedb_fromEODH_perUSsecurity(validSecurity, 3, false)
                    end

                end
            end

        end

    end 
end

