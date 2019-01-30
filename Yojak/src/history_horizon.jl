
"""
function to get history of multiple instruments/single data-mutable struct 
based on security ids for a period based on horizon 
"""    
function _history_unadj(securitycollection::Mongoc.Collection,
                    datacollection::Mongoc.Collection, 
                    secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int,
                    edate::DateTime,                    
                    securitytype::String,
                    exchange::String,
                    country::String,
                    strict::Bool)
    
    datatype = curatedatatype(datatype)
    output_ta = nothing

    if length(secids) == 0 || datatype==""
        Logger.warn("history(): Empty instrument array or data-mutable struct field")
        return output_ta
    end

    for (i, securityid) in enumerate(secids)

        priority = getpriority()
        #strict = getstrict()
        
        if securityid == -1
            #Logger.warn("$(symbol)/$(securitytype)/$(exchange) not found in database")
            continue
        else
            #fetch data from database
            nrows = 0
            data = Array{Any,2}(undef, 0,0)

            while priority > 0 && nrows == 0  
                data = getdata(datacollection, securityid, [datatype], frequency, horizon, edate, priority)
                nrows = size(data)[1]
                
                if !strict
                    priority = nrows == 0 ? (priority - 1) : priority
                else 
                    break
                end
            end
            
            symbol = "$securityid" #getsymbol(securitycollection, securityid)
            nrows = size(data)[1]
            
            ta = nrows > 0 ? toTimeArray(data, symbol, frequency = frequency) : nothing

            #combine the timearray with a bigger TimeArray
            if output_ta == nothing && ta != nothing
                output_ta = ta
            elseif output_ta != nothing && ta != nothing
                output_ta = !isempty(ta) ? merge(output_ta, ta, :outer) : output_ta
            end
        end
    end

    return output_ta
end

# function to gethistory on the basis on enddate for SINLGE security
function _history_unadj(securitycollection::Mongoc.Collection,
                    datacollection::Mongoc.Collection, 
                    secid::Int,
                    datatypes::Vector{String},
                    frequency::Symbol,
                    horizon::Int,
                    edate::DateTime,                    
                    securitytype::String,
                    exchange::String,
                    country::String,
                    strict::Bool)
    
    output_ta = nothing

    if length(datatypes) == 0
        Logger.warn("history(): Empty data-mutable struct field")
        return output_ta
    end

    for (i, x) in enumerate(datatypes)
        datatypes[i] = curatedatatype(datatype)
    end
     
    priority = getpriority()
    #strict = getstrict()
    
    if secid != -1
        #fetch data from database
        nrows = 0
        data = Array{Any,2}(undef, 0,0)

        while priority > 0 && nrows == 0  
            data = getdata(datacollection, securityid, datatypes, frequency, horizon, edate, priority)
            nrows = size(data)[1]
            if !strict
                priority = nrows == 0 ? (priority - 1) : priority
            else 
                break
            end
        end
        
        symbol = "$secid"
        nrows = size(data)[1]
        output_ta = nrows > 0 ? toTimeArray(data, symbol, frequency = frequency) : nothing

    end

    return output_ta
end

# function to gethistory on the basis on enddate and horizon
function _history(securitycollection::Mongoc.Collection,
                    datacollection::Mongoc.Collection, 
                    secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int,
                    edate::DateTime,                    
                    securitytype::String,
                    exchange::String,
                    country::String,
                    strict::Bool)

    datatype = curatedatatype(datatype)
    output_ta = nothing

    if length(secids) == 0 || datatype==""
        Logger.warn("history(): Empty instrument array or data-mutable struct field")
        return output_ta
    end

    for (i, securityid) in enumerate(secids)
        priority = getpriority()
        #strict = getstrict()

        if securityid == -1
            #Logger.warn("$(symbol)/$(securitytype)/$(exchange) not found in database")
            continue
        else
            #fetch data from database
            nrows = 0
            data = Array{Any,2}(undef, 0,0)

            while priority > 0 && nrows == 0
                columns = priority == 2 ? [datatype, "Adjustment Factor", "Adjustment Type"] : [datatype]
                data = getdata(datacollection, securityid, columns, frequency, horizon, edate, priority)
                nrows = size(data)[1]
                if !strict
                    priority = nrows == 0 ? (priority - 1) : priority
                else 
                    break
                end
            end

            symbol = "$securityid" # getsymbol(securitycollection, securityid)
            nrows = size(data)[1]
            ta = nrows > 0 ? ((priority == 2) ? adjustdata(data, symbol) : toTimeArray(data, symbol)) : nothing
            
            #combine the timearray with a bigger TimeArray
            if output_ta == nothing && ta != nothing
                output_ta = ta
            elseif output_ta != nothing && ta != nothing
                output_ta = !isempty(ta) ? merge(output_ta, ta, :outer) : output_ta
            end
        end
    end

    return output_ta
end      


# function to gethistory for ONE security on the basis on enddate and horizon
function _history(securitycollection::Mongoc.Collection,
                    datacollection::Mongoc.Collection, 
                    secid::Int,
                    datatypes::Vector{String},
                    frequency::Symbol,
                    horizon::Int,
                    edate::DateTime,                    
                    securitytype::String,
                    exchange::String,
                    country::String,
                    strict::Bool)

    output_ta = nothing

    if length(datatypes) == 0 
        Logger.warn("history(): Empty datatype array")
        return output_ta
    end

    for i in enumerate(datatypes)
        datatypes[i] = curatedatatype(datatypes[i])
    end
    
    priority = getpriority()
    #strict = getstrict()

    if secid == -1
        Logger.warn("Secid = -1 not found in database")
        #continue
    else
        #fetch data from database
        nrows = 0
        data = Array{Any,2}(undef, 0,0)

        while priority > 0 && nrows == 0
            columns = priority == 2 ? append!(datatypes, ["Adjustment Factor", "Adjustment Type"]) : [datatypes]
            data = getdata(datacollection, securityid, columns, frequency, horizon, edate, priority)
            nrows = size(data)[1]
            if !strict
                priority = nrows == 0 ? (priority - 1) : priority
            else 
                break
            end
        end

        symbol = "$secid" #getsymbol(securitycollection, secid)
        nrows = size(data)[1]
        output_ta = nrows > 0 ? ((priority == 2) ? adjustdata_all(data, symbol) : toTimeArray_all(data, symbol)) : nothing
        
    end

    return output_ta
end      


""" 
SAME FUNCTIONS AS ABOVE: Based on symbols(ticker)
"""
function _history(securitycollection::Mongoc.Collection,
                    datacollection::Mongoc.Collection, 
                    symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int,
                    edate::DateTime,                    
                    securitytype::String,
                    exchange::String,
                    country::String,
                    strict::Bool)

    _history(securitycollection, datacollection,
            getsecurityids(securitycollection, symbols, securitytype, exchange, country), datatype, frequency, horizon, edate,
            securitytype, exchange, country, strict)
end


function _history_unadj(securitycollection::Mongoc.Collection,
                    datacollection::Mongoc.Collection, 
                    symbols::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int,
                    edate::DateTime,                    
                    securitytype::String,
                    exchange::String,
                    country::String,
                    strict::Bool)

    _history(securitycollection, datacollection,
            getsecurityids(securitycollection, symbols, securitytype, exchange, country), datatype, frequency, horizon, edate,
            securitytype, exchange, country, strict)
end
