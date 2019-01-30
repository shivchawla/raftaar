
"""
function to get security 
"""
function getsecurity(securityid::Int)
    return getsecurity(securitycollection(), securityid)
end

"""
function to get security id based on symbol/securitytype/exchange
"""
function getsecurityid(ticker::String; 
                        securitytype::String="EQ", 
                        exchange::String="NSE",
                        country::String="IN")
   
    if ticker == ""
        Logger.warn("In getsecurityid(): Empty symbol provided. Unable to create a securityid")
        return -1
    end    
    
    Logger.info("In getsecurityid(): Finding for symbol:$ticker")

    securityid = getsecurityid(securitycollection(), ticker, 
                                    securitytype,
                                    exchange,
                                    country)

    ## MAKE sure that security is consistent

    #Make sure the security id corresponds to the right security
    if securityid != -1
        security = getsecurity(securityid)
        if (security.symbol.ticker != ticker 
            || security.exchange != exchange 
            || security.securitytype != securitytype
            || security.country != country) 
            Logger.warn("INCONSISTENT SECURITY for securityid: $securityid and ticker: $ticker")
        end
    end

    return securityid

    #=if securityid == -1
        securityid = generateid()
    end=#

    #return securityid    

end

function getsecurityid(curateddata::Dict{String,Any})

    try
        ticker = get(curateddata,"ticker", "")
        exchange = get(curateddata, "exchange", "NSE")
        country = get(curateddata, "country", "IN")
        securitytype = get(curateddata, "securitytype", "EQ")

        return getsecurityid(ticker, securitytype = securitytype,
                                    exchange = exchange,
                                    country = country)
    catch err
        println(err)
        return -1
    end
end

function generateid()
    #Here create a new
    
    #find the count in the security collection
    ct = count(securitycollection()) + 1

    file = open(abspath(PATH*"/randomsequence.txt"),"r")
    lines = readlines(file)
    close(file)

    id = parse(Int, lines[ct])
    while(ifsecurityidexists(securitycollection(), id))
        ct = ct+1
        id = parse(Int, lines[ct])
    end 
        
    return id

end


"""
function to insert price data from quandl to database 
"""
function insertdb_fromquandl(datasource::String; priority::Int = 1)
    #Get meta data from quandl databases
    #get security data from quandl databases
    #for each security insert data in security collection
    #and data collection
    
    metadata = getmetadata(datasource)

    if metadata == Vecotor{Dict{String,Any}}()
        Logger.warn("insertdb_forquandl(): No meta data found for Quandl/$(datasource)")
        Logger.warn("insertdb_forquandl(): Insert Failed!!!")
        return 
    else
        
        for securitydata in metadata
            securitydata = securities[j]
            insertdb_fromquandl_persecurity(securitydata, datasource, priority)
        end

    end 
end

"""
function to insert data from quandl to database 
    based on security data from quandl
"""
function insertdb_fromquandl_persecurity(securitydata::Dict{String,Any}, datasource::String, priority::Int)
    
    #Get or create security id for this instrument 
    #and create a dcument in security collection if it doesn't exist
    #If it does, add the source security dictionary as an embedded document  
    
    if(datasource == "XNSE" && !contains(securitydata["dataset_code"],"_UADJ"))
        Logger.warn("In insertdb_fromquandl_persecurity(): Can not 'Adjusted Data' for datasource: $(datasource). ABORTING!!")
        return
    end

    securityid = getsecurityid(curatequandlsecurity(securitydata, datasource))

    if securityid != -1
        Logger.warn("In insertdb_fromquandl_persecurity(): Can not insert data for securityid: $(securityid). ALREADY EXISTS!!")
        return
    end

    #First generate a new id to 
    securityid = generateid()
    Logger.info("Inserting data for securityid:$(securityid)")
    
    if (insertsecuritydata_fromquandl(securitycollection(), securityid, securitydata) != -1)   
        if (insertcolumndata_fromquandl(datacollection(), securityid, securitydata, priority) != -1)
            Logger.info("Successfuly inserted data for securityid: $(securityid)")
        else
            Logger.warn("insertcolumndata_fromquandl():: Failed adding column data for securityid:$securityid")
        end    
    else
        Logger.warn("insertsecuritydata_fromquandl():: Failed adding security data for securityid:$securityid")
        Logger.warn("Skipping adding column data too for security: $(securityid)")
    end
