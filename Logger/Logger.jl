# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

__precompile__(true)
module Logger

import Base: run
using Mongoc
using Dates
using JSON
import Redis

mutable struct  LogBook
    mode::Symbol
    ## Key needs to be string as db can't handle fields with dots
    container::Dict{String, Dict{String, Vector{String}}}
    savelimit::Int
    params::Dict{String, Any} 
    logcounter::Dict{String, Int}
end

LogBook() = LogBook(
                :json, 
                Dict{String, Vector{String}}(), 
                20, 
                Dict{String, Any}(
                    "style" => :text,
                    "modes" => [:console],
                    "save" => false,
                    "limit" => 30,
                    "counter" => 0,
                    "display" => true,
                    "backtestId" => ""),
                Dict{String, Int}()
            )

@enum MessageType INFO WARN ERROR

logbook = LogBook()

"""
Function to configure mode of the logger and change the datetime
"""
function configure(;style::Symbol = :text, modes::Vector{Symbol}=[:console], save::Bool = true, limit::Int = 30, display::Bool=true)
    logbook.params["style"] = style
    logbook.params["modes"] = modes
    logbook.params["save"] = save
    logbook.params["limit"] = limit
    
    logbook.params["display"] = display

    if(save)
        logbook.savelimit = limit
    end
end

function setredisclient(redis_client::Redis.RedisConnection)
    if haskey(logbook.params, "redis_client")
        global logbook.params = delete!(logbook.params, "redis_client")
    end
    global logbook.params["redis_client"] = redis_client 
end

function setbacktestid(backtestId::String)
    logbook.params["backtestId"] = backtestId
end

function update_display(display::Bool)
    logbook.params["display"] = display
end

function updateclock(algo_clock::DateTime)
    logbook.params["datetime"] = algo_clock
    logbook.params["counter"] = 0
end

"""
Function to record and print log messages
"""
function info(msg::Any, style::Symbol, mode::Symbol; datetime::DateTime = now(Dates.UTC))
    _log(msg, INFO, [mode], style, datetime)
end

function warn(msg::Any, style::Symbol, mode::Symbol; datetime::DateTime = now(Dates.UTC))
    _log(msg, WARN, [mode], style, datetime)
end

function error(msg::Any, style::Symbol, mode::Symbol; datetime::DateTime = now(Dates.UTC))
    _log(msg, ERROR, [mode], style, datetime)
end

function info_static(msg::Any)
    _log(msg, INFO, logbook.params["modes"], logbook.params["style"], DateTime(1))
end

function error_static(msg::Any)
    _log(msg, ERROR, logbook.params["modes"], logbook.params["style"], DateTime(1))
end

function warn_static(msg::Any)
    _log(msg, WARN, logbook.params["modes"], logbook.params["style"], DateTime(1))
end

function info(msg::Any; datetime::DateTime = now(Dates.UTC))
    _log(msg, INFO, logbook.params["modes"], logbook.params["style"], datetime)
end

function warn(msg::Any; datetime::DateTime = now(Dates.UTC))
    _log(msg, WARN, logbook.params["modes"], logbook.params["style"], datetime)
end

function error(msg::Any; datetime::DateTime = now(Dates.UTC))
    _log(msg, ERROR, logbook.params["modes"], logbook.params["style"], DateTime(1))
end

function info(msg::Any, style::Symbol; datetime::DateTime = now(Dates.UTC))
    _log(msg, INFO, logbook.params["modes"], style, datetime)
end

function warn(msg::Any, style::Symbol; datetime::DateTime = now(Dates.UTC))
    _log(msg, WARN, logbook.params["modes"], style, datetime)
end

function error(msg::Any, style::Symbol; datetime::DateTime = now(Dates.UTC))
    _log(msg, ERROR, logbook.params["modes"], style, datetime)
end

function _log(msg::Any, msgtype::MessageType, modes::Vector{Symbol}, style::Symbol, datetime::DateTime)
    
    if !get(logbook.params, "display", true)
        return
    end

    if haskey(logbook.params, "datetime") && datetime!=DateTime(1)
        datetime = logbook.params["datetime"]
    end

    msg = string(msg)
    msg = replace(msg, "Raftaar." => "")

    maxlength = min(300, length(msg))
    
    if length(msg) > maxlength
        msg = "$(msg[1:maxlength])...TRUNCATED!!"
    end
       
    if style == :text
        _logstandard(msg, msgtype, modes, datetime)
    elseif style == :json
        _logJSON(msg, msgtype, modes, datetime)
    end
end

"""
Function to log message (with timestamp) based on message type
"""
function _logstandard(msg::String, msgtype::MessageType, modes::Vector{Symbol}, datetime::DateTime)
    datestr = ""
    if (datetime != DateTime(1))
         datestr = string(datetime)*":"
    end

    dt = Dates.format(now(Dates.UTC), "Y-mm-dd HH:MM:SS.sss")
    if (:console in modes)
        if msgtype == INFO
            printstyled("[INFO][$(dt)]" * "$(datestr)" * msg * "\n", color=:green)
        elseif msgtype == WARN
            printstyled("[WARNING][$(dt)]" * "$(datestr)" * msg * "\n", color=:orange)
        else 
            printstyled("[ERROR][$(dt)]" * "$(datestr)" * msg * "\n", color=:red)
        end
    end
    
    if (:socket in modes)
        if msgtype == INFO
            fmsg = "[INFO][$(now(Dates.UTC))]"* "$(datestr)" * msg
        elseif msgtype == WARN
            fmsg = "[WARNING][$(dt)]" * "$(datestr)" * msg
        else
            fmsg = "[ERROR][$(dt)]" * "$(datestr)" * msg
        end

        write(logbook.params["client"], fmsg)
    end

    if (:db in modes)

    end
