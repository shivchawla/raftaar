
using BackTester
import BackTester: Security
using Dates
using JSON

function ifsecurityidexists(securitycollection::Mongoc.Collection, secid::Int)
    return Mongoc.count_documents(securitycollection, Mongoc.BSON(Dict("securityid"=>secid))) > 0
end

function getallsecuritiesbyticker(securitycollection::Mongoc.Collection, ticker::String)
   
    securities = Vector{Security}()

    query = Dict("ticker"=>ticker)
    ct = Mongoc.count_documents(securitycollection, Mongoc.BSON(query))
    
    if ct > 1
        Logger.info("Multiple securities present for ticker:$(ticker)")
    
    elseif ct==0
        Logger.warn("No securities present for $(ticker)")
        return securities
    end 

    securitydocs = Mongoc.find(securitycollection , Mongoc.BSON(query))

    for securitydoc in securitydocs
        append!(securities, Security(securitydoc["securityid"],
                    securitydoc["ticker"],
                    securitydoc["name"],
                    get!(securitydoc, "detail", Dict{String, Any}()),                 
                    securitydoc["exchange"],
                    securitydoc["country"],
                    securitydoc["securitytype"]))
    end

    return securities
end


function getsecurity(securitycollection::Mongoc.Collection, secid::Int)

    query = Dict("securityid"=>secid)
    ct = Mongoc.count_documents(securitycollection, Mongoc.BSON(query))
    
    if ct > 1
        Logger.warn("Multiple securities present for securityid:$(secid)")
        return Security()

    elseif ct==0
        Logger.warn("No securities present for securityid:$(secid)")
        return Security()
    end 

    securitydoc = JSON.parse(Mongoc.as_json(Mongoc.find_one(securitycollection , Mongoc.BSON(query))))

    return Security(secid, securitydoc["ticker"],
                            securitydoc["name"],
                            get(securitydoc, "detail", Dict{String, Any}()),    
                            exchange = securitydoc["exchange"],
                            country = securitydoc["country"],
                            securitytype = securitydoc["securitytype"])
end

function getsecurity(securitycollection::Mongoc.Collection, ticker::String, 
                                            securitytype::String,
                                            exchange::String,
                                            country::String)
    
    query = Dict("ticker"=>ticker, "securitytype"=>securitytype,
                "exchange"=>exchange, "country"=>country)
    
    ct = Mongoc.count_documents(securitycollection, Mongoc.BSON(query))
    
    if ct > 1
        Logger.warn("Multiple securities present for ticker:$(ticker) echange:$(exchange) securitytype:$(securitytype) country:$(country)")
        return Security()

    elseif ct==0
        Logger.warn("No securities present for $(ticker)/$(exchange)/$(country)/$(securitytype)")
        return Security()
    end 

    securitydoc = JSON.parse(Mongoc.as_json(Mongoc.find_one(securitycollection, Mongoc.BSON(query))))

    return Security(securitydoc["securityid"],
                    securitydoc["ticker"],
                    securitydoc["name"],  
                    get(securitydoc, "detail", Dict{String, Any}()),                 
                    exchange = securitydoc["exchange"],
                    country = securitydoc["country"],
                    securitytype = securitydoc["securitytype"])
      
end

"""
Get symbols for a collection of security ids
This function currently searches for one sec id at a time
FIX: Add unique constraint on securityid in datanase and search for all security ids at once 
"""
function getsymbols(securitycollection::Mongoc.Collection, securityids::Array{Int,1})
    
    symbols = Array{String,1}()
    
    for id in securityids
        symbol = getsymbol(securitycollection, id)

        if symbol != "NULL" 
            push!(symbols, symbol)
        end 
    end

    return symbols

end

"""
Get symbols for a collection of security ids
"""
function getsymbol(securitycollection::Mongoc.Collection, securityid::Int)
    
    query = Dict("securityid"=>securityid)
    ct = Mongoc.count_documents(securitycollection, Mongoc.BSON(query))
    
    if ct > 1
        Logger.warn("Multiple securities present for securityid:$(securityid)")
        return "NULL"

    elseif ct==0
        Logger.warn("No securities present for securityid:$(securityid)")
        return "NULL"
    end 

    security = JSON.parse(Mongoc.as_json(Mongoc.find_one(securitycollection, Mongoc.BSON(query))))

    return security["ticker"]

end

