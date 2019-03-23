function getlatestdate(data)
    date_column = findall(isequal("Date"), data["columns"])
    if(length(date_column) > 0)
        date_column = date_column[1]
    else
        return
    end 
    nvals = length(data["values"])
    dates = Vector{String}(undef, nvals)
    for i=1:nvals
        dates[i] = data["values"][i][date_column]
    end

    return sort(dates)[length(dates)]
end

"""

"""
function checkduplicates_and_update(datacollection, query, data)
    date_column = findall(isequal("Date"), data["columns"])
    
    if(length(date_column) > 0)
        date_column = date_column[1]
    else
        return false
    end 
    vals = data["values"]
    nvals = length(vals)
    vals_dict = Dict{String, Vector{Any}}()
    for i=1:nvals
        vals_dict[vals[i][date_column]] = vals[i] 
    end

    num_unique_dates = length(keys(vals_dict))
    if  num_unique_dates!= nvals
        updated_vals = Vector{Any}(undef, num_unique_dates)
        for (i,key) in enumerate(sort(collect(keys(vals_dict))))
            updated_vals[i] = vals_dict[key]
        end 
        Mongoc.update_one(datacollection, Mongoc.BSON(query), Mongoc.BSON(Dict("\$set"=>Dict("data.values"=>updated_vals)))) 
        return true
    end

    return false
end

"""
function to filter database on year
"""
function filterdata_byyear(data, datecolumn::Int = 1)
    len = length(data)
    dataperyear = Dict{Int, Array{Any, 1}}()
    previousdate = 0
    arr = Array{Any , 1}()
    
    for i = 1:len
        datarow = data[i]
        
        #date format is assumed to be yyyy-mm-dd
        #FIX: make it more general laster
        date = parse(Int, (split(datarow[datecolumn] , "-")[1]))

        if date == previousdate
           # Adding one row of data at a time
           # FIX: Improve logic by pushing bulk data in the new array
           push!(arr, datarow) 
        else

            #Initialize the array here for the first time
            arr = Array{Any, 1}()
            previousdate = date

            setindex!(dataperyear, arr, previousdate)
            
            push!(arr, datarow)
        end    
    end

    return dataperyear
end

"""
Update list of securities in db from deb tickers(deb_ticker.csv)
"""
function updatesecurity_fromquandldeb(securitycollection::Mongoc.Collection, securityid::Int, debdata::Dict{String,Any})

    if(Mongoc.count_documents(securitycollection, ("securityid" => securityid)) != 0)
       Logger.info("Updating data for SecurityId: $(securityid) for DEB data") 
       Mongoc.update_one(securitycollection, Mongoc.BSON(Dict("securityid" => securityid)), Mongoc.BSON(Dict("\$set"=>Dict("detail"=>debdata))))
    else
        Logger.warn("SecurityId:$(securityid) doesn't exist!!")
    end
        end

"""
Insert data (true fields) in mongodb
"""
function insertcolumndata_fromquandl(datacollection::Mongoc.Collection, securityid::Int, securitydata::Dict{String,Any}, priority::Int)

    Logger.info("Inserting column data for securityid:$securityid")
    
    if (Mongoc.count_documents(datacollection, ("securityid"=>securityid, "priority"=>priority, "datasource.database_code"=>securitydata["database_code"])) > 0)
        Logger.warn("In insertcolumndata_fromquandl(), securityid $securityid for sourcename: $(securitydata["database_code"]) at priority: $(priority) already exists in the database.")
        # THIS should not happen
        # But in  case this happens....REMOVE ALL DATA for data tables
        Logger.info("In insertcolumndata_fromquandl(): DELETING data for securityid $securityid for sourcename: $(securitydata["database_code"]) at priority: $(priority) fromt the database") 
        delete(datacollection, ("securityid"=>securityid, "priority"=>priority, "datasource.database_code"=>securitydata["database_code"]))
        
        #AND CONTINUE
    end
       
    #Get columnar data from quandl source
    data_quandl = getcolumndata(securitydata)
    
    if data_quandl != Dict{String, Any}()
        #get true data and columns
        columns = data_quandl["columns"]
        actualdata = data_quandl["data"] 

        #Convert data into year chunks for our data model
        data_byyear = filterdata_byyear(actualdata)
    
        for k in keys(data_byyear)
            array = get(data_byyear , k, "NULL")

            if array == "NULL"
                Logger.warn("insertcolumndata_fromquandl(): No data found for year: $(k)")
                continue
            else
                sourcedata = securitydata
                sourcedata["sourcename"] = "quandl_"*securitydata["database_code"]
                toinsertdict = Dict{String ,Any}("securityid" => securityid,
                                                "year" => k,
                                                "priority" => priority,
                                                "datasource" => sourcedata,
                                                "data" => Dict{String, Any}("columns"=>columns, "values"=>array))
                Mongoc.insert_one(datacollection , Mongoc.BSON(toinsertdict))
            end
            
        end

        return 1
    else
        Logger.warn("insertcolumndata_fromquandl(): No data to insert for securityid:$(securityid)")
        return -1
    end
