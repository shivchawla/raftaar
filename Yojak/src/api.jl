
import Base.convert

_isBenchmarkEODDataInitialized = false
_isBenchmarkMinuteDataInitialized = false

function __renamecolumns(ta)
    secids = Int[Meta.parse(String(name)) for name in __getcolnames(ta)] 
    ta!=nothing ? TimeSeries.rename(ta, Symbol.([getsecurity(secid).symbol.ticker for secid in secids])) : ta
end

function __fillmissingdata(ta, secids)
    #Special logic to add data for missing secids 
    #Add NaN for missing secids

    secids = [Symbol(secid) for secid in secids]

    missing_secids = setdiff(secids, __getcolnames(ta)) 
    n_missing_secids = length(missing_secids)
    if n_missing_secids != 0 && ta!=nothing
        arr = zeros(length(ta), n_missing_secids)/0
        m_ta = TimeArray(TimeSeries.timestamp(ta), arr, Symbol.(missing_secids))
        ta = merge(ta, m_ta, :outer)[secids]  
    end

    return ta
end

function _populateBenchmarkStore(frequency)

    if frequency == :Day && !_isBenchmarkEODDataInitialized
        Logger.update_display(false)
        bnch_ta = _history_unadj(securitycollection(), datacollection(), 
                                [getsecurity("NIFTY_50").symbol.id], 
                                "Close", :Day,
                                DateTime("2007-01-01"), now(),
                                "EQ",
                                "NSE",
                                "IN", false)
         
        bnch_ta = TimeSeries.rename(bnch_ta, Symbol.(["_NIFTY_50_filter"]))

        setupbenchmarkstores(bnch_ta, frequency)

        global _isBenchmarkEODDataInitialized = true
        Logger.update_display(true)
    
    end
        
end

function _adjust(ta::TimeArray; displaylogs::Bool=true, frequency::Symbol = :Day)

    Logger.update_display(displaylogs)

    ts = TimeSeries.timestamp(ta)
    adjustments = _get_adjustments_factors(datacollection(), string.(colnames(ta)),
                        DateTime(ts[1] - Dates.Day(10)), DateTime(ts[end]),
                        "EQ", "NSE", "IN")

    eff_ta = nothing
    
    for (i, name) in enumerate(colnames(ta))
        adjustment_vals = get(adjustments, String(name), Matrix{Any}(nothing, 0, 0))

        #Default adjusted ta is same as input ta (used when there is a problem in adjustments)
        _ta = ta[name]

        if adjustment_vals != Matrix{Any}(nothing, 0, 0)
            _adj_ta = TimeArray([Date(dt) for dt in adjustment_vals[:,1]], cumprod([abs(Float64(ai)) for ai in adjustment_vals[:,2]]), Symbol.(["Adj_$(String(name))"]))

            #how to DO metrge in case of intraday data
            if frequency == :Day
                _ta = merge(ta[name], _adj_ta, :outer)
                
                _ta = _ta[name].*__forwardfill(_ta[Symbol("Adj_$(String(name))")])
                _vals_ta = TimeSeries.values(_ta)
                _not_nan_idx = .!isnan.(_vals_ta) 
                _vals_ta[_not_nan_idx] = round.(_vals_ta[_not_nan_idx], digits = 2)
                _ta = TimeSeries.TimeArray(TimeSeries.timestamp(_ta), _vals_ta, [name])
            
            else
 
                _ta_ts = TimeSeries.timestamp(_ta)
                _ta_ts_dates = unique(Date.(_ta_ts))
 
                if length(_ta_ts_dates) > 1 #if more than one date, then only adjust

                    _adj_ta_name = _adj_ta[Symbol("Adj_$(String(name))")]
                    _adj_ta_ts = TimeSeries.timestamp(_adj_ta_name)
                    _adj_ta_values = TimeSeries.values(_adj_ta_name)
     
                    _ta_values = TimeSeries.values(_ta)

                    for (i,dt) in enumerate(_adj_ta_ts)
                        cmn_idx = Date.(_ta_ts) .== dt
                        _ta_values[cmn_idx] = _ta_values[cmn_idx]*_adj_ta_values[i]

                    end

                    _ta = TimeSeries.TimeArray(_ta_ts, _ta_values, [name]) 
                end

            end

        end 

        if eff_ta == nothing
             eff_ta = _ta
        else
            eff_ta = merge(eff_ta, _ta, :outer)
        end
    end

    eff_ta = TimeSeries.rename(eff_ta, colnames(ta))
    Logger.update_display(true)
    return eff_ta
end