export getsymbol


"""
Get security ids for a collection of symbol ids (and exchange and security type)
FIX: Add the unique constraint on secids and search for al symbols at once
ENHANCEMENT: Allow for securitytype array and exchange array
"""
function getsecurityids(securitycollection::Mongoc.Collection, 
                        tickers::Array{String,1}, 
                        securitytype::String, 
                        exchange::String,
                        country::String)
    
    secids = Array{Int,1}(length(tickers))

    for i = 1:length(tickers)
        secids[i] = getsecurityid(securitycollection, tickers[i], securitytype, exchange, country) 
    end

    return secids

end
#precompile(getsecurityids, (Mongoc.Collection, Array{String,1}, String, String, String))

"""
Get security id for a symbol id (and exchange and security type)
"""
function getsecurityid(securitycollection::Mongoc.Collection, 
                        ticker::String, 
                        securitytype::String, 
                        exchange::String,
                        country::String)
    
    #client = MongoClient()
    #securitycollection = Mongoc.Collection(client, "aimsquant", "security_test") 
    #const datacollection = Mongoc.Collection(client , "aimsquant", "data_test")

    query = Dict("ticker"=>ticker, "securitytype"=>securitytype, "exchange"=>exchange)
   
    ct = Mongoc.count_documents(securitycollection, Mongoc.BSON(query))
    
    if ct > 1
        Logger.warn("Multiple securities present for ticker:$(ticker)
             exchange:$(exchange) securitytype:$(securitytype)")
        return -1
    elseif ct==0
         Logger.warn("No security present for ticker:$(ticker)
             exchange:$(exchange) securitytype:$(securitytype) country:$(country)")
        return -1
    end 

    security = JSON.parse(Mongoc.as_json(Mongoc.find_one(securitycollection , Mongoc.BSON(query))))
        
    return security["securityid"]
    
end

#precompile(getsecurityid, (Mongoc.Collection, String, String, String, String))


"""
fucntions to get data from data base for security/data-mutable struct combination
for a period(either based on horizon or based on gap betwen start and end dates)
BELOW are mutliple functions with slightly different arguments to support 
the various possibility of input combinations    
"""
function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    columns::Array{String,1},
                    frequency::Symbol,
                    sdate::String, 
                    edate::String, 
                    priority::Int)    
    return aggregatedata(datacollection, securityid, columns, frequency, sdate, edate, priority)
end


function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    columns::Array{String,1},
                    frequency::Symbol,
                    sdate::DateTime, 
                    edate::DateTime, 
                    priority::Int)    
    return aggregatedata(datacollection, securityid, columns, frequency, sdate, edate, priority)
end

function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    columns::Array{String,1},
                    frequency::Symbol,
                    horizon::Int, 
                    edate::String,
                    priority::Int)    
    return aggregatedata(datacollection, securityid, columns, frequency, horizon, edate, priority)
end


function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    columns::Array{String,1},
                    frequency::Symbol,
                    horizon::Int, 
                    edate::DateTime,
                    priority::Int)    
    return aggregatedata(datacollection, securityid, columns, frequency, horizon, edate, priority)
end


"""
getdata() functions for single security/single data-type
"""
function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    column::String,
                    frequency::Symbol,
                    sdate::String, 
                    edate::String, 
                    priority::Int)    
    return aggregatedata(datacollection, securityid, [column], frequency, sdate, edate, priority)
end


function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    column::String,
                    frequency::Symbol,
                    sdate::DateTime, 
                    edate::DateTime,
                    priority::Int)    
    return aggregatedata(datacollection, securityid, [column], frequency, sdate, edate, priority)
end


function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    column::String,
                    frequency::Symbol,
                    horizon::Int, 
                    edate::String, 
                    priority::Int)    
    return aggregatedata(datacollection, securityid, [column], frequency, horizon, edate, priority)
end


function getdata(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    column::String,
                    frequency::Symbol,
                    horizon::Int, 
                    edate::DateTime,
                    priority::Int)    
    return aggregatedata(datacollection, securityid, [columns], frequency, horizon, edate, priority)
end


###########################
#INTERNAL FUNCTIONS
###########################

"""
HELPER
To search the index in the aray
"""
function getindexofcolumn(data::Array{Any,1}, column::String)
    idx = findall(data.==column)
    
    if length(idx) == 1
        return idx[1]
    else
        return -1
    end 
