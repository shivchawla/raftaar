
import Base.convert

function __renamecolumns(ta)
    secids = Int[parse(name) for name in __getcolnames(ta)] 
    ta!=nothing ? TimeSeries.rename(ta, [getsecurity(secid).symbol.ticker for secid in secids]) : ta
end

function __fillmissingdata(ta, secids)
    #Special logic to add data for missing secids 
    #Add NaN for missing secids

    secids = ["$secid" for secid in secids]

    missing_secids = setdiff(secids, __getcolnames(ta)) 
    n_missing_secids = length(missing_secids)
    if n_missing_secids != 0 && ta!=nothing
        arr = zeros(length(ta), n_missing_secids)/0
        m_ta = TimeArray(timestamp(ta), arr, missing_secids)
        ta = merge(ta, m_ta, :outer)[secids]  
    end

    return ta
end

function history_old(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int,
                    enddate::DateTime;
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN",
                    displaylogs::Bool=true,
                    strict::Bool=true)
    
    Logger.update_display(displaylogs)
    if length(secids) == 0
        Logger.update_display(true)
        return nothing
    end

    #Retrieves the AVAILABLE data (some secids may be missing)
    ta = findinglobalstores(secids, datatype, frequency, horizon, enddate,
                                removeNaN = true, 
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)
    
    #adding check for size of ta (without NaN)
    cols = ta!=nothing ? length(ta) >= horizon ? Int[parse(name) for name in __getcolnames(ta)] : Int[] : Int[]

    if length(setdiff(secids, cols)) == 0 
        Logger.update_display(true)
        return __renamecolumns(ta)
    end
    
    
    more_ta = _history(securitycollection(), datacollection(), 
                        setdiff(secids, cols), 
                        datatype, frequency, horizon, enddate, 
                        securitytype,
                        exchange,
                        country, strict)

    if (more_ta != nothing)
        _updateglobaldatastores(datatype, more_ta)
    end

    #finally get from updated global stores
    ta = findinglobalstores(secids, datatype, frequency, horizon, enddate,
                                offset = -1,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)
    
    #Special logic to add data for missing secids 
    #Add NaN for missing secids
    ta = __fillmissingdata(ta, secids)

    Logger.update_display(true)
    return __renamecolumns(ta)
end


#=history(tickers::Array{Any,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN") = history([String(ticker) for ticker in tickers],
                                    datatype, 
                                    frequency, 
                                    horizon, 
                                    edate, 
                                    securitytype = securitytype,
                                    exchange = exchange,
                                    country = country)=#

history_old(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true) = history1([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers], 
                                    datatype, 
                                    frequency, 
                                    horizon, 
                                    edate, 
                                    securitytype = securitytype,
                                    exchange = exchange,
                                    country = country,
                                    displaylogs = displaylogs,
                                    strict = strict)

history(secids::Array{Int,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::String;
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        horizon,
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)

history(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::String;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        horizon,
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)

history(securities::Array{Security,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true) = history([security.symbol.id for security in securities],
                                        datatype,
                                        frequency,
                                        horizon,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)

############
function history(secids::Vector{Int},
                    datatype::String,
                    frequency::Symbol,
                    startdate::DateTime,
                    enddate::DateTime;                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN",
                    displaylogs::Bool=true,
                    strict::Bool=true) 
    
    Logger.update_display(displaylogs)
    if length(secids) == 0
        Logger.update_display(true)
        return nothing
    end

    ta = findinglobalstores(secids, datatype, frequency, startdate,  enddate,
                                removeNaN = true,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)

    cols = Int[parse(name) for name in __getcolnames(ta)]

    if length(setdiff(secids, cols)) == 0 
        Logger.update_display(true)
        return __renamecolumns(ta)
    end

    
    more_ta = _history(securitycollection(), datacollection(), 
                        setdiff(secids, cols), 
                        datatype, frequency, 
                        startdate, enddate,
                        securitytype,
                        exchange,
                        country,
                        strict)

    if (more_ta != nothing)
        _updateglobaldatastores(datatype, more_ta)
    end
    
    #finally get from updated global stores
    ta = findinglobalstores(secids, datatype, frequency, startdate, enddate,
                                offset = -1,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)

    #Special logic to add data for missing secids 
    #Add NaN for missing secids
    ta = __fillmissingdata(ta, secids)  

    Logger.update_display(true)
    return __renamecolumns(ta)
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
        strict::Bool=true) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        sdate,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)

history(secids::Array{Int,1},
        datatype::String,
        frequency::Symbol,
        sdate::String,                    
        edate::String;
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true) = history(secids,
                                        datatype,
                                        frequency,
                                        DateTime(sdate),
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)