end

todbformat(datetime::DateTime) = Dates.format(datetime, "yyyy-mm-dd HH:MM:SS")

"""
Function to log message AS JSON (with timestamp) based on message type
"""
function _logJSON(msg::String, msgtype::MessageType, modes::Vector{Symbol}, datetime::DateTime)
    
    limit = logbook.params["limit"]
    msg_dict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(msgtype),
                                        "message" => msg,
                                        "dt" => string(now(Dates.UTC)),
                                        "backtestId" => logbook.params["backtestId"])

    if(datetime != DateTime(1)) 
        datetimestr = todbformat(datetime)
        msg_dict["datetime"] = datetimestr  
    end

    jsonmsg = JSON.json(msg_dict)

    entry_datetime = todbformat(now(Dates.UTC))
    if !haskey(logbook.container, entry_datetime)
        logbook.container[entry_datetime] = Dict{String, Vector{String}}()
    end
    
    datekey = string(Date(datetime))
    if !haskey(logbook.container[entry_datetime], datekey)
        logbook.container[entry_datetime][datekey] = Vector{String}()
    end
        
    numlogs = haskey(logbook.logcounter, datekey) ? logbook.logcounter[datekey] : 0

    if (numlogs < limit && numlogs < 50) || msgtype == ERROR

        if (:console in modes)
            println(jsonmsg)
        end

        if (:redis in modes)
            backtestId = logbook.params["backtestId"]
            #Base.run(pipeline(pushQueueCmd("backtest-realtime-$(backtestId)", jsonmsg), devnull))
            Redis.rpush(logbook.params["redis_client"], "backtest-realtime-$(backtestId)", jsonmsg)

            #Special addition to detect julia exception 
            if string(msgtype) == "ERROR"
                try
                    #Base.run(pipeline(publishCmd("backtest-realtime-$(backtestId)", jsonmsg), devnull))
                    Redis.publish(logbook.params["redis_client"], "backtest-realtime-$(backtestId)", jsonmsg)
                catch err
                    println(err)
                    println("Error Running Redis command")
                    error_static("Internal Error") 
                end
            end
        end

        if (:socket in modes)
            haskey(logbook.params, "ws_client") ? 
                    write(logbook.params["ws_client"], jsonmsg) : 
                    println("Socket Client is missing")
        end

        if (:db in modes)
            haskey(logbook.params, "mongo_collection") ? 
                    insert(logbook.params["mongo_collection"], msg_dict) : 
                    println("Mongo collection is missing")
        end

        push!(logbook.container[entry_datetime][datekey], jsonmsg)
        
        numlogs += 1
        logbook.logcounter[datekey] = numlogs

        if numlogs == limit || numlogs == 50
            msg_dict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(WARN),
                                        "message" => "Log limit reached!!")

            if(datetime != DateTime(1))
                msg_dict["datetime"] = datetimestr
            end

            json_msg = JSON.json(msg_dict)

            push!(logbook.container[entry_datetime][datekey], jsonmsg)

            #mode == :console ? println(jsonmsg) : (haskey(params, "client") ? write(params["client"], jsonmsg) : println("Socket Client is missing\n$(jsonmsg)"))
        end
    end
end

function pushQueueCmd(key, str) 
    `redis-cli -p 13472 RPUSH "$key" "$str"`
end

function publishCmd(channel, str) 
    `redis-cli -p 13472 PUBLISH "$channel" "$str"`
end

function print(str; realtime=true)
    
    backtestId = logbook.params["backtestId"]
    data = JSON.parse(str)
    data["backtestId"] = backtestId
    str = JSON.json(data)
   
    modes = [:console]

    if haskey(logbook.params, "modes")
        modes = logbook.params["modes"]
    end

    if (:console in modes)
        println(str)
    end

    if(:redis in modes)
        
        channel = realtime ? "backtest-realtime-$(backtestId)" : "backtest-final-$(backtestId)"
        if realtime
            #Base.run(pipeline(pushQueueCmd(channel, str), devnull))
            Redis.rpush(logbook.params["redis_client"], channel, str)
        else

            chunksize = 10000
            #break down the string into multiple parts
            idx = 0;

            #Using "endof" string and NOT "length" length <= endof. 
            # Read Julia documentation on strings 
            for i=1:chunksize:endof(str)
                chunk = str[i:min(endof(str), i+chunksize-1)]
                # Base.run(pipeline(pushQueueCmd(channel, JSON.json(Dict{String, Any}("data"=>chunk, "index"=>idx))), devnull))
                Redis.rpush(logbook.params["redis_client"], channel, JSON.json(Dict{String, Any}("data"=>chunk, "index"=>idx)))
                idx+=1
            end

            try
                #Base.run(pipeline(publishCmd(channel, "backtest-final-output-ready"), devnull))
                Redis.publish(logbook.params["redis_client"], channel, "backtest-final-output-ready")
            catch err
                println(err)
                println("Error Running Redis command") 
                error_static("Internal Error")
            end
        end           
    end

    if (:socket in modes)
        haskey(logbook.params, "ws_client") ? 
            write(logbook.params["ws_client"], str) : 
            println("Socket Client is missing")
    end

    if (:db in modes)
        haskey(logbook.params, "mongo_collection") ? 
            insert(logbook.params["mongo_collection"], JSON.parse(str)) : 
            println("Mongo Client is missing")
    end
end

function resetLog()
    logbook.container = Dict{String, Vector{String}}()
    for key in keys(logbook.logcounter)
        logbook.logcounter[key] = 0
    end
end

function getlogbook()
    return logbook.container
end

export info_static, error_static, warn_static

end