######## HORIZON BASED
function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int,
                    enddate::DateTime;
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN",
                    displaylogs::Bool=true,
                    strict::Bool=true,
                    forwardfill::Bool=false)
    
    # IMPLEMENTATION HERE
    unadj_history = history_unadj(secids, datatype, frequency, 
        horizon, enddate,
        securitytype = securitytype,
        exchange = exchange,
        country = country,
        displaylogs = displaylogs,
        offset = -1,
        strict = strict,
        forwardfill = forwardfill)
    
    try
        adjusted_ta = unadj_history != nothing && horizon > 0 ? _adjust(unadj_history, displaylogs = displaylogs, frequency = frequency) : unadj_history

        return adjusted_ta != nothing ? 
            frequency == :Day ? TimeSeries.tail(to(adjusted_ta, Date(enddate)), horizon) :
                adjusted_ta : nothing

                #Update logic to do final fetch between datetimes (based on horizon)
                #TimeSeries.tail(to(adjusted_ta, enddate), horizon) : nothing
    catch err
        if strict
            rethrow(err)
        else
            return unadj_history
        end
    end    
end

history(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers], 
                                    datatype, 
                                    frequency, 
                                    horizon, 
                                    edate, 
                                    securitytype = securitytype,
                                    exchange = exchange,
                                    country = country,
                                    displaylogs = displaylogs,
                                    strict = strict,
                                    forwardfill = forwardfill)

