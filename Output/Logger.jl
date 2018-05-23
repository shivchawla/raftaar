# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

__precompile__(true)
module Logger

import WebSockets: WebSocket
import Base: run
using LibBSON
using Mongo
#using Redis

type LogBook
    mode::Symbol
    ## Key needs to be string as db can't handle fields with dots
    container::Dict{String, Dict{String, Vector{String}}}
    savelimit::Int
end

LogBook() = LogBook(:json, Dict{String, Vector{String}}(), 20)

const logcounter = Dict{String, Int}()

@enum MessageType INFO WARN ERROR

#import Base: info, error
using JSON

const logbook = LogBook()
const params = Dict{String, Any}("style" => :text,
                                "modes" => [:console],
                                "save" => false,
                                "limit" => 30,
                                "counter" => 0,
                                "display" => true,
                                "backtestId" => "")

"""
Function to configure mode of the logger and change the datetime
"""
function configure(;style::Symbol = :text, mode::Symbol = :console, save::Bool = true, limit::Int = 30, display::Bool=true)
    global params["style"] = style
    global params["modes"] = [mode]
    global params["save"] = save
    global params["limit"] = limit
    global params["display"] = display

    if(save)
        logbook.savelimit = limit
    end
end

function configure(;style::Symbol = :text, modes::Vector{Symbol}=[:console], save::Bool = true, limit::Int = 30, display::Bool=true)
    global params["style"] = style
    global params["modes"] = modes
    global params["save"] = save
    global params["limit"] = limit
    
    global params["display"] = display

    if(save)
        logbook.savelimit = limit
    end
end

function setwebsocketclient(ws_client::WebSocket)
    if haskey(params, "ws_client")
        global params = delete!(params, "ws_client")
    end
    global params["ws_client"] = ws_client
end

function setmongoclient(coll::MongoCollection)
    if haskey(params, "mongo_collection")
        global params = delete!(params, "mongo_collection")
    end
    global params["mongo_collection"] = coll
end

function setredisclient(redis_host::String="127.0.0.1", redis_port::Int=6379, redis_pass::String="")
    if haskey(params, "redis_host")
        global params = delete!(params, "redis_host")
    end
    global params["redis_host"] = redis_host

    if haskey(params, "redis_port")
        global params = delete!(params, "redis_port")
    end
    global params["redis_port"] = redis_port

    if haskey(params, "redis_pass")
        global params = delete!(params, "redis_pass")
    end
    
    global params["redis_pass"] = redis_pass    

end

function setbacktestid(backtestId::String)
    global params["backtestId"] = backtestId
end

function update_display(display::Bool)
    global params["display"] = display
end

function updateclock(algo_clock::DateTime)
    global params["datetime"] = algo_clock
    global params["counter"] = 0
end

"""
Function to record and print log messages
"""
function info(msg::Any, style::Symbol, mode::Symbol; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(INFO), [mode], style, datetime)
end

function warn(msg::Any, style::Symbol, mode::Symbol; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(WARN), [mode], style, datetime)
end

function error(msg::Any, style::Symbol, mode::Symbol; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(ERROR), [mode], style, datetime)
end

function info_static(msg::Any)
    _log(msg, MessageType(INFO), params["modes"], params["style"], DateTime())
end

function error_static(msg::Any)
    _log(msg, MessageType(ERROR), params["modes"], params["style"], DateTime())
end

function warn_static(msg::Any)
    _log(msg, MessageType(WARN), params["modes"], params["style"], DateTime())
end

function info(msg::Any; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(INFO), params["modes"], params["style"], datetime)
end

function warn(msg::Any; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(WARN), params["modes"], params["style"], datetime)
end

function error(msg::Any; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(ERROR), params["modes"], params["style"], DateTime())
end

function info(msg::Any, style::Symbol; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(INFO), params["modes"], style, datetime)
end

function warn(msg::Any, style::Symbol; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(WARN), params["modes"], style, datetime)
end

function error(msg::Any, style::Symbol; datetime::DateTime = unix2datetime(time()))
    _log(msg, MessageType(ERROR), params["modes"], style, datetime)
end

function _log(msg::Any, msgtype::MessageType, modes::Vector{Symbol}, style::Symbol, datetime::DateTime)
    
    if !get(params, "display", true)
        return
    end

    if haskey(params, "datetime") && datetime!=DateTime()
        datetime = params["datetime"]
    end

    msg = string(msg)
    msg = replace(msg, "Raftaar.", "")

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
    if (datetime != DateTime())
         datestr = string(datetime)*":"
    end

    dt = Dates.format(unix2datetime(time()), "Y-mm-dd HH:MM:SS.sss")
    if (:console in modes)
        if msgtype == MessageType(INFO)
            print_with_color(:green,  "[INFO][$(dt)]" * "$(datestr)" * msg * "\n")
        elseif msgtype == MessageType(WARN)
            print_with_color(:orange, "[WARNING][$(dt)]" * "$(datestr)" * msg * "\n")
        else 
            print_with_color(:red, "[ERROR][$(dt)]" * "$(datestr)" * msg * "\n")
        end
    end
    
    if (:socket in modes)
        if msgtype == MessageType(INFO)
            fmsg = "[INFO][$(unix2datetime(time()))]"* "$(datestr)" * msg
        elseif msgtype == MessageType(WARN)
            fmsg = "[WARNING][$(dt)]" * "$(datestr)" * msg
        else
            fmsg = "[ERROR][$(dt)]" * "$(datestr)" * msg
        end

        write(params["client"], fmsg)
    end

    if (:db in modes)

    end


