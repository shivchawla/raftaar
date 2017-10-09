# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

__precompile__(true)
module Logger

import WebSockets: WebSocket
using LibBSON

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
                                "print" => :console,
                                "save" => false,
                                "limit" => 30,
                                "counter" => 0,
                                "display" => true)

"""
Function to configure mode of the logger and change the datetime
"""
function configure(;style_mode::Symbol = :text, print_mode::Symbol = :console, save_mode::Bool = true, save_limit::Int = 30, display::Bool=true)
    global params["style"] = style_mode
    global params["print"] = print_mode
    global params["save"] = save_mode
    global params["limit"] = save_limit
    global params["display"] = display

    if(save_mode)
        logbook.savelimit = save_limit
    end
end

function configure(client::WebSocket; style_mode::Symbol = :text, print_mode::Symbol = :socket, save_mode::Bool = true, save_limit::Int = 30, display::Bool=true)
    global params["style"] = style_mode
    global params["print"] = print_mode
    global params["save"] = save_mode
    global params["limit"] = save_limit
    if haskey(params, "client")
        global params = delete!(params, "client")
    end
    global params["client"] = client
    global params["display"] = display

    if(save_mode)
        logbook.savelimit = save_limit
    end
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
function info(msg::String, mmode::Symbol, pmode::Symbol; datetime::DateTime = now())
    _log(msg, MessageType(INFO), pmode, mmode, datetime)
end

function warn(msg::String, mmode::Symbol, pmode::Symbol; datetime::DateTime = now())
    _log(msg, MessageType(WARN), pmode, mmode, datetime)
end

function error(msg::String, mmode::Symbol, pmode::Symbol; datetime::DateTime = now())
    _log(msg, MessageType(ERROR), pmode, mmode, datetime)
end

function info_static(msg::String)
    mmode = params["style"]
    pmode = params["print"]
    _log(msg, MessageType(INFO), pmode, mmode, DateTime())
end

function error_static(msg::String)
    mmode = params["style"]
    pmode = params["print"]
    _log(msg, MessageType(ERROR), pmode, mmode, DateTime())
end

function warn_static(msg::String)
    mmode = params["style"]
    pmode = params["print"]
    _log(msg, MessageType(WARN), pmode, mmode, DateTime())
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
    _log(msg, MessageType(ERROR), pmode, mmode, DateTime())
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
    
    if !get(params, "display", true)
        return
    end

    #mode = params["mode"]
    if haskey(params, "datetime") && datetime!=DateTime()
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
    datestr = ""
    if (datetime != DateTime())
         datestr = string(datetime)*":"
    end

    if pmode == :console
        if msgtype == MessageType(INFO)
            print_with_color(:green,  "[INFO]" * "$(datestr)" * msg * "\n")
        elseif msgtype == MessageType(WARN)
            print_with_color(:orange, "[WARNING]" * "$(datestr)" * msg * "\n")
        else 
            print_with_color(:red, "[ERROR]" * "$(datestr)" * msg * "\n")
        end
    else pmode == :socket
        if msgtype == MessageType(INFO)
            fmsg = "[INFO]"* "$(datestr)" * msg
        elseif msgtype == MessageType(WARN)
            fmsg = "[WARNING]" * "$(datestr)" * msg
        else
            fmsg = "[ERROR]" * "$(datestr)" * msg
        end

        write(params["client"], fmsg)
    end

end

todbformat(datetime::DateTime) = Dates.format(datetime, "yyyy-mm-dd HH:MM:SS")

"""
Function to log message AS JSON (with timestamp) based on message type
"""
function _logJSON(msg::String, msgtype::MessageType, pmode::Symbol, datetime::DateTime)
  
    limit = params["limit"]
    msg_dict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(msgtype),
                                        "message" => msg)

    if(datetime != DateTime()) 
        datetimestr = todbformat(datetime)
        msg_dict["datetime"] = datetimestr  
    end

    jsonmsg = JSON.json(msg_dict)

    entry_datetime = todbformat(now())
    if !haskey(logbook.container, entry_datetime)
        logbook.container[entry_datetime] = Dict{String, Vector{String}}()
    end
    
    datekey = string(Date(datetime))
    if !haskey(logbook.container[entry_datetime], datekey)
        logbook.container[entry_datetime][datekey] = Vector{String}()
    end
        
    numlogs = haskey(logcounter, datekey) ? logcounter[datekey] : 0

    if (numlogs < limit && numlogs < 50) || msgtype == MessageType(ERROR)

        pmode == :console ? println(jsonmsg) : (haskey(params, "client") ? write(params["client"], jsonmsg) : println("Socket Client is missing\n$(jsonmsg)"))

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
    global logbook.container = Dict{String, Vector{String}}()
    global logcounter = Dict{String, Int}()
end

function getlogbook()
    return logbook.container
end

export info_static, error_static, warn_static

end