history(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        sdate::String,
        edate::String;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true) = history([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        DateTime(sdate),
                                        DateTime(edate),
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)



function history_unadj(secid::Int,
                    datatypes::Vector{String},
                    frequency::Symbol,
                    startdate::DateTime,
                    enddate::DateTime;                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN",
                    displaylogs::Bool=true,
                    strict::Bool=true)

    _history_unadj(securitycollection(), datacollection(), 
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
        strict::Bool=true) = history(getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country), 
                                        datatypes,
                                        frequency,
                                        sdate,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)

export history

#=history_unadj(secids::Array{Int,1},
        datatype::String,
        frequency::Symbol,
        horizon::Int,
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN") = _history_unadj(securitycollection(),
                                        datacollection(), 
                                        secids,
                                        datatype,
                                        frequency,
                                        horizon,
                                        edate,
                                        securitytype,
                                        exchange,
                                        country)=#


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
                        strict::Bool=true) 
    
    Logger.update_display(displaylogs)
    if length(secids) == 0
        Logger.update_display(true)
        return nothing
    end

    ta = findinglobalstores(secids, "Unadj_"*datatype, frequency, 
                                horizon, enddate,
                                removeNaN = true,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)
    
    cols = Int[parse(name) for name in __getcolnames(ta)]

    if length(setdiff(secids, cols)) == 0 
        Logger.update_display(true)
        return __renamecolumns(ta)
    end
    
    more_ta = _history_unadj(securitycollection(), datacollection(), 
                            setdiff(secids, cols), 
                            datatype, frequency,
                            horizon, enddate,
                            securitytype,
                            exchange,
                            country, strict) 
    if (more_ta != nothing)
        _updateglobaldatastores("Unadj_"*datatype, more_ta)
    end
    
    #finally get from updated global stores
    ta = findinglobalstores(secids, "Unadj_"*datatype, frequency,
                                horizon, enddate,
                                offset = offset,
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
                        strict::Bool = true) 
    
    Logger.update_display(displaylogs)
    if length(secids) == 0
        Logger.update_display(true)
        return nothing
    end

    ta = findinglobalstores(secids, "Unadj_"*datatype, frequency,
                                removeNaN = true, 
                                startdate, enddate,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country)
    
    cols = Int[parse(name) for name in __getcolnames(ta)]

    if length(setdiff(secids, cols)) == 0 
        Logger.update_display(true)
        return __renamecolumns(ta)
    end

    more_ta = _history_unadj(securitycollection(), datacollection(),
                            setdiff(secids, cols), 
                            datatype, frequency,
                            startdate, enddate,
                            securitytype,
                            exchange,
                            country, strict)

    if (more_ta != nothing)
        _updateglobaldatastores("Unadj_"*datatype, more_ta)
    end
    
    #finally get from updated global stores
    ta = findinglobalstores(secids, "Unadj_"*datatype, frequency,
                                startdate, enddate,
                                securitytype = securitytype,
                                exchange = exchange,
                                country = country) 

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
        strict::Bool=true) = history_unadj([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        horizon,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        offset = offset,
                                        strict = strict)

#=history_unadj(secids::Array{Int,1},
        datatype::String,
        frequency::Symbol,
        sdate::DateTime,                    
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN") = _history_unadj(securitycollection(),
                                        datacollection(), 
                                        secids,
                                        datatype,
                                        frequency,
                                        sdate,
                                        edate,
                                        securitytype,
                                        exchange,
                                        country)=#

history_unadj(tickers::Array{String,1},
        datatype::String,
        frequency::Symbol,
        sdate::DateTime,                    
        edate::DateTime;                    
        securitytype::String="EQ",
        exchange::String="NSE",
        country::String="IN",
        displaylogs::Bool=true,
        strict::Bool=true) = history_unadj([getsecurityid(ticker, securitytype = securitytype, exchange = exchange, country = country) for ticker in tickers],
                                        datatype,
                                        frequency,
                                        sdate,
                                        edate,
                                        securitytype = securitytype,
                                        exchange = exchange,
                                        country = country,
                                        displaylogs = displaylogs,
                                        strict = strict)

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

        alldocs = find(securitycollection(), q , Dict("name"=>1, "ticker"=>1, "exchange"=>1, "securitytype"=>1,"country"=>1, "_id"=>0), limit = limit)

        allsecurities = []
        for doc in alldocs
            push!(allsecurities, getsecurity(LibBSON.dict(doc)["ticker"]))
        end

        return allsecurities
    elseif outputType == "count"
        ct = count(securitycollection(), q)
        println("Count: $(ct)")
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