end

todbformat(datetime::DateTime) = Dates.format(datetime, "yyyy-mm-dd HH:MM:SS")

"""
Function to log message AS JSON (with timestamp) based on message type
"""
function _logJSON(msg::String, msgtype::MessageType, modes::Vector{Symbol}, datetime::DateTime)
    
    limit = params["limit"]
    msg_dict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(msgtype),
                                        "message" => msg,
                                        "dt" => Dates.format(unix2datetime(time()), "Y-mm-dd HH:MM:SS.sss"),
                                        "backtestId" => params["backtestId"])

    if(datetime != DateTime()) 
        datetimestr = todbformat(datetime)
        msg_dict["datetime"] = datetimestr  
    end

    jsonmsg = JSON.json(msg_dict)

    entry_datetime = todbformat(unix2datetime(time()))
    if !haskey(logbook.container, entry_datetime)
        logbook.container[entry_datetime] = Dict{String, Vector{String}}()
    end
    
    datekey = string(Date(datetime))
    if !haskey(logbook.container[entry_datetime], datekey)
        logbook.container[entry_datetime][datekey] = Vector{String}()
    end
        
    numlogs = haskey(logcounter, datekey) ? logcounter[datekey] : 0

    if (numlogs < limit && numlogs < 50) || msgtype == MessageType(ERROR)

        if (:console in modes)
            println(jsonmsg)
        end

        if (:redis in modes)
            backtestId = params["backtestId"]
            Base.run(pushQueueCmd("backtest-realtime-$(backtestId)", jsonmsg))

            #Special addition to detect julia exception 
            if string(msgtype) == "ERROR"
                try
                    Base.run(publishCmd("backtest-realtime-$(backtestId)", jsonmsg))
                catch err
                    println(err)
                    println("Error Running Redis command")
                    error_static("Internal Error") 
                end
            end
        end

        if (:socket in modes)
            haskey(params, "ws_client") ? 
                    write(params["ws_client"], jsonmsg) : 
                    println("Socket Client is missing")
        end

        if (:db in modes)
            haskey(params, "mongo_collection") ? 
                    insert(params["mongo_collection"], msg_dict) : 
                    println("Mongo collection is missing")
        end

        push!(logbook.container[entry_datetime][datekey], jsonmsg)
        
        numlogs += 1
        logcounter[datekey] = numlogs

        if numlogs == limit || numlogs == 50
            msg_dict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(WARN),
                                        "message" => "Log limit reached!!")

            if(datetime != DateTime())
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
    
    backtestId = params["backtestId"]
    data = JSON.parse(str)
    data["backtestId"] = backtestId
    str = JSON.json(data)
   
    modes = [:console]

    if haskey(params, "modes")
        modes = params["modes"]
    end

    if (:console in modes)
        println(str)
    end

    if(:redis in modes)
        
        channel = realtime ? "backtest-realtime-$(backtestId)" : "backtest-final-$(backtestId)"
        if realtime
            Base.run(pushQueueCmd(channel, str))
        else

            chunksize = 10000
            #break down the string into multiple parts
            idx = 0;

            #Using "endof" string and NOT "length" length <= endof. 
            # Read Julia documentation on strings 
            for i=1:chunksize:endof(str)
                chunk = str[i:min(endof(str), i+chunksize-1)]
                Base.run(pushQueueCmd(channel, JSON.json(Dict{String, Any}("data"=>chunk, "index"=>idx))))
                idx+=1
            end

            try
                Base.run(publishCmd(channel, "backtest-final-output-ready"))
            catch err
                println(err)
                println("Error Running Redis command") 
                error_static("Internal Error")
            end
        end           
    end

    if (:socket in modes)
        haskey(params, "ws_client") ? 
            write(params["ws_client"], str) : 
            println("Socket Client is missing")
    end

    if (:db in modes)
        haskey(params, "mongo_collection") ? 
            insert(params["mongo_collection"], JSON.parse(str)) : 
            println("Mongo Client is missing")
    end
end

function resetLog()
    global logbook.container = Dict{String, Vector{String}}()
    for key in keys(logcounter)
        global logcounter[key] = 0
    end
end

function getlogbook()
    return logbook.container
end

export info_static, error_static, warn_static

end