end


"""
Insert security data in mongodb
"""
function insertsecuritydata_fromquandl(securitycollection::Mongoc.Collection, securityid::Int, sourcedata::Dict{String,Any}) 
    
    Logger.info("Inserting security data for securityid:$securityid")

    sourcedata["sourcename"] = "quandl_"*sourcedata["database_code"]
    
    if(Mongoc.count_documents(securitycollection, ("securityid"=>securityid)) == 0)

        #aqticker = country*securitytype*string(securityid)*exchange

        curateddata = curatequandlsecurity(sourcedata, sourcedata["database_code"])

        # Here insert if security didn't exist
        securitydata = Dict{String , Any}("securityid" => securityid,
            #"ISIN" => ISIN,
            "ticker" => curateddata["ticker"],
            "exchange" => curateddata["exchange"],
            "securitytype" => curateddata["securitytype"],
            "country" => curateddata["country"],
            "name" => get(sourcedata,"name","NULL"),
            "datasources" => Vector{Dict{String,Any}}([sourcedata]))
        
        Mongoc.insert_one(securitycollection, Mongoc.BSON(securitydata))

        return 1
    
    else 
        
        Logger.info("In insertsecuritydata_fromquandl(): securityid: $(securityid) already exists in the database")
        Logger.info("Adding source information from quandl/$(sourcedata["database_code"])")
        
        query = Dict("securityid"=>securityid, 
                                    "datasources"=>Dict("\$elemMatch"=>Dict("sourcename"=>"quandl_"*sourcedata["database_code"],
                            "dataset_code"=>sourcedata["dataset_code"])))
        if(Mongoc.count_documents(securitycollection, Mongoc.BSON(query)) == 0)
       
            # Add another data source
            Mongoc.update_one(securitycollection, Mongoc.BSON(Dict("securityid"=>securityid)), Mongoc.BSON(Dict("\$push"=>Dict("datasources"=>sourcedata))))
                #Dict("datasources"=>Dict("sourcename"=>"quandl_"*data["database_code"], 
                            #"data"=>data))))
            return 1

        else
            Logger.info("In insertsecuritydata_fromquandl(): quandl/$(sourcedata["database_code"]) datasource already exists for $(securityid)")
            Logger.info("Cannot add source information from quandl/$(sourcedata["database_code"])")
            return -1
        end    
                    
    end
end

"""
Insert security data in mongodb
"""
function insertsecuritydata(securitycollection::Mongoc.Collection, securityid::Int, sourcedata::Dict{String,Any}, sourcename::String) 
    
    Logger.info("Inserting security data for securityid:$securityid")

    sourcedata["sourcename"] = "$(sourcename)_$(sourcedata["database_code"])"
    
    if(Mongoc.count_documents(securitycollection, Mongoc.BSON(Dict("securityid"=>securityid))) == 0)
            
        curateddata = curatequandlsecurity(sourcedata, sourcedata["database_code"])
        curateddata["name"] = String(get(sourcedata, "name", "NULL"))
        delete!(sourcedata, "name")

        # Here insert if security didn't exist
        securitydata = Dict{String, Any}("securityid" => securityid,
            #"ISIN" => ISIN,
            "ticker" => curateddata["ticker"],
            "exchange" => curateddata["exchange"],
            "securitytype" => curateddata["securitytype"],
            "country" => curateddata["country"],
            "name" => curateddata["name"],
            "datasources" => [sourcedata])


        Mongoc.insert_one(securitycollection, Mongoc.BSON(securitydata))

        return 1
    
    else 
        
        Logger.info("In insertsecuritydata_fromquandl(): securityid: $(securityid) already exists in the database")
        Logger.info("Adding source information from quandl/$(sourcedata["database_code"])")
        
        query = Dict("securityid"=>securityid, 
                                    "datasources"=>Dict("\$elemMatch"=>Dict("sourcename"=>"quandl_"*sourcedata["database_code"],
                            "dataset_code"=>sourcedata["dataset_code"])))
        if(Mongoc.count_documents(securitycollection, Mongoc.BSON(query)) == 0)
       
            # Add another data source
            Mongoc.update_one(securitycollection, Mongoc.BSON(Dict("securityid"=>securityid)), Mongoc.BSON(Dict("\$push"=>Dict("datasources"=>sourcedata))))
                #Dict("datasources"=>Dict("sourcename"=>"quandl_"*data["database_code"], 
                            #"data"=>data))))
            return 1

        else
            Logger.info("In insertsecuritydata_fromquandl(): quandl/$(sourcedata["database_code"]) datasource already exists for $(securityid)")
            Logger.info("Cannot add source information from quandl/$(sourcedata["database_code"])")
            return -1
        end    
                    
    end
