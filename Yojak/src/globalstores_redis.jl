import Base: getindex

const _globaldatastores = Dict{String, Any}()
const _tickertosecurity = Dict{String, Security}()
const _seciddtosecurity = Dict{Int, Security}() 
_benchmarkEODData = nothing

function __forwardfill(ta)

    nrows = length(ta)
    vals = values(ta)
    for (col, name) in enumerate(colnames(ta))
        noNaNIdx = findlast(x -> !isnan(x), vals[:, col])
        if noNaNIdx < nrows && noNaNIdx > 0
            vals[noNaNIdx+1:nrows, col] .= vals[noNaNIdx, col]
        end
    end

    return TimeSeries.TimeArray(timestamp(ta), vals, colnames(ta))
end

function getsubset(ta::TimeArray, d::DateTime, ct::Int=0, offset::Int=5, frequency::Symbol = :Day) 

    # Drop NaN before selecting time period 
    ta = dropnan(ta)
    timestamps = TimeSeries.timestamp(ta)

    lastidx = 0

    #special logic to check for offset number of days around the end date (in case end date is unavailable)
    #offset = -1 means inifinite days
    #offset = offset == -1 ? length(timestamps) : offset
    
    if frequency == :Day
        for i=0:(offset == -1 ? length(timestamps) : offset)
            
            nd = Date(d) - Dates.Day(i)
            lastidx = findlast(x -> x == nd, timestamps)

            if lastidx > 0
                break
            end
        end
    else 
        # for i=0:(offset == -1 ? length(timestamps) : offset)
            
        #     nd = Date(d) - Dates.Day(i)
        #     lastidx = findlast(x -> x == nd, unique(Date.(timestamps)))

        #     if lastidx > 0
        #         break
        #     end
        # end

        offset = -1
    end

    #Check if lastidx is zero and offset is -1 ====> lastidx = end
    if offset == -1 && lastidx == 0
        lastidx = length(timestamps)
    end

    firstidx = 1

    if frequency == :Day
        firstidx = ct > 0 ? ((lastidx - ct + 1 > 0) ? lastidx - ct + 1 : 1) : 1
    else
        dd = unique(Date.(timestamps))
        firstDate = dd[max(1, end-ct+1):end]
        firstidx = findlast(x -> x >= DateTime(firstDate), timestamps)
    end

    lastidx > 0 ? dropnan(length(ta) == 0 ? ta : 
        d < TimeSeries.timestamp(ta)[1] ? ta[1:0] :
        d > TimeSeries.timestamp(ta)[end] ? ta[firstidx:end] :
        ta[firstidx:lastidx], :all) : nothing
end

function getsubset(ta::TimeArray, sd::DateTime, ed::DateTime, offset::Int=5, frequency::Symbol = :Day)
    ##BUG HERE (what if sd to ed has just one data point
    output = nothing

    if frequency == :Day
        output = to(from(ta, Date(sd)), Date(ed)) #Empty output is timeseries object and NOT nothing
    else frequency == :Minute
        #Add one date to end-date because minute data or a date start at 3:45 to 10:00
        output = to(from(ta, sd), ed + Dates.Day(1)) 
    end

    return output != nothing ? length(TimeSeries.timestamp(output)) > 0 ? output : nothing : nothing
end

# array of columns by name
function getindex(ta::TimeArray, names::Vector{Symbol})
    ns = [something(findfirst(isequal(a), TimeSeries.colnames(ta)), 0) for a in names]
    TimeArray(TimeSeries.timestamp(ta), TimeSeries.values(ta)[:,ns], names, TimeSeries.meta(ta))
end

function setupbenchmarkstores(ta::TimeArray, frequency::Symbol)
    if frequency == :Day
        global _benchmarkEODData = ta
    end
end

function compareSizeWithBenchmark(ta; startdate::DateTime = now(), enddate::DateTime = now(), horizon::Int=0, frequency::Symbol=:Day)
    
    if frequency == :Day
        if (horizon == 0)
            return size(ta)[1] < size(to(from(_benchmarkEODData, Date(startdate)), Date(enddate)))[1] ? -1 : 1
        else
            return size(ta)[1] < size(TimeSeries.tail(to(_benchmarkEODData, Date(enddate)), horizon))[1] ? -1 : 1
        end
    else
        #No benchamrk comparison in minute data
        return true
    end
end