end

function updatedb_fromquandl(datasource::String; priority::Int=1, refreshAll::Bool = false)
    
    #Get meta data from quandl databases
   
    metadata = getmetadata(datasource)

    if metadata == Vector{Dict{String,Any}}()
        Logger.warn("updatedb_forquandl(): No meta data found for Quandl/$(datasource)")
        Logger.warn("updatedb_forquandl(): Update Failed!!!")
        return 
    
    else
        
        for securitydata in metadata

            # first try to search document for this security 
            # data in the collection. if found, then proceed with update
            # else insert as a new security
            success  = updatedb_fromquandl_persecurity(securitydata, datasource, priority, refreshAll)
            println("")

        end
    end
end

"""
function to update data from quandl to database 
    based on security data from quandl
"""
function updatedb_fromquandl_persecurity(securitydata::Dict{String,Any}, datasource::String, priority::Int, refreshAll::Bool)

    # For XNSE source, don't insert/update adjusted price data in the database
    if(datasource == "XNSE" && !contains(securitydata["dataset_code"],"_UADJ"))
        Logger.warn("In updatedb_fromquandl_persecurity(): Can not update 'Adjusted Data' for datasource: $(datasource). SKIPPING Adjusted Data!!")
        return
    end

    securityid = getsecurityid(curatequandlsecurity(securitydata, datasource))

    if securityid == -1
        Logger.warn("In updatedb_fromquandl_persecurity(): security is not present. Attempting to INSERT instead!")
        return insertdb_fromquandl_persecurity(securitydata, datasource, priority)
    end    

    Logger.info("Updating data for securityid:$(securityid)")
    success = updatesecuritydata_fromquandl(securitycollection(), securityid, securitydata)
    
    if success == -1
        Logger.warn("updatedb_fromquandl(): Failed updating security data for securityid :$(securityid)")
        Logger.warn("Skipping updating the column data for securityid :$(securityid)")
        return -1
    
    elseif success == 1 || success ==2
        success = updatecolumndata_fromquandl(datacollection(), securityid, securitydata, priority, refreshAll)
        
        if success==-1
            Logger.warn("updatedb_fromquandl(): Failed updating column data for securityid :$(securityid)") 
            return -1
        
        else 
            Logger.info("updatedb_fromquandl(): Successful update for securityid:$(securityid)")    
            return 1 
        end 

    #elseif success == 2
    #    Logger.info("updatedb_fromquandl(): Data is up-to-date for securityid: $(securityid)")  
    end
end


function update_fromquandldeb_securitylist(alldata)
    all_securities_data = alldata[1]
    header_data = alldata[2]

    (nrows, ncols) = size(all_securities_data)
    for i in 1:nrows
        single_security_data = vec(all_securities_data[i,:])    
        
        data_dict = Dict{String, Any}()
        for (j, field) in enumerate(vec(header_data))
            data_dict[string(field)] = typeof(single_security_data[j]) == SubString{String} ? String(single_security_data[j]) : single_security_data[j]
        end

        if haskey(data_dict, "NSE_ID")

            ticker = string(data_dict["NSE_ID"])
            securityid = getsecurityid(ticker)

            if securityid == -1 && data_dict["NSE_ID"] != "" && data_dict["NSE_ID"] != nothing 
                securityid = generateid()
                tmp_data = Dict{String, Any}(
                    "database_code" => "NSE",
                    "dataset_code" => data_dict["NSE_ID"]
                )
                
                insertsecuritydata_fromquandl(securitycollection(), securityid, tmp_data)
            end

            
            updatesecurity_fromquandldeb(securitycollection(), securityid, data_dict)
        end

        #break
    end
end