end

"""
Update security data in mongodb
THIS FUNCTION NEEDS TO BE FIXED FOR CORRECT QUERIES (A LOT OF HACKY CODE)
"""
function updatesecuritydata_fromquandl(securitycollection::Mongoc.Collection, securityid::Int, data::Dict{String,Any})

    Logger.info("Updating security data for securityid:$securityid")

    query = Dict("securityid"=>securityid, "datasources"=>Dict("\$elemMatch"=>Dict("sourcename"=>"quandl_"*data["database_code"],
                            "dataset_code"=>data["dataset_code"])))   
 
    #First find whether the security already exists in the collection 
    if (Mongoc.count_documents(securitycollection, query) == 0) 
        Logger.info("In updatesecuritydata_fromquandl(), securityid $securityid with datasource: $(data["database_code"]) doesn't exist in the database")
        Logger.info("In updatesecuritydata_fromquandl(), attempting to insert securityid $securityid with datasource: $(data["database_code"]) in the database")
        return insertsecuritydata_fromquandl(securitycollection, securityid, data)       
    end
          
    
    #Update logic
    try
        doc = Mongoc.find_one(securitycollection, Mongoc.BSON(query))
                    
        #get array (THIS SHOULD BE REPLACED BY QUERY )
        found = false
        index = 0
        datasource = Dict()
        for i in 1:length(doc["datasources"])
            #More hacky code to check for "sourcename" field (somehow there are cases where sourcename is not present)
            #Make this efficient 
            if(doc["datasources"][i]["dataset_code"] == data["dataset_code"] && haskey(Mongoc.as_dict(doc)["datasources"][i], "sourcename"))
                found = true
                datasource = doc["datasources"][i] 
                index = i
                break
            end 
        end

        if found   #Should always be true 
            # Check if data needs update
            if (haskey(datasource, "newest_available_date") && datasource["newest_available_date"] 
                == data["newest_available_date"])
                Logger.info("updatesecuritydata_fromquandl(): Data is up-to-date for securityid: $(securityid), dataset:$(data["dataset_code"]) and datasource: $(data["database_code"])")
                return 2
            else

                # Update this array
                dictionary = Mongoc.as_dict(doc) 

                datasource_array = dictionary["datasources"]
                data["sourcename"] = datasource_array[index]["sourcename"]
                datasource_array[index] = data 

                #Set to new array 
                #WORKS
                Mongoc.update_one(securitycollection, Mongoc.BSON(Dict("securityid"=>securityid)), Mongoc.BSON(Dict("\$set"=>Dict("datasources"=>datasource_array))))

                return 1
            end    
        end
    
    catch
        Logger.warn("In updatesecuritydata_fromquandl(), source id for securityid $securityid doesn't exist in the database. SKIPPING!!!")
        return -1
    end        
end


