# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

@enum MessageType INFO WARNING

import Base: log
using JSON

"""
Message contents
"""
type Message 
    datetime::DateTime
    message::String 
    messagetype::MessageType
end

typealias Logger Vector{Message}

"""
Function to record and print log messages
"""
function log!(logger::Logger, datetime::DateTime, msg::String, msgtype::MessageType)
    push!(logger, Message(datetime, msg, msgtype))
    _log(datetime, msg, msgtype)
end


"""
Function to record and print log messages as JSON
"""
function logJSON!(logger::Logger, datetime::DateTime, msg::String, msgtype::MessageType)
    push!(logger, Message(datetime, msg, msgtype))
    _logJSON(datetime, msg, msgtype)
end

"""
Function to log message (with timestamp) based on message type
"""
function _log(datetime::DateTime, msg::String, msgtype::MessageType) 
    if msgtype == MessageType(INFO)
        print(datetime)
        info(msg)
    elseif msgtype == MessageType(WARNING)
        print(datetime)
        warn(msg)
    end
end 

"""
Function to log message AS JSON (with timestamp) based on message type
"""
function _logJSON(datetime::DateTime, msg::String, msgtype::MessageType) 
    
    messagedict = Dict{String, String}("outputtype" => "log",
                                        "datetime" => string(datetime), 
                                        "message" => msg)
    if msgtype == MessageType(INFO)
        messagedict["msgtype"] = "INFO"
        
    elseif msgtype == MessageType(WARNING)
        messagedict["msgtype"] = "WARNING"
    end
    
    JSON.print(messagedict)

end 


