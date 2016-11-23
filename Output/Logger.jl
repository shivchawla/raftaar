# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

__precompile__()

module Logger

@enum MessageType INFO WARN ERROR

import Base: info, error
import Base.error
using JSON

const mode = :json
datetime = now()

"""
Function to configure mode of the logger and change the datetime
"""
function configure(;print_mode::Symbol = :json, algo_clock::DateTime = now())
    global mode = print_mode
    global datetime = algo_clock
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
    if mode == :console
        _logstandard(msg, msgtype)
    elseif mode == :json
        _logJSON(msg, msgtype)
    end
end


"""
Function to log message (with timestamp) based on message type
"""
function _logstandard(msg::String, msgtype::MessageType) 
    if msgtype == MessageType(INFO)     
        print_with_color(:green,  "$(string(datetime))"* "INFO:"*" "*msg*"\n")
    elseif msgtype == MessageType(WARN)
        print_with_color(:orange, "WARNING:" * "$(string(datetime))" *" "*msg*"\n")
    else
        print_with_color(:red, "ERROR:" * "$(string(datetime))" *" "*msg*"\n")
        exit(0)
    end
end 

"""
Function to log message AS JSON (with timestamp) based on message type
"""
function _logJSON(msg::String, msgtype::MessageType) 
    messagedict = Dict{String, String}("outputtype" => "log",
                                        "messagetype" => string(msgtype),
                                        "datetime" => string(datetime), 
                                        "message" => msg)

    JSON.print(messagedict)
    println()

end 

end