"""
Update data (true fields) in mongodb
"""
function updatecolumndata_fromquandl(datacollection::Mongoc.Collection, securityid::Int, securitydata::Dict{String,Any}, priority::Int, refreshAll::Bool)

    Logger.info("Updating column data for securityid:$securityid")
    
    query = Dict("securityid"=>securityid, 
                            "datasource.sourcename"=>"quandl_"*securitydata["database_code"],
                            "datasource.dataset_code"=>securitydata["dataset_code"])
    if(refreshAll) 
        Logger.info("Deleting column data for securityid: $(securityid) and priority: $(priority)")
        delete(datacollection, Mongoc.BSON(query))
    end

    #First find whether the security already exists in the collection 
    #If not, then insert
    if (Mongoc.count_documents(datacollection, Mongoc.BSON(Dict("securityid"=>securityid))) == 0) 
        Logger.info("In updatecolumndata_fromquandl(), securityid $securityid doesn't exist in the database")
        Logger.info("In updatecolumndata_fromquandl(), attempting to insert column data for securityid $securityid in the database")
        return insertcolumndata_fromquandl(datacollection, securityid, securitydata, priority)
    end

    #Find whether the security for datasource already exists in the collection 
    #If not, then insert
    if(Mongoc.count_documents(datacollection,("securityid"=>securityid, 
                            "datasource.sourcename"=>"quandl_"*securitydata["database_code"],
                            "datasource.dataset_code"=>securitydata["dataset_code"])) == 0)
        Logger.info("In updatecolumndata_fromquandl(): quandl/$(securitydata["dataset_code"]) datasource doesn't exist for $(securityid)")
        Logger.info("In updatecolumndata_fromquandl(), attempting to insert column data for securityid $securityid in the database")
        return insertcolumndata_fromquandl(datacollection, securityid, securitydata, priority)
    else
        #Update logic
        year = 2030
        if haskey(securitydata, "newest_available_date")
            year = parse(Int, (split(securitydata["newest_available_date"] , "-")[1]) )
        end
            
        dyear = year
        query = Dict("securityid"=>securityid,
                            "year"=>dyear, 
                            "datasource.sourcename"=>"quandl_"*securitydata["database_code"], 
                            "datasource.dataset_code"=>securitydata["dataset_code"])
        
        ct = Mongoc.count_documents(datacollection, Mongoc.BSON(query))        
        
        if(ct > 0) 
            # If document with latest year is present, compare the latest dates
            doc = Mongoc.find_one(datacollection, Mongoc.BSON(query))
          
            if (haskey(doc["datasource"], "newest_available_date") && 
                    haskey(securitydata, "newest_available_date") && 
                    doc["datasource"]["newest_available_date"]
                == securitydata["newest_available_date"])
                Logger.info("In updatecolumndata_fromquandl(): Column data is up-to-date for securityid: $(securityid), dataset:$(securitydata["dataset_code"]) and datasource: $(securitydata["database_code"])")
                
                return 1
            end
        #First try to find the last available year document               
        elseif(ct == 0)
            while (ct == 0 && dyear > 1990)                   
                dyear = dyear - 1
                query = Dict("securityid"=>securityid,
                             "year"=>dyear, 
                            "datasource.sourcename"=>"quandl_"*securitydata["database_code"], 
                            "datasource.dataset_code"=>securitydata["dataset_code"])
                ct = Mongoc.count_documents(datacollection, Mongoc.BSON(query))
            end
        end

        if dyear == 1990 #seems like some data-issue 
            Logger.warn("In updatecolumndata_fromquandl(): Data issue(no/little data present) for securityid: $(securityid), dataset:$(securitydata["dataset_code"]) and datasource: $(securitydata["database_code"])")
            return 1
        end    

        try   
            #latest document
            doc = Mongoc.as_dict(Mongoc.find_one(datacollection, Mongoc.BSON(query)))
             
            # Better way to check for start date
            # First delete if there any duplicates
            # Second, get the latest DATE from actual data (NOT from embedded security document)  
            duplicates = checkduplicates_and_update(datacollection, query, doc["data"])
            
            if(duplicates)
                Logger.info("In updatecolumndata_fromquandl(): Duplicate Column data was found for securityid: $(securityid), dataset:$(securitydata["dataset_code"]) and datasource: $(securitydata["database_code"]). Deleted!!!")
                doc = Mongoc.as_dict(Mongoc.find_one(datacollection, Mongoc.BSON(query)))
            end

            latest_date = getlatestdate(doc["data"])

            #Mak sure latest_date year is same as 
            latest_date_year = Dates.year(Date(latest_date))

            if latest_date_year != dyear
                Logger.warn("For SecurityId: $securityid, data for $latest_date_year present in $dyear document")
                latest_date = "$dyear-12-31"
            end

            data_quandl = getcolumndata(securitydata, 
                                startdate = string(Date(latest_date) + Dates.Day(1)),
                                enddate = get(securitydata, "newest_available_date", ""))
        
            if data_quandl != Dict{String, Any}()
                #get true data and columns
                columns = data_quandl["columns"]
                actualdata = data_quandl["data"] 

                #Convert data into year chunks for our data model
                data_byyear = filterdata_byyear(actualdata)
                
                for k in keys(data_byyear)
                    array = get(data_byyear , k, "NULL")
                    
                    if array == "NULL" || length(array) == 0
                        Logger.warn("In updatecolumndata_fromquandl(): No data found for securityid: $(securityid) and year: $(k)")
                        continue
                    else
                        #determine whether to insert 
                        #or whether to append
                        dyear = k

                        # Missing query (FIX)
                        query = Dict("securityid"=>securityid,
                             "year"=>dyear, 
                            "datasource.sourcename"=>"quandl_"*securitydata["database_code"], 
                            "datasource.dataset_code"=>securitydata["dataset_code"])
 
                        ct = Mongoc.count_documents(datacollection, Mongoc.BSON(query))

                        if ct > 0
                            #get the already stored data
                            doc = Mongoc.as_dict(Mongoc.find_one(datacollection, Mongoc.BSON(query)))
                            data = doc["data"]["values"]
                            append!(data, array)
                            Mongoc.update_one(datacollection, Mongoc.BSON(query), Mongoc.BSON(Dict("\$set" => Dict("data.values"=>data))))

                            #Also, update the source informaton
                            sourcedata = securitydata
                            sourcedata["sourcename"] = "quandl_"*securitydata["database_code"]

                            query = Dict("securityid"=>securityid,
                                        "datasource.sourcename"=>"quandl_"*sourcedata["database_code"], 
                                        "datasource.dataset_code"=>sourcedata["dataset_code"])

                            Mongoc.update_many(datacollection, Mongoc.BSON(query), set("datasource"=>sourcedata))

                            Logger.info("In updatecolumndata_fromquandl(): Data updated successfully for securityid: $(securityid) and year:$(k)")
                        else

                            sourcedata = securitydata
                            sourcedata["sourcename"] = "quandl_"*securitydata["database_code"]
                            toinsertdict = Dict{String, Any}("securityid" => securityid,
                                                        "year" => k,
                                                        "priority" => priority,
                                                        "datasource" => sourcedata,
                                                        "data" => Dict{String, Any}("columns"=>columns, "values"=>array))
                            Mongoc.insert_one(datacollection , Mongoc.BSON(toinsertdict))
                            Logger.info("In updatecolumndata_fromquandl(): Data inserted successfully for securityid: $(securityid) and year:$(k)")
                        end
                    end
                end 
            end

        catch err
            Logger.warn("In updatecolumndata_fromquandl(), data for securityid $securityid and year:$dyear doesn't exist in the database. SKIPPING!!!")
            return -1
        end        
    end