end


"""
HELPER
Convert the output of database into n-dimensional data
"""
function NdArray(data::Array{Array{Any,1}}, index::Array{Int,1})
    
    len = length(data)
    
    if len == 0
        return Array{Any}(0,0)
    end

    ncols = length(index)
    output = Array{Any}(undef, len, ncols)
    for i = 1:len
        for j = 1:ncols
            idx = index[j]
            output[i,j] = data[i][idx]
        end
    end
    return output
end

function NdArray(data::Array{Any,1}, index::Array{Int,1})
    
    len = length(data)
    
    if len == 0
        return Array{Any}(0,0)
    end

    ncols = length(index)
    output = Array{Any}(undef, len, ncols)
    for i = 1:len
        for j = 1:ncols
            idx = index[j]
            output[i,j] = data[i][idx]
        end
    end
    return output
end


function removeduplicates(data::Array{Any,2})
    v = Array{Any, 2}
    nrows, ncols = size(data)

    for i = 1:nrows - 1
        if data[i, 1] == data[i+1, 1]
            data[i, 2] = -1
        end
    end
    
    A = .~any((data .== -1), dims=2)

    return data[(LinearIndices(A))[findall(A)],:]

end

"""
Function to get data (multiple fields + Date) from the database for security id and a particular year
"""
function getdatabyyear(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    columns::Array{String,1}, 
                    year::Int, 
                    priority::Int = 1)
    
    ct =  Mongoc.count_documents(datacollection, Mongoc.BSON(Dict("securityid" => securityid, 
                                    "year" => year, 
                                    "priority"=> priority
                                ))
                )

    if ct > 1
        Logger.warn("More than one document found in the collection for securityid:$(securityid) and year:$(year)")
        return Array{Any}(undef,0,0)
    elseif ct == 0    
        Logger.warn("No document found in the collection for securityid:$(securityid) and year:$(year)")
        return Array{Any}(undef,0,0)
    end

    docs = Mongoc.collect(Mongoc.find(datacollection, 
                            Mongoc.BSON(Dict("securityid" => securityid,
                                                "year" => year, 
                                                "priority"=>priority))
                        ))
    
    for d in docs

        doc = JSON.parse(Mongoc.as_json(d))

        columndata = doc["data"]["columns"]
        actualdata = doc["data"]["values"]

        columnindices = Array{Int,1}()
        for column in columns
            
            idx = getindexofcolumn(columndata, column)
            
            if idx != -1
                push!(columnindices, idx)
            else
                Logger.warn("$(column) field not found in data")
            end
        end

        if length(columnindices) == 0
            Logger.warn("No fields are not found in data")
            return Array{Any}(undef, 0,0)
        end

        dateindex = getindexofcolumn(columndata,"Date")

        if dateindex ==-1
            Logger.warn("'Date' field not found in data")
            return Array{Any}(undef, 0,0)
        end

        ndata = NdArray(actualdata, append!([dateindex], columnindices))
        
        ndata = sortslices(ndata, dims=1, rev=true)

        return removeduplicates(ndata)

    end   
     
end


"""
Function to get data (single field + Date) from the database for security id and a particular year
"""
function getdatabyyear(datacollection::Mongoc.Collection, 
                        securityid::Int, 
                        column::String, 
                        year::Int, 
                        priority::Int = 1)
    
    return getdatabyyear(datacollection, securityid, [column], year, priority)
end

function forwardfill(data::Array{Any,2}, date::Date)


    b_dt = DateTime(Dates.year(date), Dates.month(date), Dates.day(date), 3, 46, 0);
    e_dt = DateTime(Dates.year(date), Dates.month(date), Dates.day(date), 10, 0, 0);

    minutes =  Int(floor(Dates.value(e_dt - b_dt)/1000/60)) + 1

    ndata = Array{Any,2}(undef, minutes, 2)

    last_val = NaN;

    for i in 1:minutes
        dt = b_dt + Dates.Minute(i - 1);
        
        idxs = findall(x -> x == dt, data[:,1])

        if (length(idxs) == 1)
            ndata[i, :] = data[idxs[1], :]
        else
            ndata[i,1] = dt
            ndata[i,2] = last_val
        end

        last_val = ndata[i,2]

    end

    return sortslices(ndata, dims=1, rev=true)
    
end

