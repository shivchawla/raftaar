
const PATH = Base.source_dir()
global dailydata = Dict{String, Any}()

"""
function to get the Quandl API key
"""
function getapikey_quandl()
    if !ispath(PATH)
        Logger.error("Api Key is not initialized")
    end

    api_key = replace(readstring(PATH*"/token/auth_token_quandl"), "\n", "")
    
    if api_key == ""
        println("Empty API Key")
    else
        println("Using API key " , api_key)
    end

    return api_key

end

"""
function to set the Quandl API key
"""
function setauthtoken_quandl(token::AbstractString)

    if length(token) != 20 && length(token) != 0
        Logger.error("Invalid Token : must be 20 characters long or be an empty")
    end
    
    requiredpath = PATH;

    if !ispath(requiredpath)
        println("Creating new directory")
        mkdir(requiredpath)
    end

    open(requiredpath*"/auth_token_quandl","w") do token_file
        write(token_file , token)
    end

    return nothing
end

"""
function to get the basic url for the Quandl
"""
function getbaseurl_quandl()
    return "https://www.quandl.com/api/"
end


"""
function to return the GET arguements for downloading the meta data for
the datasets in the particular database defined by database_code in QUANDL
"""
function getqueryargs(database_code:: AbstractString, per_page::Int, page::Int)

    queryargs = Dict{String, Any}("database_code" => database_code,
                              "per_page" => per_page,
                              "sort_by"=>"id",
                                "page" =>page,
                                "api_key" =>getapikey_quandl())

    return queryargs
end


"""
function to get the metadata from the metadata database 
"""
function getmetadata_OLD(database_code::AbstractString; per_page::Int = 100) 

    #first create initial request for single page.
    path = getbaseurl_quandl() * "v3/datasets.json?" 
    Logger.info("Downloading metadata from Quandl/$(database_code)")
    response = Requests.get(path, query = getqueryargs(database_code, per_page, 1))

    status = response.status
    if status != 200
        Logger.warn("Error in processing the query. Response status: $status ")
        return Dict{String, Any}()
    else
        #parse response 
        responseJSON = Requests.json(response)
        
        if (haskey(responseJSON,"meta"))
            return responseJSON["meta"]
        else
            Logger.warn("getmetadata(): Meta data not found for Quandl/$(database_code)")
            return Dict{String, Any}()
        end 
    end
end

function getmetadata(database_code::AbstractString) 

    source_dir = Base.source_dir()
    #first create initial request for single page.
    path = getbaseurl_quandl() * "v3/databases/$database_code/metadata?api_key=$(getapikey_quandl())" 
    Logger.info("Downloading metadata from Quandl/$(database_code)")
    
    zip_data=source_dir*"/tmp/zip_metadata_"*database_code
    fdir=source_dir*"/data"
    metadata_file = "$fdir/$(database_code)_metadata.csv"
    metadata = Vector{Dict{String, Any}}()
    

    try
        #download(path, zip_data)

        r = ZipFile.Reader(zip_data)
        
        if length(r.files) > 0
            f = r.files[1]
            println("Extracting Metadata file")
            
            open(metadata_file, "w") do file
                write(file, read(f, String))
            end

        end

        #Now process the metadata file
        if isfile(metadata_file)
            (data, headers) = readcsv(metadata_file, header=true)
            
            #code,name,description,refreshed_at,from_date,to_date                        

            for row in 1:size(data)[1]
                
                dict = Dict(
                        "database_code" => database_code,
                        "dataset_code" => string(data[row, find(headers.=="code")[1]]),
                        "name" => data[row, find(headers.=="name")[1]],
                        "description" => data[row, find(headers.=="description")[1]],
                        "refreshed_at" => data[row, find(headers.=="refreshed_at")[1]],
                        "oldest_available_date" => data[row, find(headers.=="from_date")[1]],
                        "newest_available_date" => data[row, find(headers.=="to_date")[1]])

                push!(metadata, dict)
            end

        end

    catch err
        println(err)
        Logger.warn("Error in processing/downloading metadata")
    end

    return metadata

end