end


"""
Insert security data in mongodb from generic data source
"""
function insertsecuritydata_generic(securitycollection::Mongoc.Collection, securityid::Int, sourcedata::Dict{String,Any}) 
    
    Logger.info("Inserting security data for securityid:$securityid")

    sourcedata["sourcename"] = sourcedata["database_code"]
    
    if(Mongoc.count_documents(securitycollection, ("securityid"=>securityid)) == 0)

        # Here insert if security didn't exist
        securitydata = Dict{String , Any}("securityid" => securityid,
            #"ISIN" => ISIN,
            "ticker" => sourcedata["ticker"],
            "exchange" => get(sourcedata, "exchange", "NSE"),
            "securitytype" => get(sourcedata,"securitytype", "EQ"),
            "country" => get(sourcedata,"country", "IN"),
            "name" => get(sourcedata,"name","NULL"),
            "datasources" => Vector{Dict{String,Any}}([sourcedata]))
        
        Mongoc.insert_one(securitycollection, Mongoc.BSON(securitydata))

        return 1
    
    else 
        
        Logger.info("In insertsecuritydata_generic(): securityid: $(securityid) already exists in the database")
        Logger.info("Adding source information from quandl/$(sourcedata["database_code"])")
   
        if(Mongoc.count_documents(securitycollection,("securityid"=>securityid, 
                                    "datasources"=>Dict("\$elemMatch"=>Dict("sourcename"=>sourcedata["database_code"],
                            "dataset_code"=>sourcedata["dataset_code"])))) == 0)
       
            # Add another data source
            Mongoc.update_one(securitycollection, Mongoc.BSON(Dict("securityid"=>securityid)), Mongoc.BSON(Dict("\$push"=>Dict("datasources"=>sourcedata))))
                #Dict("datasources"=>Dict("sourcename"=>"quandl_"*data["database_code"], 
                            #"data"=>data))))
            return 1

        else
            Logger.info("In insertsecuritydata_generic(): quandl/$(sourcedata["database_code"]) datasource already exists for $(securityid)")
            Logger.info("Cannot add source information from quandl/$(sourcedata["database_code"])")
            return -1
        end    
                    
    end
end