"""
(Minute Data) Function to get data (multiple fields + Date) from the database for security id and a particular Date
"""
function getdatabydate(datacollection::Mongoc.Collection, 
                    securityid::Int, 
                    columns::Array{String,1}, 
                    date::Date,
                    priority::Int = 1)
    
    query = Dict("securityid" => securityid, 
                "priority"=> priority,
                "date" => DateTime(date), ## BSON supports only datetime (and DB also has data in datetime format)
            )

    ct =  Mongoc.count_documents(datacollection, Mongoc.BSON(query))

    if ct > 1
        Logger.warn("More than one document found in the collection for securityid:$(securityid) and date:$(date)")
        return Array{Any}(undef, 0,0)
    elseif ct == 0    
        Logger.warn("No document found in the collection for securityid:$(securityid) and date:$(date)")
        return Array{Any}(undef, 0,0)
    end

    docs = Mongoc.collect(Mongoc.find(datacollection, Mongoc.BSON(query)))
    
    for d in docs

        doc = JSON.parse(Mongoc.as_json(d))

        columndata = doc["data"]["columns"]
        actualdata = doc["data"]["values"]

        #Format the actual data (with new mongoc module, simplae datetime array field comes as dictionary field)
        if actualdata != nothing && length(actualdata) > 0
            actualdata = [[DateTime(collect(values(dataRow[1]))[1][1:end-1]); dataRow[2:end]] for dataRow in actualdata]
        end

        columnindices = Array{Int,1}()
        for column in columns
            
            idx = getindexofcolumn(columndata, column)
            
            if idx != -1
                push!(columnindices, idx)
            else
                Logger.warn("$(column) field not found in data")
            end
        end

        if length(columnindices) == 0
            Logger.warn("No fields are not found in data")
            return Array{Any}(undef, 0,0)
        end

        dateindex = getindexofcolumn(columndata,"Date")

        if dateindex ==-1
            Logger.warn("'Date' field not found in data")
            return Array{Any}(undef, 0,0)
        end

        ndata = NdArray(actualdata, append!([dateindex], columnindices))

        ndata = sortslices(ndata, dims=1, rev=true)

        # b_dt = DateTime(Dates.year(date), Dates.month(date), Dates.day(date), 3, 46, 0);
        # e_dt = DateTime(Dates.year(date), Dates.month(date), Dates.day(date), 10, 0, 0);

        # ndata = forwardfill(ndata[(ndata[:, 1] .>= b_dt) .& (ndata[:, 1] .<= e_dt), :])

        return forwardfill(removeduplicates(ndata), date)

    end   
     
end


"""
(Minute Data) Function to get data (single field + Date) from the database for security id and a particular year
"""
function getdatabydate(datacollection::Mongoc.Collection, 
                        securityid::Int, 
                        column::String, 
                        date::Date, 
                        priority::Int = 1)
    
    return getdatabydate(datacollection, securityid, [column], date, priority)
end




#aggregates data by year.
#Later filters by start and end dates