history(secids::Array{Int,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::String;
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        horizon,
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)

history(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::String;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        horizon,
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)

history(securities::Array{Security,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history([security.symbol.id for security in securities],
                                        datatype,
                                        frequency,
                                        horizon,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)

############ PERIOD BASED
function history(secids::Vector{Int},
                    datatype::String,
                    frequency::Symbol,
                    startdate::DateTime,
                    enddate::DateTime;                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN",
                    displaylogs::Bool=true,
                    strict::Bool=true,
                    forwardfill::Bool=false) 
    
    #IMPLEMENTATION HERE
    unadj_history = history_unadj(secids, datatype, frequency, 
        startdate, enddate,
        securitytype = securitytype,
        exchange = exchange,
        country = country,
        displaylogs = displaylogs,
        strict = strict,
        forwardfill = forwardfill)
    
    try
        adjusted_ta = enddate > startdate && unadj_history != nothing ? 
            _adjust(unadj_history, displaylogs = displaylogs, frequency = frequency) :
            unadj_history
        
        return adjusted_ta!=nothing ? 
            frequency == :Day ? TimeSeries.from(to(adjusted_ta, Date(enddate)), Date(startdate)) :
                adjusted_ta  : nothing
                #Update logic to do final fetch between datetimes
                #TimeSeries.from(to(adjusted_ta, DateTime(Date(enddate) + Dates.Day(1)), startdate) : nothing
    catch err
        if strict
            rethrow(err)
        else
            return unadj_history
        end
    end
end

history(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        sdate::DateTime,                    
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        sdate,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)

history(secids::Array{Int,1},
        datatype::String,
        frequency::Symbol,
        sdate::String,                    
        edate::String;
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history(secids,
                                        datatype,
                                        frequency,
                                        DateTime(sdate),
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)

history(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        sdate::String,
        edate::String;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        DateTime(sdate),
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)



function history_unadj(secid::Int,
                    datatypes::Vector{String},
                    frequency::Symbol,
                    startdate::DateTime,
                    enddate::DateTime;                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN",
                    displaylogs::Bool=true,
                    strict::Bool=true,
                    forwardfill::Bool=false)

    _history_unadj(securitycollection(), 
                    frequency == :Day ? datacollection() : minutedatacollection(),
                    secid,
                    datatypes, frequency,
                    startdate, enddate,
                    securitytype,
                    exchange,
                    country,
                    strict) 

end 


#This is not adjusted ....NEEDS FIX!!!!
function history(secid::Int,
                    datatypes::Vector{String},
                    frequency::Symbol,
                    startdate::DateTime,
                    enddate::DateTime;                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN",
                    displaylogs::Bool=true,
                    strict::Bool=true,
                    forwardfill::Bool=false)

    _history_unadj(securitycollection(), 
                    frequency == :Day ? datacollection() : minutedatacollection(),
                    secid,
                    datatypes, frequency,
                    startdate, enddate,
                    securitytype,
                    exchange,
                    country,
                    strict) 

end 


history(ticker::String,
        datatypes::Vector{String},
        frequency::Symbol,
        sdate::DateTime,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history(getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country), 
                                        datatypes,
                                        frequency,
                                        sdate,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)

export history

function history_unadj(secids::Vector{Int},
                        datatype::String,
                        frequency::Symbol,
                        horizon::Int,
                        enddate::DateTime;
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN",
                        displaylogs::Bool=true,
                        offset::Int=5,
                        strict::Bool=true,
                        forwardfill::Bool=false) 
    
    println("History unadj between dates: $(now())")
    println("Freqeuncy: $(frequency), Datatype: $(datatype), horizon: $(horizon)")

    _populateBenchmarkStore(frequency)

    Logger.update_display(displaylogs)
    if length(secids) == 0
        Logger.update_display(true)
        return nothing
    end

    println("Finding in global stores $(now())")
    ta = findinglobalstores(secids, datatype, frequency, 
                                horizon, enddate,
                                offset = -1,
                                removeNaN = frequency == :Day ? true : false,
                                forceRedis = true,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)
    
    cols = Int[Meta.parse(String(name)) for name in __getcolnames(ta)]

    # println("Cols: $(cols)")
    # println("Secids: $(secids)")

    if length(setdiff(secids, cols)) == 0 && compareSizeWithBenchmark(ta, enddate = enddate, horizon = horizon) != -1
        Logger.update_display(true)
        return __renamecolumns(ta)
    end

    println("OOPS! Data not sufficient: $(now())")
    println("Fetching from DB: $(now())")

    more_ta = _history_unadj(securitycollection(), 
                            frequency == :Day ? datacollection() : minutedatacollection(),
                            secids, #setdiff(secids, cols),  NEEDS IMPROVEMENT
                            datatype, frequency,
                            horizon, enddate,
                            securitytype,
                            exchange,
                            country, strict) 

    println("Again updating the global data stores: $(now())")
    if (more_ta != nothing)
       _updateglobaldatastores(more_ta, datatype, frequency)
    end

    println("Again finding in the global data stores: $(now())")

    #finally get from updated global stores
    ta = findinglobalstores(secids, datatype, frequency,
                                horizon, enddate,
                                offset = offset,
                                forwardfill = forwardfill,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)

    ta = __fillmissingdata(ta, secids)

    Logger.update_display(true)
    return __renamecolumns(ta)
end

function history_unadj(secids::Vector{Int},
                        datatype::String,
                        frequency::Symbol,
                        startdate::DateTime,
                        enddate::DateTime;
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN",
                        displaylogs::Bool = true,
                        strict::Bool = true,
                        forwardfill::Bool=false) 

    println("History unadj between dates: $(now())")
    println("Freqeuncy: $(frequency), Datatype: $(datatype)")
    
    _populateBenchmarkStore(frequency)

    Logger.update_display(displaylogs)
    if length(secids) == 0
        Logger.update_display(true)
        return nothing
    end

    println("Finding in global stores $(now())")
    ta = findinglobalstores(secids, datatype, frequency,
                                startdate, enddate,
                                removeNaN = frequency == :Day ? true : false,
                                forceRedis = true,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)


    cols = Int[Meta.parse(String(name)) for name in __getcolnames(ta)]

    if length(setdiff(secids, cols)) == 0 && compareSizeWithBenchmark(ta, startdate = startdate, enddate = enddate) != -1
        Logger.update_display(true)
        return __renamecolumns(ta)
    end

    println("OOPS! Data not sufficient: $(now())")
    println("Fetching from DB: $(now())")

    more_ta = _history_unadj(securitycollection(), 
                        frequency == :Day ? datacollection() : minutedatacollection(),
                        secids, #setdiff(secids, cols), NEEDS IMPROVEMENT
                        datatype, frequency,
                        startdate, enddate,
                        securitytype,
                        exchange,
                        country, strict)


    println("Again updating the global data stores: $(now())")

    if (more_ta != nothing)
        _updateglobaldatastores(more_ta, datatype, frequency)
    end

    println("Again finding in the global data stores: $(now())")

    #finally get from updated global stores
    ta = findinglobalstores(secids, datatype, frequency,
                                startdate, enddate,
                                forwardfill = forwardfill,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)

    println("Finally done: $(now())")

    ta = __fillmissingdata(ta, secids)

    Logger.update_display(true)
    return __renamecolumns(ta)
end

history_unadj(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool = true,
        offset::Int=5,
        strict::Bool=true,
        forwardfill::Bool=false) = history_unadj([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        horizon,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        offset = offset,
                                        strict = strict,
                                        forwardfill = forwardfill)

history_unadj(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        sdate::DateTime,                    
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true,
        forwardfill::Bool=false) = history_unadj([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        sdate,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict,
                                        forwardfill = forwardfill)

export history_unadj


function getadjustments(tickers::Array{String,1}, 
                        sdate::DateTime, 
                        edate::DateTime;
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN",
                        displaylogs::Bool=true)
    
    Logger.update_display(displaylogs)

    adjs = _get_adjustments(datacollection(), 
                        tickers,
                        sdate, 
                        edate,
                        securitytype,
                        exchange,
                        country
                    )
    Logger.update_display(true)

    return adjs
    
end

function getadjustments(secids::Array{Int,1}, 
                        sdate::DateTime, 
                        edate::DateTime; 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN",
                        displaylogs::Bool = true)
    
    Logger.update_display(displaylogs)
    adjs = _get_adjustments(datacollection(), 
                        secids,
                        sdate, 
                        edate,
                        securitytype,
                        exchange,
                        country)

    Logger.update_display(true) 

    return adjs

end 


function getadjustments(securities::Array{Security,1}, 
                        sdate::DateTime, 
                        edate::DateTime; 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN",
                        displaylogs::Bool = true)
    
    Logger.update_display(displaylogs)
    secids = Vector{Int}(length(securities))

    for i = 1:length(securities)
        secids[i] = securities[i].symbol.id
    end

    adjs = _get_adjustments(datacollection(), 
                        secids,
                        sdate, 
                        edate,
                        securitytype,
                        exchange,
                        country
                    )

    Logger.update_display(true)

    return adjs
end

export getadjustments 

function getsecurity(ticker::String; 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")
    
    mticker = ticker*"_"*securitytype*"_"*exchange*"_"*country
    
    if haskey(_tickertosecurity, mticker)
        return _tickertosecurity[mticker]
    else
        security = getsecurity(securitycollection(), ticker, 
                        securitytype, 
                        exchange, 
                        country)

        _tickertosecurity[mticker] = security
        
        return security 
    end 

end

function getsecurity(secid::Int64, search::Bool = false)

    if haskey(_seciddtosecurity, secid) && !search
        return _seciddtosecurity[secid]
    else
        security = getsecurity(securitycollection(), secid)
        _seciddtosecurity[secid] = security

        return security
    end
end

export getsecurity

function getsecurities(hint::String, limit::Int, outputType::String)
    
    q = Dict()

    if hint!=""
        matchhint = "^(.*?($(hint))[^\$]*)\$"
        
        q1 = Dict("ticker" => Dict("\$regex" => matchhint, "\$options" => "i"))
        q2 = Dict("name" => Dict("\$regex" => matchhint, "\$options" => "i"))

        nostartwithCNX = "^((?!^CNX).)*\$"
        q3 = Dict("ticker" => Dict("\$regex" => nostartwithCNX))

        nostartwithMF = "^((?!^MF).)*\$"
        q4 = Dict("ticker" => Dict("\$regex" => nostartwithMF))

        nostartwithLIC = "^((?!^LIC).)*\$"
        q5 = Dict("ticker" => Dict("\$regex" => nostartwithLIC))

        nostartwithICNX = "^((?!^ICNX).)*\$"
        q6 = Dict("ticker" => Dict("\$regex" => nostartwithICNX))

        nostartwithSPCNX = "^((?!^SPCNX).)*\$"
        q7 = Dict("ticker" => Dict("\$regex" => nostartwithSPCNX))

        q8 = Dict("ticker" => Dict("\$ne" => ""))

        q = Dict("\$and" => [Dict("\$or" => [q1, q2]), q3, q4, q5, q6, q7, q8])
    end

    if outputType == ""

        alldocs = Mongoc.collect(Mongoc.find(securitycollection(), q , Mongoc.BSON(Dict("name"=>1, "ticker"=>1, "exchange"=>1, "securitytype"=>1,"country"=>1, "_id"=>0)), Mongoc.BSON(Dict("limit" => limit))))

        allsecurities = []
        for doc in alldocs
            push!(allsecurities, getsecurity(JSON.parse(Mongoc.as_json(doc))["ticker"]))
        end

        return allsecurities
    elseif outputType == "count"
        ct = Mongoc.count_documents(securitycollection(), Mongoc.BSON(q))
        return ct
    end

end
export getsecurities

function getsecurityid(ticker::String; securitytype::String="EQ", 
        exchange::String="NSE",
        country::String="IN")

    security = getsecurity(ticker, 
                securitytype = securitytype,
                exchange = exchange,
                country = country)

    return security.symbol.id
end 

export getsecurityid

function getsecurityids(tickers::Array{String,1}; 
    securitytype::String="EQ", 
    exchange::String="NSE",
    country::String="IN")

    secids = [getsecurity(ticker, 
                securitytype = securitytype,
                exchange = exchange,
                country = country).symbol.id for ticker in tickers]
end  
export getsecurityids

function reset()
    for (k,v) in _globaldatastores
        delete!(_globaldatastores, k)
    end
end

