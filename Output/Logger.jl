# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

__precompile__()

module Logger


type LogBook
    mode::Symbol
    container::Dict{Date, Vector{String}}
    savelimit::Int
end

LogBook() = LogBook(:json, Dict{Date, Vector{String}}(), 200)

@enum MessageType INFO WARN ERROR

import Base: info, error
import Base.error
using JSON

const logbook = LogBook()
const params = Dict{String, Any}("mode" => :console, 
                                "save" => false,
                                "datetime" => "",
                                "limit" => 20,
                                "counter" => 0)
"""
Function to configure mode of the logger and change the datetime
"""
function configure(;print_mode::Symbol = :console, save_mode::Bool = false, save_limit::Int = 20)
    params["mode"] = print_mode
    params["save"] = save_mode
    params["limit"] = save_limit
    
    if(save_mode)
        logbook.savelimit = save_limit
    end
end

function updateclock(algo_clock::DateTime)
    params["datetime"] = algo_clock
    params["counter"] = 0
end

"""
Function to record and print log messages
"""
function info(msg::String)
    _log(msg, MessageType(INFO))
end

function warn(msg::String)
    _log(msg, MessageType(WARN))
end

function error(msg::String)
    _log(msg, MessageType(ERROR))
end


function _log(msg::String, msgtype::MessageType)
    mode = params["mode"]
    datetime = now()
    if (params["datetime"] != "")
        datetime = params["datetime"]
    end
       
    if mode == :console
        _logstandard(msg, msgtype, datetime)
    elseif mode == :json
        _logJSON(msg, msgtype, datetime)
    end
end


"""
Function to log message (with timestamp) based on message type
"""
function _logstandard(msg::String, msgtype::MessageType, datetime::DateTime) 
    if msgtype == MessageType(INFO)     
        print_with_color(:green,  "[INFO] "*"$(string(datetime)): "*msg*"\n")
    elseif msgtype == MessageType(WARN)
        print_with_color(:orange, "[WARNING] " * "$(string(datetime)): "*msg*"\n")
    else
        print_with_color(:red, "[ERROR] " * "$(string(datetime)): "*msg*"\n")
        exit(0)
    end
end 

"""
Function to log message AS JSON (with timestamp) based on message type
"""
function _logJSON(msg::String, msgtype::MessageType, datetime::DateTime) 
    
    date = Date(datetime)
    counter = params["counter"];
    if(counter < params["limit"] && params["limit"] != -1)
        messagedict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(msgtype),
                                        "datetime" => string(date), 
                                        "message" => msg)
        jsonmsg = JSON.json(messagedict);
        println(jsonmsg)

        if params["save"]
            
            if !haskey(logbook.container, date)
                logbook.container[date] = Vector{String}()
            end

            logs = logbook.container[date]
            nmessages = length(logs)
            if nmessages < logbook.savelimit
                push!(logs, jsonmsg);
            end
        end

        params["counter"] = counter + 1
    end

end 

function getlogbook()
    return logbook.container;
end

end