function aggregatedata(datacollection::Mongoc.Collection,
                        securityid::Int,
                        columns::Array{String,1},
                        frequency::Symbol,
                        sdate::DateTime,
                        edate::DateTime,
                        priority::Int)
    
    #handle daily frequency data, data comes from yearly files
    if (frequency == :Day) 
                 
        sdate_year = Dates.value(Dates.Year(sdate))
        edate_year = Dates.value(Dates.Year(edate))

        if ("Volume" in columns && priority == 1)
            columns[columns.=="Volume"] = "Total Trade Quantity"
        end
        
        data = Array{Any}(undef, 0,0)

        while (edate_year >= sdate_year) 
            
            # Get data for year of year_enddate from database
            # IMPROVEMENT : modify fucntion to directy get Time Array
            ndata = getdatabyyear(datacollection, securityid, columns, edate_year, priority)

            if(size(ndata)!=(0,0))
                if size(data) == (0,0) 
                    data = ndata
                else
                    data = vcat(data, ndata)
                end 
            end    
            edate_year = edate_year - 1        
        end

    elseif (frequency == Symbol("1m") || frequency == Symbol("5m") || frequency == Symbol(":15m") || frequency == Symbol(":30m"))

        sdate_date = Date(sdate)
        edate_date = Date(edate)

        if ("Volume" in columns && priority == 1)
            columns[columns.=="Volume"] = "Total Trade Quantity"
        end
        
        data = Array{Any}(undef, 0,0)

        while (edate_date >= sdate_date) 
            
            # Get data for year of year_enddate from database
            # IMPROVEMENT : modify fucntion to directy get Time Array
            ndata = getdatabydate(datacollection, securityid, columns, edate_date, priority)

            if(size(ndata)!=(0,0))
                if size(data) == (0,0) 
                    data = ndata
                else
                    data = vcat(data, ndata)
                end 
            end

            edate_date = edate_date - Dates.Day(1)
        
        end

    end

    #Remove duplicates from data
    data = removeduplicates(data)

    # IMPROVEMENT: directly make time array
   
    #Now filter data based on start and end date
    #BUG FIX: Check if dates exist in interval (was sending the full year data previously)
    if(size(data) == (0,0))
        return []
    end
    
    #Comparing inout dates with extremes
    if Date(sdate) > Date(data[1,1])
         return []
    elseif Date(edate) < Date(data[size(data,1),1])
        return []
    end        


    eidx = 1
    for i = 1:size(data,1)
        if edate < DateTime(data[i,1])
            continue
        end
       
        eidx = i
        break
    end

    if frequency == :Day
        ##Filter data for dates

        sidx = size(data, 1)
        for i = size(data, 1):-1:1
            if sdate > DateTime(data[i,1])
                continue
            end
            sidx = i
            break
        end

        return data[eidx:1:sidx , :]

    else #in case of minute data, return everything

        return data
    end


end

#aggregates data by year.
#Later filters by end date and horizon
function aggregatedata(datacollection::Mongoc.Collection,
                        securityid::Int,
                        columns::Array{String,1},
                        frequency::Symbol,
                        horizon::Int,
                        edate::DateTime,
                        priority::Int)

    if ("Volume" in columns && priority == 1)
        columns[columns.=="Volume"] = "Total Trade Quantity"
    end

    if frequency == :Day

        edate_year = Dates.value(Dates.Year(edate))

        #get data for n year from database
        data = getdatabyyear(datacollection, securityid, columns, edate_year, priority)

        #Now filter data based on end date
        eidx = 0
        datetimes = size(data) != (0,0)  ? [DateTime(date) for date in data[:,1]] : []
        availableHorizon = length(datetimes[datetimes .<= edate])
     
        while (availableHorizon < horizon)
            edate_year = edate_year - 1
            ndata = getdatabyyear(datacollection, securityid, columns, edate_year, priority)
            
            if(size(ndata) != (0,0))
                if size(data) == (0,0) 
                    data = ndata
                else
                    data = vcat(data, ndata)
                end

                data = removeduplicates(data) 
            else
                Logger.warn("Only $(size(data,1)) days of data avalable for securityid :$(securityid) ")
                horizon = size(data,1)
                break 
            end 

            # Final retrieval
            datetimes = size(data) != (0,0) ? [DateTime(date) for date in data[:,1]] : []
            availableHorizon = length(datetimes[datetimes .<= edate])
        end

    elseif (frequency == Symbol("1m") || frequency == Symbol("5m") || frequency == Symbol(":15m") || frequency == Symbol(":30m"))

        edate_date = Dates.Date(edate)
        
        #get data for this from database
        data = getdatabydate(datacollection, securityid, columns, edate_date, priority)
        currentHorizon = data == nothing || data == [] ? 0  : 1

        while (currentHorizon < horizon && edate_date > Date("2018-06-01"))
            edate_date -= Dates.Day(1)
            ndata = getdatabydate(datacollection, securityid, columns, edate_date, priority)

        
            if(size(ndata) != (0,0))
                if size(data) == (0,0) 
                    data = ndata
                else
                    data = vcat(data, ndata)
                end

                data = removeduplicates(data) 
                
                currentHorizon += 1
            end
        end

    end

    return data

end

#function to add data on the basis of the start and end date and return an array filled with data
function aggregatedata(datacollection::Mongoc.Collection,
                        securityid::Int,
                        columns::Array{String,1},
                        frequency::Symbol,
                        sdate::String,
                        edate::String)
                        

    aggregatedata(datacollection, securityid, columns, DateTime(sdate), DateTime(edate))
end

