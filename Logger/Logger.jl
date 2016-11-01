# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

@enum MessageType INFO WARNING

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
function logg!(logger::Logger, datetime::DateTime, msg::String, msgtype::MessageType)
    push!(logger, Message(datetime, msg, msgtype))
    _log(datetime, msg, msgtype)
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

