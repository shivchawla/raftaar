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
    # println("Subset")
    # println(timestamps)
    if frequency == :Day
        for i=0:(offset == -1 ? length(timestamps) : offset)
            
            nd = Date(d) - Dates.Day(i)
            lastidx = findlast(x -> x <= nd, timestamps)

            if lastidx == nothing || lastidx > 0
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
    if offset == -1 && isnothing(lastidx)
        lastidx = length(timestamps)
    elseif isnothing(lastidx)
        lastidx = 0
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

#array of columns by name
function getindex(ta::TimeArray, names::Vector{Symbol})
    ns = [findfirst(isequal(a), TimeSeries.colnames(ta)) for a in names]
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

    isDifferent = false
    old_ta = nothing
    if frequency != Day
        old_ta = fromglobalstores(String.(colnames(ta)), datatype, frequency)

        storedTa = nothing
        try
            storedTa = old_ta[timestamp(ta)][colnames(ta)]
        catch err
        end

        if storedTa != nothing
            for nm in colnames(ta)
                nmta = dropnan(ta[nm])
                nmstoredTa = nothing
                try
                    nmstoredTa = dropnan(storedTa[nm])
                catch err
                end

                if nmstoredTa == nothing || nmstoredTa != nmta
                    isDifferent = true
                    break
                end
            end

        else 
            isDifferent = true  
        end

        if (!isDifferent) 
            println("Incoming TA is already present")
            return
        end

    else 
        old_ta = haskey(_globaldatastores, datatype) ? _globaldatastores[datatype] : nothing
    end

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

    if haskey(_globaldatastores, datatype)
        isDifferent = false

        storedTa = nothing
        try 
            storedTa = _globaldatastores[datatype][timestamp(ta)][colnames(ta)]
        catch err
        end
        
        if storedTa != nothing
            for nm in colnames(ta)
                nmta = dropnan(ta[nm])

                nmstoredTa  = nothing
                try
                    nmstoredTa = dropnan(storedTa[nm])
                catch err
                end

                if nmstoredTa == nothing ||  nmta != storedTa
                    isDifferent = true
                    break
                end
            end
        else 
            isDifferent  = true
        end

        if (!isDifferent)
            println("Incoming TA is already present")
            return 
        end
    end

    merged_ta = _mergeWithExisting(ta, datatype, frequency)

    if (merged_ta != nothing && frequency == :Day)
        _globaldatastores[datatype] = merged_ta 

        #Updating Redis is slow because of redundant updates
        #return
    end

    # println("Updating for all names")
    for (i, name) in enumerate(colnames(ta))

        #Columns are secids
        _ta_this = merged_ta!=nothing ? merged_ta[name] : nothing
        
        # #Update incoming ta with existing ta
        # if _ta_this != nothing
        #    _ta_this = _mergeWithExisting(_ta_this, datatype, frequency)
        # else
        #     continue
        # end

        if _ta_this != nothing
            _ta_this_values = values(_ta_this)
            _ta_this_names = colnames(_ta_this)
            _ta_this_timestamp = timestamp(_ta_this) 
            
            vs = _ta_this_values[:,1]
            ts = _ta_this_timestamp 

            #Filter out nothing/NaN
            idx_not_valid = (vs .!= nothing) .& (.!isnan.(vs)) 
            vs = Float64.(vs[idx_not_valid])
            ts = ts[idx_not_valid]

            yearFormattedDates = Dates.format.(ts, "yyyy")
            monthFormattedDates = Dates.format.(ts, "yyyymm")

            timeunits = frequency == :Day ? unique(yearFormattedDates)  : unique(monthFormattedDates) 
            
            for timeunit in timeunits
                ticker = string(name)
                key = "$(ticker)_$(string(frequency))_$(datatype)_$(timeunit)"

                _vs = []
                _ts = []
                
                idx = nothing
                if frequency == :Day
                    idx = yearFormattedDates .== timeunit
                else
                    idx = monthFormattedDates .== timeunit
                end

                _vs = vs[idx]
                _ts = ts[idx]

                value = Vector{String}(undef, length(_ts))
                for (j, dt) in enumerate(_ts)
                    value[j] = JSON.json(Dict("Date" => dt, "Value" => _vs[j]))
                end

                if length(value) > 0
                    Redis.del(redisClient(), key) 
                    Redis.lpush(redisClient(), key, value)
                end
            end
        end
    end 
end