#function to add data on the basis of the start and end date and return an array filled with data
function aggregatedata(datacollection::Mongoc.Collection,
                        securityid::Int,
                        columns::Array{String,1},
                        frequency::Symbol,
                        horizon::Int,
                        edate::String)

    aggregatedata(datacollection, securityid, columns, horizon, DateTime(edate))
end

function _get_adjustments_factors_security(datacollection::Mongoc.Collection, 
                            secid::Int,
                            sdate::DateTime, 
                            edate::DateTime,
                            securitytype::String,
                            exchange::String,
                            country::String)    

    data = getdata(datacollection, 
                    secid, 
                    ["Adjustment Factor"],
                    :Day,
                    sdate, 
                    edate,
                    2)

    #data can be empty array due to data issues
    if data != Any[]
        data[data[:,2].==nothing, 2] .= 1.0
        data[data[:,2].=="", 2] .= 1.0
        data[:,2] = pushfirst!(data[1:end-1,2], 1.0)
    end

    return data == Any[] ? Matrix{Any}(0,0) : data
end


function _get_adjustments_factors(datacollection::Mongoc.Collection, 
                        tickers::Vector{String},
                        sdate::DateTime, 
                        edate::DateTime,
                        securitytype::String,
                        exchange::String,
                        country::String
                    )

    output = Dict{String, Array{Any,2}}()
    
    for ticker in tickers
        
        security = getsecurity(ticker)

        output[security.symbol.ticker] = _get_adjustments_factors_security(datacollection, 
                            security.symbol.id,
                            sdate, 
                            edate,
                            securitytype,
                            exchange,
                            country)

    end

    return output

end



function _get_adjustments(datacollection::Mongoc.Collection, 
                        tickers::Vector{String},
                        sdate::DateTime, 
                        edate::DateTime,
                        securitytype::String,
                        exchange::String,
                        country::String
                    )

    output = Dict{Int, Dict{Date, Vector{Float64}}}()
    
    for ticker in tickers
        
        security = getsecurity(ticker)

        output[security.symbol.id] = _get_adjustments_security(datacollection, 
                            security.symbol.id,
                            sdate, 
                            edate,
                            securitytype,
                            exchange,
                            country)

    end

    return output

end

function _get_adjustments(datacollection::Mongoc.Collection, 
                        secids::Vector{Int},
                        sdate::DateTime, 
                        edate::DateTime,
                        securitytype::String,
                        exchange::String,
                        country::String
                    )
    
    output = Dict{Int, Dict{Date, Vector{Float64}}}()
    
    for secid in secids
    
        output[secid] = _get_adjustments_security(datacollection, 
                            secid,
                            sdate, 
                            edate,
                            securitytype,
                            exchange,
                            country)

    end

    return output
   
end

    
function _get_adjustments_security(datacollection::Mongoc.Collection, 
                            secid::Int,
                            sdate::DateTime, 
                            edate::DateTime,
                            securitytype::String,
                            exchange::String,
                            country::String)    

    data = getdata(datacollection, 
                    secid, 
                    ["Close", "Adjustment Factor", "Adjustment Type"],
                    :Day,
                    sdate, 
                    edate,
                    2)


    nrows = size(data)[1]
    output = Dict{Date, Vector{Float64}}()

    for i = 1:nrows
        rowdata = data[i,:]

        adjType = 0.0
        adjFactor = 0.0
        
        if (rowdata[4] != "" && rowdata[4] != nothing)
            # Added absolute because of some data issue
            # ALBK has negatve adjustment factor (data issue)
            # ******BUT THROWING ERROR in SOME CASES abs(symbol) not allowed
            # Undo
            adjFactor = Meta.parse(string(rowdata[3]))
            adjType = Meta.parse(string(rowdata[4])) 
        end

        if (adjType == 17.0)
            #Get Cash Dividend based on last known price before this date
            
            if (i + 1 <= nrows)
                nextRow = data[i+1, :]
                adjFactor = nextRow[2] * (1 - adjFactor)
            else           
                adjFactor = rowdata[2] * (1 - adjFactor)    
            end

        elseif (rowdata[3] != "")
            adjFactor = adjFactor
        end 

        #Seems like rowdata[3] can contain both nothing or empty string
        #Added check for empty sring (19/07/2017)
        #TODO: Make the source check this
        if (rowdata[3] != nothing && rowdata[3] != "")
            output[Date(rowdata[1])] = [rowdata[2], adjFactor, adjType]
        end

    end

    return output

end
