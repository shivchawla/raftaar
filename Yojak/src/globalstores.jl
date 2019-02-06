
import Base: getindex

const _globaldatastores = Dict{String, Any}()
const _tickertosecurity = Dict{String, Security}()
const _seciddtosecurity = Dict{Int, Security}() 
_benchmarkData = nothing

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

function getsubset(ta::TimeArray, d::Date, ct::Int=0, offset::Int=5) 

    # Drop NaN before selecting time period 
    ta = dropnan(ta)
    timestamps = TimeSeries.timestamp(ta)

    lastidx = 0

    #special logic to check for offset number of days around the end date (in case end date is unavailable)
    #offset = -1 means inifinite days
    #offset = offset == -1 ? length(timestamps) : offset
    for i=0:(offset == -1 ? length(timestamps) : offset)
        
        nd = d - Dates.Day(i)
        lastidx = findlast(x -> x == nd, timestamps)

        if lastidx > 0
            break
        end
    end

    #Check if lastidx is zero and offset is -1 ====> lastidx = end
    if offset == -1 && lastidx == 0
        lastidx = length(timestamps)
    end

    firstidx = ct > 0 ? ((lastidx - ct + 1 > 0) ? lastidx - ct + 1 : 1) : 1

    lastidx > 0 ? dropnan(length(ta) == 0 ? ta : 
        d < TimeSeries.timestamp(ta)[1] ? ta[1:0] :
        d > TimeSeries.timestamp(ta)[end] ? ta[firstidx:end] :
        ta[firstidx:lastidx], :all) : nothing
end

function getsubset(ta::TimeArray, sd::Date, ed::Date, offset::Int=5)
    ##BUG HERE (what if sd to ed has just one data point
    output = to(from(ta, sd), ed) #Empty output is timeseries object and NOT nothing
    return output != nothing ? length(TimeSeries.timestamp(output)) > 0 ? output : nothing : nothing
end

# array of columns by name
function getindex(ta::TimeArray, names::Vector{Symbol})
    ns = [something(findfirst(isequal(a), TimeSeries.colnames(ta)), 0) for a in names]
    TimeArray(TimeSeries.timestamp(ta), TimeSeries.values(ta)[:,ns], names, TimeSeries.meta(ta))
end

function setupbenchmarkstores(ta::TimeArray, frequency::Symbol)
    global _benchmarkData = ta
end

function compareSizeWithBenchmark(ta; startdate::DateTime = now(), enddate::DateTime = now(), horizon::Int=0)
    if (horizon == 0)
        return size(ta)[1] < size(to(from(_benchmarkData, Date(startdate)), Date(enddate)))[1] ? -1 : 1
    else
        return size(ta)[1] < size(TimeSeries.tail(to(_benchmarkData, Date(enddate)), horizon))[1] ? -1 : 1
    end
end


function _updateglobaldatastores(ta::TimeArray, key::String, frequency::Symbol)
    
    if frequency != :Day
        return
    end

    if !haskey(_globaldatastores, key)
        _globaldatastores[key] = ta 
    else
        old_ta = _globaldatastores[key]
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

        if (merged_ta != nothing)
            _globaldatastores[key] = merged_ta 
        end
    end
end

# Searches and return TA of available secids
function fromglobalstores(secids::Vector{Int}, key::String, frequency::Symbol)
    
    if frequency == :Day

        secids = [Symbol(secid) for secid in secids]
        if haskey(_globaldatastores, key)
            ta = _globaldatastores[key]

            columnnames = __getcolnames(ta)
            unavailablenames = setdiff(secids, columnnames)

            if length(unavailablenames) > 0
                availablenames = setdiff(secids, unavailablenames)
                if length(availablenames) > 0
                    return ta[availablenames]
                end
                
                return nothing
            end

            return ta[secids]
        end
    end

    return nothing
end

function searchsecurity(secid::Int64)

    notfound = false
    if haskey(_globaldatastores, "security")
        if haskey(_globaldatastores["security"], secid)
            return _globaldatastores["security"][secid]
        
        else
            notfound = true
        end
    else
        notfound = true
    end

    if notfound
        if !haskey(_globaldatastores, "security") 
            _globaldatastores["security"] = Dict{Int64, Security}()
        end

        security = getsecurity(secid)
        _globaldatastores["security"][secid] = security
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
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")      
    
    full_ta = fromglobalstores(secids, datatype, frequency)
    truenames = full_ta != nothing ? colnames(full_ta) : Symbol[]

    #Merge with benchmark data as a filter
    full_ta = full_ta != nothing ? merge(full_ta, to(from(_benchmarkData, Date(startdate)), Date(enddate)), :outer) : nothing

    if forwardfill
        full_ta = __forwardfill(full_ta)
    end

    full_ta = full_ta != nothing ? getsubset(full_ta, Date(startdate), Date(enddate), offset) : nothing
    
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
    
    full_ta = fromglobalstores(secids, datatype, frequency)

    truenames = full_ta != nothing ? colnames(full_ta) : Symbol[]

    #Merge with benchmark data as a filter
    full_ta = full_ta!=nothing ? merge(full_ta, TimeSeries.tail(to(_benchmarkData, Date(enddate)), horizon), :outer) : nothing
    
    if forwardfill
        full_ta = __forwardfill(full_ta)
    end

    full_ta = full_ta!=nothing ? getsubset(full_ta, Date(enddate), horizon, offset) : nothing

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
