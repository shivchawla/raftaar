
const PATH = Base.source_dir()
global dailydata_EODH_EODH_EODH = Dict{String, Any}()

"""
function to get the EODH API key
"""
function getapikey_EODH()
    if !ispath(PATH)
        Logger.error("Api Key is not initialized")
    end

    api_key = replace(readstring(PATH*"/token/auth_token_EODH"), "\n", "")
    
    if api_key == ""
        println("Empty API Key")
    else
        println("Using API key " , api_key)
    end

    return api_key

end

"""
function to set the EODH API key
"""
function setauthtoken_EODH(token::AbstractString)

    if length(token) != 20 && length(token) != 0
        Logger.error("Invalid Token : must be 20 characters long or be an empty")
    end
    
    requiredpath = PATH;

    if !ispath(requiredpath)
        println("Creating new directory")
        mkdir(requiredpath)
    end

    open(requiredpath*"/auth_token_EODH","w") do token_file
        write(token_file , token)
    end

    return nothing
end

"""
function to get the basic url for the Quandl
"""
function getbaseurl_EODH()
    return "http://eodhistoricaldata.com/api"
end

function downloadHTTPData(url)
    try 
        response = HTTP.get(url)
        
        if response.status == 200
            raw_data = IOBuffer(response.body)
            return JSON.parse(raw_data)
        end
    catch (err)
        if typeof(err) == HTTP.ExceptionRequest.StatusError && err.status == 404
            Logger.warn("downloadHTTPData(): Error - $(url) doesn't exist")
            return nothing
        else
            Logger.warn("downloadHTTPData(): $err");
            return nothing
        end
    end
end




"""
function to get daily updates from EODH
"""
function getdailydata_EODHfromfile(ticker::String, exchange::String, date::String)
    
    output = Dict{String, Any}()

    if !haskey(dailydata_EODH, exchange)
        
        # data and update the global dictionary
        # d = Dates.format(Date(date), "yyyymmdd")
        # month = Dates.month(d)
        # month = month > 9 ? string(month) : "0"*string(month)

        # day = Dates.day(d)
        # day = day > 9 ? string(day) : "0"*string(day)
 
        # year = string(Dates.year(d))
        formatted_date = Dates.format(Date(date), "yyyymmdd")

        try 
            f = Base.source_dir()*"/EODH_$(exchange)_$(formatted_date).csv"

            dlm_data = readdlm(f, ',', Any)
            (nrows,ncols) = size(dlm_data)
            if nrows > 0
                dailydata_EODH[exchange] = Dict{String, Any}()
                for i = 1:nrows
                    
                    #if data is available for the security for the date
                    if(string(dlm_data[i,3]) == date)
                        # Convert ticker to string(in case ticker is a number)
                        dailydata_EODH[exchange][string(dlm_data[i,1])] = [dlm_data[i, 3:end-3]]
                    end
                end 
            end
        catch err
           return (false, output)
        end

    end

    if haskey(dailydata_EODH, exchange)
        if haskey(dailydata_EODH[exchange], ticker)
            output["data"] = dailydata_EODH[exchange][ticker]
            output["columns"] = ["Date","Open","High","Low","Close","Adjusted_Close","Volume"]
        end
    end

    return (true, output)       
end


"""
function to get column and values data for a security 
"""
function getcolumndata_EODH(ticker::String, exchange::String; startdate="", enddate="", skip=0)
    #Updating logic to fetch data from the static file for latest updates
    if exchange == "NSE"
        if (startdate == enddate && startdate !="" && skip == 0)
            if Dates.dayofweek(Date(startdate)) <= 5 #weekday
                (found, data) = getdailydata_EODHfromfile(ticker, exchange, startdate)
                
                #if file exists and data found ()
                if found
                    return data
                end
            end
        end
    end

    #continue if data not found in single day file 
    #OR wider date range
    eodDataUrl = "$(getbaseurl_EODH())/eod/$(ticker).$(exchange)?api_token=$(getapikey_EODH())&from=$(startdate)&to=$(enddate)&fmt=json" 
    splitDataUrl = "$(getbaseurl_EODH())/splits/$(ticker).$(exchange)?api_token=$(getapikey_EODH())&from=$(startdate)&to=$(enddate)&fmt=json"
    dividendDataUrl = "$(getbaseurl_EODH())/div/$(ticker).$(exchange)?api_token=$(getapikey_EODH())&from=$(startdate)&to=$(enddate)&fmt=json"

    eodData = downloadHTTPData(eodDataUrl)
    splitData = downloadHTTPData(splitDataUrl)
    dividendData = downloadHTTPData(dividendDataUrl)
 
    if eodData == nothing || length(eodData) == 0
        Logger.warn("getdata(): No data available for EODH/$(exchange)/$(ticker)")
        return Dict{String, Any}()
    end
    
    splitDates = []
    if splitData != nothing
        try
           _s1 = [1/eval(parse(val["split"])) for val in splitData] 
           _s2 = [Date(val["date"]) for val in splitData]

           splitData = _s1
           splitDates = _s2 
        catch e
            splitData = []
            splitDates = []
        end
    end

    dividendDates = []
    if dividendData != nothing
        err  = false
        try 
            _d1 = [parse(val["value"]) for val in values(dividendData)] 
            _d2 = [Date(val["date"]) for val in values(dividendData)]

            dividendData = _d1
            dividendDates = _d2 
        catch e
            println("Dividend format is different now. It's an array now!! OOOPSS!!")
            err = true
        end

        if (err)
            try
                _d1 = [parse(val["value"]) for val in dividendData] 
                _d2 = [Date(val["date"]) for val in dividendData] 

                dividendData = _d1
                dividendDates = _d2 
            catch e
                dividendData = []
                dividendDates = []
            end
        end
    end

    lengthData = length(eodData)

    if (lengthData > 0)          
        data_keys = ["Date", "Open", "High", "Low", "Close", "Volume", "Adjustment Factor", "Adjustment Type"]        
        available_keys = ["Date", "Open", "High", "Low", "Close", "Volume"]

        data = Vector{Any}(length(eodData))

        nextAdjFactor = nothing
        nextAdjType = nothing

        for i in 1:length(eodData)

            date = Date(eodData[i]["date"])

            data_today = Vector{Any}(length(data_keys))
            
            for (j, key) in enumerate(available_keys)
                data_today[j] = eodData[i][lowercase(key)]
            end
            
            data_today[7] = nextAdjFactor
            data_today[8] = nextAdjType

            # Now compute next day factors
            nextAdjFactor = nothing
            nextAdjType = nothing

            splitIdxArr = find(splitDates.==date)
            dividendIdxArr = find(dividendDates.==date)

            if length(splitIdxArr) != 0
                nextAdjFactor = splitData[splitIdxArr[1]]
                nextAdjType = "13.0"
            elseif length(dividendIdxArr) != 0
                nextAdjFactor = 1 - dividendData[dividendIdxArr[1]]/eodData[i]["close"]
                nextAdjType = "17.0"
            end

            data[i] = data_today
        end

        if skip > 0
            data = length(data) > skip ? data[skip+1 : end] : []
        end

        if length(data) == 0
            return Dict{String, Any}()
        end

        return Dict{String, Any}(
            "data" => data,
            "columns" => data_keys)
    end   
    
end
