
using YRead

import YRead: history, getsecurity, getsecurityid, getsecurityids, getsymbol
import Base: getindex, convert

const _globaldatastores = Dict{String, Dict{String, TimeArray}}()


function to{T,N,D}(ta::TimeArray{T,N,D}, d::D, ct::Int = 0)
    last = searchsortedlast(ta.timestamp, d)
    first = ct > 0 ? ((last - ct + 1 > 0) ? last - ct + 1 : 1) : 1
    length(ta) == 0 ? ta : 
        d < ta.timestamp[1] ? ta[1:0] :
        d > ta.timestamp[end] ? ta[first:end] :
        ta[first:last]
end



# array of columns by name
function getindex{T,N,D}(ta::TimeArray{T,N,D}, names::Vector{String})
    ns = [findfirst(ta.colnames, a) for a in names]
    TimeArray(ta.timestamp, ta.values[:,ns], String[a for a in names], ta.meta)
end


function _updateglobaldatastores(key::String, ta::TimeArray)

    for ticker in colnames(ta)
        _updateglobaldatastores(ticker, key , ta[ticker])
    end
end

function _updateglobaldatastores(ticker::String, key::String, ta::TimeArray)
    
    if !haskey(_globaldatastores, ticker)
        _globaldatastores[ticker] = Dict{String, TimeArray}()
        _globaldatastores[ticker][key] = ta
    else
        if !haskey(_globaldatastores[ticker], key)
            _globaldatastores[ticker][key] = ta
        else 
            #APPLY THE SPECIAL MERGE LOGIC
            merged_ta = merge(_globaldatastores[ticker][key], ta, :outer)

            val_old = values(merged_ta[ticker])
            val_new = values(merged_ta[ticker*"_1"])

            nrows = length(val_new)
            vals = zeros(nrows, 1)
            for i = 1:nrows
                if isnan(val_old[i]) && isnan(val_new[i]) 
                    vals[i] = NaN
                elseif  isnan(val_old[i]) && !isnan(val_new[i]) 
                    vals[i] = val_new[i]
                elseif !isnan(val_old[i]) && isnan(val_new[i]) 
                    vals[i] = val_old[i]
                end
            end

            _globaldatastores[ticker][key] = TimeArray(merged_ta.timestamp, vals, [ticker])

        end
    end
end


function fromglobalstore(ticker::String, key::String)
    if haskey(_globaldatastores, ticker)
        if haskey(_globaldatastores[ticker], key)
            return _globaldatastores[ticker][key]
        end
    end

    return nothing
end