"""
Insert data (true fields) in mongodb for generic data source
"""
function insertcolumndata_generic(datacollection::Mongoc.Collection, securityid::Int, securitydata::Dict{String,Any}, columndata::Dict{String, Any}, priority::Int)

    Logger.info("Inserting column data for securityid:$securityid")
    
    if (Mongoc.count_documents(datacollection, ("securityid"=>securityid, "priority"=>priority, "datasource.database_code"=>securitydata["database_code"])) > 0)
        Logger.warn("In insertcolumndata_genric(), securityid $securityid for sourcename: $(securitydata["database_code"]) at priority: $(priority) already exists in the database.")
        # THIS should not happen
        # But in  case this happens....REMOVE ALL DATA for data tables
        Logger.info("In insertcolumndata_generic(): DELETING data for securityid $securityid for sourcename: $(securitydata["database_code"]) at priority: $(priority) fromt the database") 
        delete(datacollection, ("securityid"=>securityid, "priority"=>priority, "datasource.database_code"=>securitydata["database_code"]))
        
        #AND CONTINUE
    end
       
    
    if columndata != Dict{String, Any}()
        #get true data and columns
        columns = columndata["columns"]
        actualdata = columndata["data"] 

        #Convert data into year chunks for our data model
        data_byyear = filterdata_byyear(actualdata)
    
        for k in keys(data_byyear)
            array = get(data_byyear , k, "NULL")

            if array == "NULL"
                Logger.warn("insertcolumndata_fromquandl(): No data found for year: $(k)")
                continue
            else
                sourcedata = securitydata
                sourcedata["sourcename"] = securitydata["database_code"]
                toinsertdict = Dict{String ,Any}("securityid" => securityid,
                                                "year" => k,
                                                "priority" => priority,
                                                "datasource" => sourcedata,
                                                "data" => Dict{String, Any}("columns"=>columns, "values"=>array))
                Mongoc.insert_one(datacollection, Mongoc.BSON(toinsertdict))
            end
            
        end

        return 1
    else
        Logger.warn("insertcolumndata_fromquandl(): No data to insert for securityid:$(securityid)")
        return -1
    end  
end

"""
Update data (true fields) in mongodb for generic data source
"""
function updatecolumndata_generic(datacollection::Mongoc.Collection, securityid::Int, securitydata::Dict{String,Any}, columndata::Dict{String, Any}, priority::Int, refreshAll::Bool)

    Logger.info("Updating column data for securityid:$securityid")
    
    query = Dict("securityid"=>securityid, 
                            "datasource.sourcename"=>securitydata["database_code"],
                            "datasource.dataset_code"=>securitydata["dataset_code"])
    if(refreshAll) 
        Logger.info("Deleting column data for securityid: $(securityid) and priority: $(priority)")
        Mongoc.delete(datacollection, Mongoc.BSON(query))
    end

    #First find whether the security already exists in the collection 
    #If not, then insert
    if (Mongoc.count_documents(datacollection, Mongoc.BSON(Dict("securityid"=>securityid))) == 0) 
        Logger.info("In updatecolumndata_fromquandl(), securityid $securityid doesn't exist in the database")
        Logger.info("In updatecolumndata_fromquandl(), attempting to insert column data for securityid $securityid in the database")
        return insertcolumndata_generic(datacollection, securityid, securitydata, columndata, priority)
    end

    return insertcolumndata_generic(datacollection, securityid, securitydata, columndata, priority)
end


"""
Insert data (true fields) in mongodb
"""
function insertcolumndata_fromEODH(datacollection::Mongoc.Collection, securityid::Int, securitydata::Dict{String,Any}, priority::Int)

    Logger.info("In insertcolumndata_fromEODH(): Inserting column data for securityid:$securityid")
    
    query = Mongoc.BSON(Dict("securityid"=>securityid, "priority"=>priority, "datasource.database_code"=>securitydata["database_code"])) 
    if Mongoc.count_documents(datacollection, query) > 0
        Logger.warn("In insertcolumndata_fromEODH(), securityid $securityid for sourcename: $(securitydata["database_code"]) at priority: $(priority) already exists in the database.")
        
        # THIS should not happen
        # But in  case this happens....REMOVE ALL DATA for data tables
        Logger.info("In insertcolumndata_fromEODH(): DELETING data for securityid $securityid for sourcename: $(securitydata["database_code"]) at priority: $(priority) from the database") 
        Mongoc.delete(datacollection, query)
        
        #AND CONTINUE
    end
       
    #Get columnar data from quandl source
    data_EODH = getcolumndata_EODH(securitydata["dataset_code"], securitydata["database_code"])
    
    if data_EODH != Dict{String, Any}()
        #get true data and columns
        columns = data_EODH["columns"]
        actualdata = data_EODH["data"] 

        #Convert data into year chunks for our data model
        data_byyear = filterdata_byyear(actualdata)
    
        for k in keys(data_byyear)
            array = get(data_byyear , k, "NULL")

            if array == "NULL"
                Logger.warn("insertcolumndata_fromEODH(): No data found for year: $(k)")
                continue
            else
                sourcedata = securitydata
                sourcedata["sourcename"] = "EODH_"*securitydata["database_code"]
                toinsertdict = Dict{String ,Any}("securityid" => securityid,
                                                "year" => k,
                                                "priority" => priority,
                                                "datasource" => sourcedata,
                                                "data" => Dict{String, Any}("columns"=>columns, "values"=>array))

                Mongoc.insert_one(datacollection, Mongoc.BSON(toinsertdict))
            end
            
        end

        return 1
    else
        Logger.warn("insertcolumndata_fromEODH(): No data to insert for securityid:$(securityid)")
        return -1
    end