function _mergeWithExisting(ta::TimeArray, datatype::String, frequency::Symbol)

    old_ta = fromglobalstores(String.(colnames(ta)), datatype, frequency)

    if old_ta == nothing
        return ta
    end

    oldnames = __getcolnames(old_ta)
    newnames = __getcolnames(ta)
    commonnames = intersect(newnames, oldnames)
    old_common_ta = old_ta[commonnames]
    new_common_ta = ta[commonnames]
    merged_common_ta = nothing

    # BUG FIX REQUIRED: Adjusted prices are adjusted only for the horizon 
    # merging two different horizons leads to price incompatibility
    for ticker in commonnames

        old_common_ta_ticker = old_common_ta[ticker]
        new_common_ta_ticker = new_common_ta[ticker]

        merged_common_ta_ticker = merge(old_common_ta_ticker, new_common_ta_ticker, :outer)
       
        val_old = values(merged_common_ta_ticker[ticker])
        val_new = values(merged_common_ta_ticker[Symbol(String(ticker)*"_1")])


        nrows = length(val_new) #???
        vals = zeros(nrows, 1)
        for i = 1:nrows
            if isnan(val_old[i]) && isnan(val_new[i]) 
                vals[i] = NaN
            elseif  isnan(val_old[i]) && !isnan(val_new[i]) 
                vals[i] = val_new[i]
            elseif !isnan(val_old[i]) && isnan(val_new[i]) 
                vals[i] = val_old[i]
            elseif !isnan(val_old[i]) && !isnan(val_new[i]) 
                vals[i] = val_new[i]
            end
        end

        merged_common_ta_ticker = TimeArray(TimeSeries.timestamp(merged_common_ta_ticker), vals, [ticker])

        if merged_common_ta == nothing
            merged_common_ta = merged_common_ta_ticker
        else
            merged_common_ta = merge(merged_common_ta, merged_common_ta_ticker, :outer)
        end
    end

    # Now merge ta for unique names across old and new TA
    old_diffnames = setdiff(oldnames, newnames)
    old_uncommon_ta = nothing

    if length(old_diffnames) > 0
        old_uncommon_ta = old_ta[old_diffnames]
    end

    new_diffnames = setdiff(newnames, oldnames)
    new_uncommon_ta = nothing
    
    if length(new_diffnames) > 0
        new_uncommon_ta = ta[new_diffnames]
    end

    merged_uncommon_ta = nothing

    if old_uncommon_ta != nothing && new_uncommon_ta != nothing
        merged_uncommon_ta = merge(old_uncommon_ta, new_uncommon_ta, :outer)
    elseif old_uncommon_ta != nothing 
        merged_uncommon_ta = old_uncommon_ta
    elseif new_uncommon_ta != nothing  
        merged_uncommon_ta = new_uncommon_ta
    end

    # final merge
    merged_ta = nothing

    if merged_uncommon_ta != nothing && merged_common_ta != nothing
        merged_ta = merge(merged_uncommon_ta, merged_common_ta, :outer)
    elseif merged_uncommon_ta != nothing
        merged_ta = merged_uncommon_ta
    elseif merged_common_ta != nothing 
        merged_ta = merged_common_ta
    end


    return merged_ta
end

#In case of Redis, we save key/value pairs
#Keys = TICKER_FREQUENCY_DATATYPE (Default frequency = "Minute", Datatype = "Close")
#Values = array of values
#So effetive DS for Redis == RANGE
#Save only unadjusted data
function _updateglobaldatastores(ta::TimeArray, datatype::String, frequency::Symbol)
    
    for (i, name) in enumerate(colnames(ta))

        #Columns are secids
        _ta_this = ta!=nothing ? ta[name] : nothing
        
        #Update incoming ta with existing ta
        if _ta_this != nothing
           _ta_this = _mergeWithExisting(_ta_this, datatype, frequency)
        else
            continue
        end

        _ta_this_values = _ta_this != nothing ? values(_ta_this) : nothing
        _ta_this_names = _ta_this != nothing ? colnames(_ta_this) : Symbol[]
        _ta_this_timestamp = _ta_this != nothing ? timestamp(_ta_this) : (frequency == :Day ? Date[] : DateTime[])

        ticker = string(name)
        key = "$(ticker)_$(string(frequency))_$(datatype)"

        vs = _ta_this_values[:, 1]
        ts = _ta_this_timestamp

        #Filter out nothing
        idx_not_nothing = vs .!= nothing
        vs = vs[idx_not_nothing]
        ts = ts[idx_not_nothing]

        #Filter out NaN
        idx_not_nan = .!isnan.(vs)
        vs = Float64.(vs[idx_not_nan])
        ts = ts[idx_not_nan]
        
        value = Vector{String}(undef, length(ts))
        for (j, dt) in enumerate(ts)
            value[j] = JSON.json(Dict("Date" => dt, "Value" => vs[j]))
        end

        # println("Finally pushing")
        # println(name)
        # println(vs)
        # println(ts)

        Redis.del(redisClient(), key) 
        Redis.lpush(redisClient(), key, value)
    end 
end