function findinglobalstores(tickers::Vector{String}, 
                                datatype::String, 
                                frequency::Symbol, 
                                startdate::DateTime, 
                                enddate::DateTime;
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")  
    
    return nothing
end


function findinglobalstores(tickers::Vector{String}, 
                                datatype::String, 
                                frequency::Symbol, 
                                horizon::Int, 
                                enddate::DateTime;
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")
    
    #println("Here")

    if !haskey(_globaldatastores, datatype)
        return nothing
    else
        full_ta = _globaldatastores[datatype][tickers]
        #println(full_ta)

        return nothing
    end
end

function findinglobalstores(secids::Vector{Int64}, 
                                datatype::String, 
                                frequency::Symbol, 
                                startdate::DateTime, 
                                enddate::DateTime;
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")
    return nothing
end


function findinglobalstores(secids::Vector{Int64}, 
                                datatype::String, 
                                frequency::Symbol, 
                                horizon::Int, 
                                enddate::DateTime;
                                securitytype::String="EQ",
                                exchange::String="NSE",
                                country::String="IN")
    #println("Here - Secids")  

    #tickers = reshape([getsecurity(secid).symbol.ticker for secid in secids], (1, length(secids)))
   
    tickers = vec([getsecurity(secid).symbol.ticker for secid in secids])
    output_ta = nothing
    
    for ticker in tickers
        ta = to(fromglobalstore(ticker, datatype), Date(enddate), horizon)
        
        if ta!=nothing && output_ta == nothing
            output_ta = ta
        elseif ta!=nothing
            output_ta = merge(output_ta, ta, :outer)
        end
    end

    #println("length")
    #println(length(output_ta))

    if(length(output_ta) == horizon)
        #println(output_ta)
    end

    return length(output_ta) < horizon ? nothing : output_ta
      
end



function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime())
    checkforparent([:ondata])
    ids = Vector{Int}(length(securities))

    for i = 1:length(ids)
        ids[i] = securities[i].symbol.id    
    end
    
    history(ids, datatype, frequency, horizon, enddate = enddate)

end

function history(symbols::Vector{SecuritySymbol},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime())
    
    checkforparent([:ondata])
    ids = Vector{Int}(length(symbols))

    for i = 1:length(ids)
        ids[i] = symbols[i].id    
    end
    
    history(ids, datatype, frequency, horizon, enddate = enddate)

end

function history(secids::Array{Int,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int; enddate::DateTime = getcurrentdatetime()) 
    
    SIZE = 50

    if frequency!=:Day
        Logger.info("""Only ":Day" frequency supported in history()""")
        exit()
    end

    checkforparent([:ondata, :_init])

    if enddate == DateTime()
        enddate = getcurrentdatetime()
     elseif !checkforparent([:_init])
        Logger.error("history() can not be called with enddate argument")
        exit()
    end

    secids = length(secids) > SIZE ? secids[1:50] : secids


    ta = findinglobalstores(secids, datatype, frequency, horizon, enddate) 

    if ta!=nothing
        #println("Found")
        return ta
    end

    #println("Not Found")
    ta = YRead.history(secids, datatype, frequency,
            horizon, enddate)

    _updateglobaldatastores(datatype, ta)
    
    return ta 

end

# Based on symbols
function history(tickers::Array{String,1},
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime = getcurrentdatetime(),
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")
    
    SIZE = 50

    if frequency!=:Day
        Logger.info("""Only ":Day" frequency supported in history()""")
        exit(0)
    end

    checkforparent([:ondata, :_init])

    if enddate == DateTime()       
        enddate = getcurrentdatetime()
    elseif !checkforparent([:_init])
        Logger.warn("history() can not be called with enddate argument")
        exit(0)
    end
    
    tickers = length(tickers) > SIZE ? tickers[1:50] : tickers

    #println("findinglobalstores")
    ta = findinglobalstores(tickers, datatype, frequency, horizon, enddate)
    
    if (ta!=nothing)
        return ta
    end
    
    ta = YRead.history(tickers, datatype, frequency,
            horizon, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country) 

    _updateglobaldatastores(datatype, ta)

    return ta 
end


# Period based History
function history(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    ids = Vector{Int}(length(securities))
    for i = 1:length(securities)
        ids[i] = securities[i].symbol.id
    end

    history(ids, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype  =securitytype,
                exchange = exchange,
                country = country)
    
end

function history(symbols::Vector{SecuritySymbol},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    ids = Vector{Int}(length(symbols))
    for i = 1:length(symbols)
        ids[i] = symbols[i].id
    end

    history(ids, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype  =securitytype,
                exchange = exchange,
                country = country)   
end


function history(secids::Vector{Int},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    SIZE = 50

    secids = length(secids) > SIZE ? secids[1:50] : secids

    ta = findinglobalstores(secids, datatype, frequency, startdate, enddate)
    
    if (ta!=nothing)
        return ta
    end

    ta = YRead.history(secids, datatype, frequency, 
                startdate,
                enddate,
                securitytype = securitytype,
                exchange = exchange,
                country = country)

    _updateglobaldatastores(datatype, ta)

    return ta 

end


function history(tickers::Vector{String},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    SIZE = 50

    tickers = length(tickers) > SIZE ? tickers[1:50] : tickers

    ta = findinglobalstores(tickers, datatype, frequency, startdate, enddate)
    
    if (ta!=nothing)
        return ta
    end

    ta = YRead.history(tickers, datatype, frequency,
            startdate, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country) 

    _updateglobaldatastores(datatype, ta)

    return ta 
end

export history



#for Unadjusted History

function history_unadj(securities::Vector{Security},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    ids = Vector{Int}(length(securities))
    for i = 1:length(securities)
        ids[i] = securities[i].symbol.id
    end

    history_unadj(ids, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype = securitytype,
                exchange = exchange,
                country = country)
    
end

function history_unadj(symbols::Vector{SecuritySymbol},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    ids = Vector{Int}(length(symbols))
    for i = 1:length(symbols)
        ids[i] = symbols[i].id
    end

    history_unadj(ids, datatype, frequency, 
                startdate = startdate,
                enddate = enddate,
                securitytype  =securitytype,
                exchange = exchange,
                country = country)   
end

function history_unadj(tickers::Vector{String},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    SIZE = 50

    tickers = length(tickers) > SIZE ? tickers[1:50] : tickers

    ta = findinglobalstores(tickers, "Unadj_"*datatype, frequency, startdate, enddate)
    
    if(ta!=nothing)
        return ta
    end

    ta = YRead.history_unadj(tickers, datatype, frequency,
            startdate, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country) 

    _updateglobaldatastores("Unadj_"*datatype, ta)
    return ta 
end

function history_unadj(secids::Vector{Int},
                    datatype::String,
                    frequency::Symbol;
                    startdate::DateTime = now(),
                    enddate::DateTime = now(),                   
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN") 
    
    SIZE = 50
    secids = length(secids) > SIZE ? secids[1:50] : secids

    ta = findinglobalstores(secids, "Unadj_"*datatype, frequency, startdate, enddate)
    
    if(ta!=nothing)
        return ta
    end

    ta = YRead.history_unadj(secids, datatype, frequency, 
                startdate,
                enddate,
                securitytype = securitytype,
                exchange = exchange,
                country = country)

    _updateglobaldatastores("Unadj_"*datatype, ta)
    return ta 
end

export history_unadj


function getadjustments(tickers::Vector{String},
                        startdate::DateTime, 
                        enddate::DateTime, 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")

    YRead.getadjustments(tickers, datatype, frequency,
            startdate, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country)    
end

function getadjustments(secids::Vector{Int},
                        startdate::DateTime, 
                        enddate::DateTime, 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")
    
    YRead.getadjustments(tickers, datatype, frequency,
            startdate, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country)    
end

function getadjustments(securities::Vector{Security},
                        startdate::DateTime, 
                        enddate::DateTime, 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")

    secids = Vector{Int}(length(securities))
    for i = 1:length(securities)
        secids[i] = securities[i].symbol.id
    end

    getadjustments(secids, datatype, frequency,
            startdate, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country)    
end

function getadjustments(symbols::Vector{SecuritySymbol},
                        startdate::DateTime, 
                        enddate::DateTime, 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")

    secids = Vector{Int}(length(symbols))
    
    for i = 1:length(symbols)
        secids[i] = symbols[i].id
    end

    getadjustments(secids, datatype, frequency,
            startdate, enddate, 
            securitytype = securitytype, 
            exchange = exchange, country = country)    
end



#=function getsecurityids(tickers::Array{String,1}; 
                        securitytype::String="EQ", 
                        exchange::String="NSE",
                        country::String="IN")
    
    getsecurityids(securitycollection, tickers, 
                        securitytype = securitytype,
                        exchange = exchange,
                        country = country)

end

"""
Get security id for a symbol id (and exchange and security type)
"""
function getsecurityid(ticker::String; 
                        securitytype::String="EQ", 
                        exchange::String="NSE",
                        country::String="IN")

    getsecurityid(securitycollection, ticker,
                    securitytype = securitytype,
                    exchange = exchange,
                    country = country)
end

function getsymbol(id::Int)
    return getsymbol(securitycollection, id)
end=#
   
function convert(::Type{Raftaar.Security}, security::YRead.Security)
    
    return Raftaar.Security(security.symbol.id, security.symbol.ticker, security.name,
                      exchange = security.exchange,
                      country = security.exchange,
                      securitytype = security.securitytype)
end


function getsecurity(ticker::String; 
                        securitytype::String="EQ",
                        exchange::String="NSE",
                        country::String="IN")

    sec =  YRead.getsecurity(ticker, 
                        securitytype, 
                        exchange, 
                        country)
    convert(Raftaar.Security, sec)
end

# Overriding getindex for history dataframes
getindex(dataframe::DataFrame, security::Security) = getindex(dataframe, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, symbol::SecuritySymbol) = getindex(dataframe, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, ticker::String) = getindex(dataframe, Symbol(ticker))

getindex(dataframe::DataFrame, col_inds::Colon, security::Security) = getindex(dataframe, col_inds, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, col_inds::Colon, symbol::SecuritySymbol) = getindex(dataframe, col_inds, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, col_inds::Colon, ticker::String) = getindex(dataframe, col_inds, Symbol(ticker))

getindex(dataframe::DataFrame, col_ind::Int64, security::Security) = getindex(dataframe, col_ind, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, col_ind::Int64, symbol::SecuritySymbol) = getindex(dataframe, col_ind, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, col_ind::Int64, ticker::String) = getindex(dataframe, col_ind, Symbol(ticker))

getindex(dataframe::DataFrame, col_inds::UnitRange{Int64}, security::Security) = getindex(dataframe, col_ind, Symbol(security.symbol.ticker))
getindex(dataframe::DataFrame, col_inds::UnitRange{Int64}, symbol::SecuritySymbol) = getindex(dataframe, col_ind, Symbol(symbol.ticker))
getindex(dataframe::DataFrame, col_inds::UnitRange{Int64}, ticker::String) = getindex(dataframe, col_ind, Symbol(ticker))

#=function history(symbol::String,
                    datatype::String,
                    frequency::Symbol,
                    horizon::Int;
                    enddate::DateTime=DateTime(),                    
                    securitytype::String="EQ",
                    exchange::String="NSE",
                    country::String="IN")

 history(securitycollection, datacollection,
            symbol, datatype, frequency,
            horizon, enddate, securitytype = securitytype, exchange = exchange, country = country)  
end=#