# Searches and return TA of available secids
function fromglobalstores(names::Vector{String}, datatype::String, frequency::Symbol, startdate::DateTime = DateTime("1990-01-01"), enddate::DateTime = DateTime("2030-01-01"); forceRedis::Bool = false)
    
    # if frequency != :Day
    #     println("Fetching From global store: $(now())")
    # end

    if frequency == :Day && haskey(_globaldatastores, datatype)
        
        ta = _globaldatastores[datatype]

        secids = Symbol.(names)
        columnnames = __getcolnames(ta)
        unavailablenames = setdiff(secids, columnnames)

        if length(unavailablenames) >= 0
            availablenames = setdiff(secids, unavailablenames)
            if length(availablenames) > 0
                return ta[availablenames]
            end

            if !forceRedis
                return nothing
            end
        end

        if !forceRedis
            return ta[secids]
        end
    end

    #If data not available above, search in redis

    #Else read from redis
    timeunits = String[];

    if frequency == :Day
        _sd = Dates.firstdayofyear(Date(startdate))
        while _sd <= enddate
           push!(timeunits, Dates.format.(_sd, "yyyy"))
           _sd = _sd + Dates.Year(1)
       end
    else
        _sd = Dates.firstdayofmonth(Date(startdate))
        while _sd <= enddate
           push!(timeunits, Dates.format.(_sd, "yyyymm"))
           _sd = _sd + Dates.Month(1)
       end
    end

    ta = nothing
    all_fs = []
    uniq_ts = frequency == :Day ? Date[] : DateTime[]
    all_names = Symbol[]

    for name in names
        vs = []
        ts = []
        for timeunit in timeunits
            key = "$(name)_$(string(frequency))_$(datatype)_$(timeunit)"
            value = Redis.lrange(redisClient(), key, 0, -1)

            # println("Key: $(key)")

            if length(value) > 0 
                # println("Name: $(name)")
                parsed = JSON.parse.(value)
                sub_vs = (get.(parsed, "Value", NaN))
                
                sub_ts = nothing
                if frequency == :Day
                    sub_ts = Date.(get.(parsed, "Date", Date(1)))
                else
                    sub_ts = DateTime.(get.(parsed, "Date", DateTime(1)))
                end
                
                sub_fs = [sub_ts sub_vs]
                sub_fs = sub_fs[sub_fs[:,2] .!= nothing, :]
                sub_fs = sub_fs[.!isnan.(sub_fs[:,2]), :]
                sub_fs = sortslices(sub_fs, dims=1, by=x->x[1])

                append!(ts, sub_fs[:,1])
                append!(vs, sub_fs[:,2])
                # println("Sub")
                # println(ts)
                # println(vs)
            end
        end

        if length(ts) > 0
            fs = [ts vs]
            push!(all_fs, fs)
            append!(uniq_ts, fs[:,1])
            push!(all_names, Symbol(name))           
        end
    end

    if length(all_names) > 0
        #Now process TA from all values
        uniq_ts = sort(unique(uniq_ts))
        vals = Matrix{Float64}(undef, length(uniq_ts), length(all_names))

        for (i, name) in enumerate(all_names)

            #Initialize all values as NaN for the column
            vals[:,i] .= NaN
            
            # #LOGIC 1 to merge  O(NlogN)
            # for (j, dt) in enumerate(all_ts[i])
            #     idx = findall(isequal(dt), uniq_ts)
            #     if idx!=nothing && length(idx) !=0
            #         vals[idx[1], i] = all_vs[i][j]
            #     end
            # end

            #LOGIC 2 to merge O(N)
            _tSmall = all_fs[i][:, 1]
            _tBig =  uniq_ts
            if length(_tSmall) == length(_tBig)
                vals[:, i] .= all_fs[i][:, 2]
            else

                # println(_tSmall)
                # println(_tBig)

                j=1
                k=1
                idx = Vector{Int64}(undef, length(_tSmall))
                idx .= 0
                while j <= length(_tBig) && k<=length(_tSmall)
                    if  _tSmall[k] == _tBig[j]
                        idx[k] = j
                        k += 1
                    end
                    j+=1
                end

                # println(idx)
                # println(all_fs[i])
                # println(typeof(all_fs[i]))

                # println(all_fs[i][:,2])
                # println(typeof(all_fs[i][:,2]))

                vals[idx, i] .= all_fs[i][:, 2]
            end
     
        end

        ta = TimeArray(uniq_ts, vals, all_names)    

        # if frequency != :Day
        #     println("Done fetching from global store: $(now())")
        # end

        return ta
    end
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
                                forceRedis::Bool=false,
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")      
    
    full_ta = fromglobalstores(string.(secids), datatype, frequency, startdate, enddate, forceRedis = forceRedis)
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
                                forceRedis::Bool=false,
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")
    
    _guessStartDate = DateTime(frequency == :Day ? Date(enddate) - Dates.Day(2*horizon) : enddate - Dates.Minute(2*horizon)) 
    full_ta = fromglobalstores(string.(secids), datatype, frequency, _guessStartDate, enddate, forceRedis = forceRedis)

    truenames = full_ta != nothing ? colnames(full_ta) : Symbol[]

    #Merge with benchmark data as a filter
    if frequency == :Day
        full_ta = full_ta != nothing ? merge(full_ta, TimeSeries.tail(to(_benchmarkEODData, Date(enddate)), horizon), :outer) : nothing
    else
        full_ta = full_ta != nothing ? TimeSeries.tail(to(full_ta, enddate), horizon) : nothing
    end
    
    if forwardfill
        full_ta = __forwardfill(full_ta)
    end

    full_ta = full_ta != nothing ? getsubset(full_ta, enddate, horizon, offset, frequency) : nothing

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