end

"""
Update data (true fields) in mongodb
"""
function updatecolumndata_fromEODH(datacollection::Mongoc.Collection, securityid::Int, securitydata::Dict{String,Any}, priority::Int, refreshAll::Bool)

    Logger.info("In updatecolumndata_fromEODH(): Updating column data for securityid:$securityid")
    
    query = Dict("securityid"=>securityid, 
                            "datasource.sourcename"=>"EODH_"*securitydata["database_code"],
                            "datasource.dataset_code"=>securitydata["dataset_code"])
    if(refreshAll) 
        Logger.info("Deleting column data for securityid: $(securityid) and datasource: EODH_$(securitydata["database_code"])")
        delete(datacollection, Mongoc.BSON(query))
    end

    #First find whether the security already exists in the collection 
    #If not, then insert
    if (Mongoc.count_documents(datacollection, Mongoc.BSON(Dict("securityid"=>securityid))) == 0) 
        Logger.info("In updatecolumndata_fromEODH(), securityid $securityid doesn't exist in the database")
        Logger.info("In updatecolumndata_fromEODH(), attempting to insert column data for securityid $securityid in the database")
        return insertcolumndata_fromEODH(datacollection, securityid, securitydata, priority)
    end

    #Find whether the security for datasource already exists in the collection 
    #If not, then insert
    if(Mongoc.count_documents(datacollection, Mongoc.BSON(Dict("securityid"=>securityid, 
                            "datasource.sourcename"=>"EODH_"*securitydata["database_code"],
                            "datasource.dataset_code"=>securitydata["dataset_code"]))) == 0)
        Logger.info("In updatecolumndata_fromEODH(): quandl/$(securitydata["dataset_code"]) datasource doesn't exist for $(securityid)")
        Logger.info("In updatecolumndata_fromEODH(), attempting to insert column data for securityid $securityid in the database")
        return insertcolumndata_fromquandl(datacollection, securityid, securitydata, priority)
    else
        #Update logic
        year = 2030
        if haskey(securitydata, "newest_available_date")
            year = parse(Int, (split(securitydata["newest_available_date"] , "-")[1]))
        end
            
        dyear = year
        query = Dict("securityid"=>securityid,
                            "year"=>dyear, 
                            "datasource.sourcename"=>"EODH_"*securitydata["database_code"], 
                            "datasource.dataset_code"=>securitydata["dataset_code"])
        
        ct = Mongoc.count_documents(datacollection, Mongoc.BSON(query))        
        today = Dates.format(Dates.now(), "yyyy-mm-dd")

        if(ct > 0) 
            # If document with latest year is present, compare the latest dates
            doc = Mongoc.find_one(datacollection, Mongoc.BSON(query))
          
            if (haskey(doc["datasource"], "newest_available_date") && doc["datasource"]["newest_available_date"]
                == today)
                Logger.info("In updatecolumndata_fromEODH(): Column data is up-to-date for securityid: $(securityid), dataset:$(securitydata["dataset_code"]) and datasource: $(securitydata["database_code"])")
                
                return 1
            end
        #First try to find the last available year document               
        elseif(ct == 0)
            while (ct == 0 && dyear > 1990)          
                dyear = dyear - 1
                query = Dict("securityid"=>securityid,
                             "year"=>dyear, 
                            "datasource.sourcename"=>"EODH_"*securitydata["database_code"], 
                            "datasource.dataset_code"=>securitydata["dataset_code"])
                ct = Mongoc.count_documents(datacollection, Mongoc.BSON(query))
            end
        end

        if dyear == 1990 #seems like some data-issue 
            Logger.warn("In updatecolumndata_fromEODH(): Data issue(no/little data present) for securityid: $(securityid), dataset:$(securitydata["dataset_code"]) and datasource: $(securitydata["database_code"])")
            return 1
        end

        try   
            #latest document
            doc = Mongoc.as_dict(Mongoc.find_one(datacollection, Mongoc.BSON(query)))
             
            # Better way to check for start date
            # First delete if there any duplicates
            # Second, get the latest DATE from actual data (NOT from embedded security document)  
            duplicates = checkduplicates_and_update(datacollection, query, doc["data"])
            
            if(duplicates)
                Logger.info("In updatecolumndata_fromEODH(): Duplicate Column data was found for securityid: $(securityid), dataset:$(securitydata["dataset_code"]) and datasource: $(securitydata["database_code"]). Deleted!!!")
                doc = Mongoc.as_dict(Mongoc.find_one(datacollection, Mongoc.BSON(query)))
            end

            latest_date = getlatestdate(doc["data"])

            #Mak sure latest_date year is same as 
            latest_date_year = Dates.year(Date(latest_date))

            if latest_date_year != dyear
                Logger.warn("For SecurityId: $securityid, data for $latest_date_year present in $dyear document")
                latest_date = "$dyear-12-31"
            end

            data_EODH = getcolumndata_EODH(securitydata["dataset_code"], securitydata["database_code"], 
                                startdate = string(Date(latest_date) + Dates.Day(1)),
                                enddate = today, skip = 1)
            

            if data_EODH != Dict{String, Any}()
                #get true data and columns
                columns = data_EODH["columns"]
                actualdata = data_EODH["data"] 

                true_newest_date = actualdata[end][1] 

                #Convert data into year chunks for our data model
                data_byyear = filterdata_byyear(actualdata)
                
                for k in keys(data_byyear)
                    array = get(data_byyear , k, "NULL")
                    
                    if array == "NULL" || length(array) == 0
                        Logger.warn("In updatecolumndata_fromEODH(): No data found for securityid: $(securityid) and year: $(k)")
                        continue
                    else
                        #determine whether to insert 
                        #or whether to append
                        dyear = k

                        # Missing query (FIX)
                        query = Dict("securityid"=>securityid,
                             "year"=>dyear, 
                            "datasource.sourcename"=>"EODH_"*securitydata["database_code"], 
                            "datasource.dataset_code"=>securitydata["dataset_code"])
 
                        ct = Mongoc.count_documents(datacollection, Mongoc.BSON(query))

                        #Also, update the source informaton
                        sourcedata = securitydata
                        sourcedata["newest_available_date"] = true_newest_date
                        sourcedata["sourcename"] = "EODH_"*securitydata["database_code"]

                        if ct > 0
                            #get the already stored data
                            doc = Mongoc.as_dict(Mongoc.find_one(datacollection, Mongoc.BSON(query)))
                            data = doc["data"]["values"]
                            append!(data, array)
                            Mongoc.update_one(datacollection, Mongoc.BSON(query), Mongoc.BSON(Dict("\$set" => Dict("data.values"=>data))))

                            
                            query = Dict("securityid"=>securityid,
                                        "datasource.sourcename"=>"quandl_"*sourcedata["database_code"], 
                                        "datasource.dataset_code"=>sourcedata["dataset_code"])

                            Mongoc.update_many(datacollection, Mongoc.BSON(query), Mongoc.BSON(Dict("\$set"=>Dict("datasource"=>sourcedata))))

                            Logger.info("In updatecolumndata_fromEODH(): Data updated successfully for securityid: $(securityid) and year:$(k)")
                        else
                           
                            toinsertdict = Dict{String, Any}("securityid" => securityid,
                                                        "year" => k,
                                                        "priority" => priority,
                                                        "datasource" => sourcedata,
                                                        "data" => Dict{String, Any}("columns"=>columns, "values"=>array))
                            
                            Mongoc.insert_one(datacollection , Mongoc.BSON(toinsertdict))
                            Logger.info("In updatecolumndata_fromEODH(): Data inserted successfully for securityid: $(securityid) and year:$(k)")
                        end
                    end
                end 
            end
        catch err
            println(err)
            Logger.warn("In updatecolumndata_fromEODH(), data for securityid $securityid and year:$dyear doesn't exist in the database. SKIPPING!!!")
            return -1
        end        
    end
end

