# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

__precompile__()

module Logger

type LogBook
    mode::Symbol
    ## Key needs to be string as db can't handle fields with dots
    container::Dict{String, Vector{String}} 
    savelimit::Int
end

LogBook() = LogBook(:json, Dict{String, Vector{String}}(), 20)

@enum MessageType INFO WARN ERROR

import Base: info, error
import Base.error
using JSON

const logbook = LogBook()
const params = Dict{String, Any}("style" => :text,
                                "print" => :console, 
                                "save" => false,
                                "datetime" => DateTime(),
                                "limit" => 30,
                                "counter" => 0)
                                
"""
Function to configure mode of the logger and change the datetime
"""
function configure(;style_mode::Symbol = :text, print_mode::Symbol = :console, save_mode::Bool = false, save_limit::Int = 30, client = WebSocket(0,TCPSock()))
    params["style"] = style_mode
    params["print"] = print_mode
    params["save"] = save_mode
    params["limit"] = save_limit
    params["client"] = client
    
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
function info(msg::String, mmode::Symbol, pmode::Symbol; datetime::DateTime = DateTime())
    _log(msg, MessageType(INFO), pmode, mmode, datetime)
end

function warn(msg::String, mmode::Symbol, pmode::Symbol; datetime::DateTime = DateTime())
    _log(msg, MessageType(WARN), pmode, mmode, datetime)
end

function error(msg::String, mmode::Symbol, pmode::Symbol; datetime::DateTime = DateTime())
    _log(msg, MessageType(ERROR), pmode, mmode, datetime)
end

function info(msg::String; datetime::DateTime = now())
    mmode = params["style"]
    pmode = params["print"] 
    _log(msg, MessageType(INFO), pmode, mmode, datetime)
end

function warn(msg::String; datetime::DateTime = now())
    mmode = params["style"]
    pmode = params["print"]
    _log(msg, MessageType(WARN), pmode, mmode, datetime)
end

function error(msg::String; datetime::DateTime = now())
    mmode = params["style"]
    pmode = params["print"]
    _log(msg, MessageType(ERROR), pmode, mmode, datetime)
end

function info(msg::String, mmode::Symbol; datetime::DateTime = now())
    pmode = params["print"] 
    _log(msg, MessageType(INFO), pmode, mmode, datetime)
end

function warn(msg::String, mmode::Symbol; datetime::DateTime = now())
   pmode = params["print"]
    _log(msg, MessageType(WARN), pmode, mmode, datetime)
end

function error(msg::String, mmode::Symbol; datetime::DateTime = now())
    pmode = params["print"]
    _log(msg, MessageType(ERROR), pmode, mmode, datetime)
end

function _log(msg::String, msgtype::MessageType, pmode::Symbol, mmode::Symbol, datetime::DateTime)
    #mode = params["mode"]
    if datetime == DateTime() && params["datetime"] != ""
        datetime = params["datetime"]
    end
       
    if mmode == :text
        _logstandard(msg, msgtype, pmode, datetime)
    elseif mmode == :json
        _logJSON(msg, msgtype, pmode, datetime)
    end
end


"""
Function to log message (with timestamp) based on message type
"""
function _logstandard(msg::String, msgtype::MessageType, pmode::Symbol, datetime::DateTime) 
    
    if(pmode == :console)
        if msgtype == MessageType(INFO)     
            print_with_color(:green,  "[INFO] "*"$(string(datetime)): "*msg*"\n")
        elseif msgtype == MessageType(WARN)
            print_with_color(:orange, "[WARNING] " * "$(string(datetime)): "*msg*"\n")
        else
            print_with_color(:red, "[ERROR] " * "$(string(datetime)): "*msg*"\n")
        end
    else
        if msgtype == MessageType(INFO)     
            fmsg = "[INFO] "*"$(string(datetime)): "*msg
        elseif msgtype == MessageType(WARN)
            fmsg = "[WARNING] " * "$(string(datetime)): "*msg
        else
            fmsg = "[ERROR] " * "$(string(datetime)): "*msg
        end
        
        write(params["client"], fmsg)
    end

end 


todbformat(datetime::DateTime) = Dates.format(datetime, "yyyy-mm-dd HH:MM:SS")

"""
Function to log message AS JSON (with timestamp) based on message type
"""
function _logJSON(msg::String, msgtype::MessageType, pmode::Symbol, datetime::DateTime) 
    
    datetimestr = todbformat(datetime)
    limit = params["limit"]

    datestr = string(Date(datetime))

    messagedict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(msgtype),
                                        "datetime" => datetimestr,
                                        "message" => msg)
    
    jsonmsg = JSON.json(messagedict)

    if !haskey(logbook.container, datestr)
        logbook.container[datestr] = Vector{String}()
    end

    numlogs = length(logbook.container[datestr])
    if (numlogs < limit && numlogs < 50) || msgtype == MessageType(ERROR)
        
        pmode == :console ? println(jsonmsg) : (haskey(params, "client") ? write(params["client"], jsonmsg) : println("Socket Client is missing\n$(jsonmsg)"))

        push!(logbook.container[datestr], jsonmsg);
        numlogs = length(logbook.container[datestr])

        if numlogs == limit || numlogs == 50
            jsonmsg = JSON.json(Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(WARN),
                                        "datetime" => datetimestr,
                                        "message" => "Log limit reached!!"))

            pmode == :console ? println(jsonmsg) : (haskey(params, "client") ? write(params["client"], jsonmsg) : println("Socket Client is missing\n$(jsonmsg)"))
        end
        
    end

end 

function print(str)
    pmode = :console

    if haskey(params, "print")
        pmode = params["print"]
    end

    pmode == :console ? println(str) : (haskey(params, "client") ? write(params["client"], str) : println("Socket Client is missing\n$(str)"))

end

function resetLog()
    println("Resetting Logs")
    logbook.container = Dict{String, Vector{String}}()
    println(getlogbook())
end

function getlogbook()
    return logbook.container
end

end