function updatedb_fromNSEIndices_security(securitydata::Dict{String, Any}, priority::Int, refreshAll::Bool)
    datasourceurl = "http://www.niftyindices.com/Backpage.aspx/getHistoricaldatatabletoString"

    headers = Dict("Content-Type"=>"application/json")
 
    body = Dict("name"=>securitydata["name"], 
        "startDate"=>"01-Jan-2007", 
        "endDate"=>Dates.format(Date(now()),"dd-u-yyyy"))

    columndata = nothing
    try
        r = HTTP.post(datasourceurl, headers, JSON.json(body))
        output = JSON.parse(JSON.parse(String(r.body))["d"])
        #println(output)

        dataColumns = ["HistoricalDate", "OPEN", "HIGH", "LOW", "CLOSE"]
        outputColumns = ["Date", "Open", "High", "Low", "Close"]
        
        matrix = Vector{Vector{Any}}(length(output))

        for (i,data_per_day) in enumerate(output)
            d = Vector{Any}()
            for (j,column) in enumerate(dataColumns)
                push!(d, j==1 ? string(Date(data_per_day[column], "dd u yyyy")) : parse(data_per_day[column]))
            end

            matrix[i] = d
        end

        if matrix == nothing
            error("No data found for $(securitydata["name"]) in NSE_indices")
        end

        columndata = Dict("columns" => outputColumns, "data" => matrix)

        securityid = getsecurityid(securitydata["ticker"])
        if securityid == -1
            #First generate a new id to 
            securityid = generateid()
            Logger.info("Inserting data for securityid:$(securityid)")
            
            if (insertsecuritydata_generic(securitycollection(), securityid, securitydata) != -1)   
                if (insertcolumndata_generic(datacollection(), securityid, securitydata, columndata, priority) != -1)
                    Logger.info("Successfuly inserted data for securityid: $(securityid)")
                else
                    Logger.warn("insertcolumndata_fromquandl():: Failed adding column data for securityid:$securityid")
                end    
            end
        else 
            updatecolumndata_generic(datacollection(), securityid, securitydata, columndata, priority, refreshAll)
        end
    catch err
        println(err)
    end
end


function updatedb_fromNSEIndices(allIndices::Dict{String, Any}; priority::Int=0, refreshAll::Bool = false)

    for (ticker, name) in allIndices
        println("$ticker: $name")
        securitydata = Dict{String, Any}("ticker" => ticker, 
            "name" => name, 
            "database_code" => "NSE_Indices", 
            "dataset_code" => ticker,
            "description" => "Historical Index Values for $name")

        updatedb_fromNSEIndices_security(securitydata, priority, refreshAll)
    end
end


"""
function to update data from quandl to database 
    based on security data from quandl
"""
function updatedb_fromEODH_persecurity(securitydata::Dict{String,Any}, datasource::String, priority::Int, refreshAll::Bool)

    #used NSE/securty-data from Quandl
    securityid = getsecurityid(curatequandlsecurity(securitydata, datasource))
    
    println("updatedb_fromEODH_persecurity")
    println(securityid)
    
    return 

    if securityid == -1
        Logger.warn("In updatedb_fromEODH_persecurity(): security is not present. Attempting to INSERT instead!")
        
        #First generate a new id to 
        securityid = generateid()
        Logger.info("Inserting data for securityid:$(securityid)")
        
        success = insertsecuritydata_fromquandl(securitycollection(), securityid, securitydata)
        if success == -1
            Logger.warn("updatedb_fromEODH_persecurity():: Failed adding security data for securityid:$securityid")
        end
    end    
   
    println(securityid)
    println(securitydata)
    return

    #Attempt updating column data from the EODH
    success = updatecolumndata_fromEODH(datacollection(), securityid, securitydata, priority, refreshAll)
        
    if success==-1
        Logger.warn("updatedb_fromEODH_persecurity(): Failed updating column data for securityid :$(securityid)") 
        return -1
    
    else 
        Logger.info("updatedb_fromEODH_persecurity(): Successful update for securityid:$(securityid)")    
        return 1 
    end 
    
end


function updatedb_fromEODH(datasource::String; priority::Int=1, refreshAll::Bool = false)
    
    #Get meta data from quandl databases (even in case of EODH -- NSE/Quandl is free)
    # But as of 2019-01-09, Quandl/NSE is deprecated, so don't download any meta-data
    # and use the old data
    metadata = getmetadata("NSE", refetch = false)

    if metadata == Vector{Dict{String,Any}}()
        Logger.warn("updatedb_fromEODH(): No meta data found for Quandl/$(datasource)")
        Logger.warn("updatedb_fromEODH(): Update Failed!!!")
        return 
    
    else
        
        for securitydata in metadata

            # first try to search document for this security 
            # data in the collection. if found, then proceed with update
            # else insert as a new security
            success  = updatedb_fromEODH_persecurity(securitydata, datasource, priority, refreshAll)
            println("")
        end
    end
end