# Searches and return TA of available secids
function fromglobalstores(names::Vector{String}, datatype::String, frequency::Symbol)
    
    ta = nothing
    for name in names
        key = "$(name)_$(string(frequency))_$(datatype)"
        value = Redis.lrange(redisClient(), key, 0, -1)

        if length(value) > 0 
            # println("Name: $(name)")
            parsed = JSON.parse.(value)
            vs = (get.(parsed, "Value", NaN))
            
            ts = nothing
            if frequency == :Day
                ts = Date.(get.(parsed, "Date", Date(1)))
            else
                ts = DateTime.(get.(parsed, "Date", DateTime(1)))
            end
            
            # println("VS-1")
            # println(vs)

            #Filter out Nothing
            idx_not_nothing = vs .!= nothing
            vs = vs[idx_not_nothing]
            ts = ts[idx_not_nothing]

            # println("VS-2")
            # println(vs)

            #Filter out Nan
            idx_not_nan = .!isnan.(vs)
            vs = Float64.(vs[idx_not_nan])
            ts = ts[idx_not_nan]

            # println("VS-3")
            # println(vs)

            _ta = TimeArray(ts, vs, [Symbol(name)])

            # # println("_Ta")
            # if _ta != nothing
            #     println(_ta)
            # else
            #     println("_ta is nothing")
            # end

            # println("Ta")
            # if ta != nothing
            #     println(ta)
            # else
            #     println("ta is nothing")
            # end

            if ta == nothing
                ta = _ta
            else 
                ta = merge(ta, _ta, :outer)
            end
        end
    end

    return ta
end

#Time gap based global stores is not GOOD
#If data is not available for all dates, new data is not downloaded
#Added removeNaN flag: remove series if any of the values in NaN
#RemoveNaN is useful because in global data stores, 
#ts can have NaNs for security(not because data is unavailable in DB 
#but because ts are merged)
function findinglobalstores(secids::Vector{Int}, 
                                datatype::String, 
                                frequency::Symbol, 
                                startdate::DateTime, 
                                enddate::DateTime;
                                offset::Int=5,
                                forwardfill::Bool=false,
                                removeNaN::Bool=false,
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")      
    
    full_ta = fromglobalstores(string.(secids), datatype, frequency)
    truenames = full_ta != nothing ? colnames(full_ta) : Symbol[]

    #Merge with benchmark data as a filter
    if frequency == :Day
        full_ta = full_ta != nothing ? merge(full_ta, to(from(_benchmarkEODData, Date(startdate)), Date(enddate)), :outer) : nothing
    else 
        full_ta = full_ta != nothing ? to(from(full_ta, startdate), enddate + Dates.Day(1)) : nothing
    end

    if forwardfill
        full_ta = __forwardfill(full_ta)
    end

    full_ta = full_ta != nothing ? getsubset(full_ta, startdate, enddate, offset, frequency) : nothing
    
    #Remove the filter column
    full_ta = full_ta != nothing ? full_ta[truenames] : nothing

    #RemoveNaN removes all columns with ANY NaN values
    #it's a conservative check and is not used as second step
    #At second step, drop all rows if all are NaNs
    output = removeNaN ? removeNaNs(full_ta) : full_ta != nothing ? dropnan(full_ta, :all) : nothing
    return output != nothing && length(output) > 0 ? output : nothing
       
end

#Added removeNaN flag: remove series if any of the values in NaN
function findinglobalstores(secids::Vector{Int}, 
                                datatype::String, 
                                frequency::Symbol, 
                                horizon::Int, 
                                enddate::DateTime;
                                offset::Int=5,
                                forwardfill::Bool=false,
                                removeNaN::Bool=false,
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")
    
    full_ta = fromglobalstores(string.(secids), datatype, frequency)

    truenames = full_ta != nothing ? colnames(full_ta) : Symbol[]

    #Merge with benchmark data as a filter
    if frequency == :Day
        full_ta = full_ta!=nothing ? merge(full_ta, TimeSeries.tail(to(_benchmarkEODData, Date(enddate)), horizon), :outer) : nothing
    else
        full_ta = full_ta!=nothing ? TimeSeries.tail(to(full_ta, enddate), horizon) : nothing
    end
    
    if forwardfill
        full_ta = __forwardfill(full_ta)
    end

    full_ta = full_ta!=nothing ? getsubset(full_ta, enddate, horizon, offset, frequency) : nothing

    #Remove the filter columns
    full_ta = full_ta != nothing ? full_ta[truenames] : nothing

    #RemoveNaN removes all columns with ANY NaN values
    #it's a conservative check and is not used as second step
    #At second step, drop all rows if all are NaNs
    output = removeNaN ? removeNaNs(full_ta) : full_ta != nothing ? dropnan(full_ta, :all) : nothing
    return output != nothing && length(output) > 0 ? output : nothing
end

function removeNaNs(full_ta)

    if full_ta != nothing
        allnames = __getcolnames(full_ta)
        hasNaNs = Symbol[]

        for name in allnames
            vals = values(full_ta[name])
            # Conservative check
            # If a single NaN is present, re-fetch the prices
            if length(vals[isnan.(vals)]) > 0
                push!(hasNaNs, name)
            end
        end

        return full_ta[setdiff(allnames, hasNaNs)]
    else
        return nothing
    end
end