"""
function to get daily updates from quandl
"""
function getdailydatafromfile(database_code::String, dataset_code::String, date::String)
    
    output = Dict{String, Any}()

    if !haskey(dailydata, database_code)
        # data and update the global dictionary
        d = Date(date)
        month = Dates.month(d)
        month = month > 9 ? string(month) : "0"*string(month)

        day = Dates.day(d)
        day = day > 9 ? string(day) : "0"*string(day)
 
        year = string(Dates.year(d))
        formatted_date = year*month*day

        try 
            #println("/$(database_code)_$(formatted_date).partial.csv")
            f = Base.source_dir()*"/$(database_code)_$(formatted_date).partial.csv"

            dlm_data = readdlm(f, ',', Any)
            (nrows,ncols) = size(dlm_data)
            if nrows > 0
                dailydata[database_code] = Dict{String, Any}()
                for i = 1:nrows
                    #if data is available for the security for the date
                    if(string(dlm_data[i,2]) == date)
                        # Convert ticker to string(in case ticker is a number)
                        dailydata[database_code][string(dlm_data[i,1])] = [dlm_data[i, 2:end]]
                    end
                end 
            end
        catch err
           return (false, output)
        end

    end

    if haskey(dailydata, database_code)
        if haskey(dailydata[database_code], dataset_code)
            output["data"] = dailydata[database_code][dataset_code]
            output["columns"] = ["Date","Open","High","Low","Close","Volume","Adjustment Factor","Adjustment Type"]
        end
    end

    return (true, output)       
end

"""
function to get column and values data for a security 
"""
function getcolumndata(params::Dict{String,Any}; startdate="", enddate="")
    database_code = params["database_code"]
    dataset_code = params["dataset_code"]
      
    #Updating logic to fetch data from the static file for latest updates
    if database_code == "XNSE"
        if (startdate == enddate && startdate !="")
            if Dates.dayofweek(Date(startdate)) <= 5 #weekday
                (found, data) = getdailydatafromfile(database_code, dataset_code, startdate)
                
                #if file exists and data found ()
                if found
                    return data
                end
            end
        end
    end

    #continue if data not found in single day file 
    #OR wider date range
    getdataurl = getbaseurl_quandl() *  "v3/datasets/" *database_code * "/" * dataset_code *".json" 
    queryargs = Dict{Any , Any}("api_key" => getapikey_quandl(), 
                                "start_date" => startdate,
                                "end_date" => enddate)
   
    Logger.info("Downloading column data from Quandl/$(database_code)/$(dataset_code)") 
    
    try
        response = HTTP.request("GET", getdataurl; query = queryargs)
        if response.status == 200
            raw_data = IOBuffer(response.body)
            dataJSON = JSON.parse(raw_data)
            if(haskey(dataJSON, "dataset"))
                if(haskey(dataJSON["dataset"], "data") && haskey(dataJSON["dataset"], "column_names"))
                    return Dict{String, Any}("data"=>dataJSON["dataset"]["data"], 
                                            "columns"=>dataJSON["dataset"]["column_names"])
                else 
                    Logger.warn("getdata(): No data available for Quandl/$(database_code)/$(dataset_code)")
                    return Dict{String, Any}()
                end
            else
                Logger.warn("getdata(): No data available for Quandl/$(database_code)/$(dataset_code)")
                return Dict{String, Any}()
            end
        else
            Logger.warn("getdata(): Error in processing the query. Response status: $status")
            return Dict{String, Any}()
            #throw(HTTP.ExceptionRequest.StatusError)
        end
    catch (err)
        if typeof(err) == HTTP.ExceptionRequest.StatusError && err.status == 404
            Logger.warn("getdata(): Error - $(dataset_code) doesn't exist")
            return Dict{String, Any}()
        else
            Logger.warn("getdata(): $err");
            return Dict{String, Any}()
        end
    end
end

function curatequandlsecurity(quandlsecurity::Dict{String,Any}, quandlsource::String)

    curateddata = Dict{String,Any}()

    if quandlsource == "NSE"
        curateddata["ticker"] = String(quandlsecurity["dataset_code"])
        curateddata["exchange"] = "NSE"
        curateddata["securitytype"] = "EQ"
        curateddata["country"] = "IN"
    elseif quandlsource == "XNSE"    
        
        #XNSE has dataset codes as ticker_ADJ or ticker_UADJ
        dataset_code = quandlsecurity["dataset_code"]
        
        if(contains(dataset_code, "_ADJ")) 
            curateddata["ticker"] = replace(dataset_code, "_ADJ", "")
        elseif (contains(dataset_code, "_UADJ"))
            curateddata["ticker"] = replace(dataset_code, "_UADJ", "")
        else 
            curateddata["ticker"] = String(dataset_code)
        end

        curateddata["exchange"] = "NSE"
        curateddata["securitytype"] = "EQ"
        curateddata["country"] = "IN"
    end

    return curateddata
end

