__precompile__(true)
module YRead

using Mongoc 
using Logger
using TimeSeries
using Dates

import Logger: info, warn
import TimeSeries: TimeArray
import Base: convert
import Redis

const dict = Dict{String, Any}()

function configureMongo(cl::Mongoc.Client; database::String = "dbYojak_dev", priority::Int = 1, strict::Bool = true)    
    global dict
    dict["client"] = cl
    dict["db"] = database
    dict["priority"] = priority
    dict["strict"] = strict
end

function configureRedis(cl::Redis.RedisConnection)    
    global dict
    dict["redis_client"] = cl
end

securitycollection() = dict["client"][dict["db"]]["security_test"]
datacollection() = dict["client"][dict["db"]]["data_test"]
minutedatacollection() = dict["client"][dict["db"]]["data_minute"]
redisClient() = dict["redis_client"]

const PRIORITY = 1
const STRICT = false

function setstrict(strict::Bool = true)
    dict["strict"] = strict
end

function getstrict()
    return haskey(dict, "strict") ? dict["strict"] : STRICT
end

function setpriority(;priority::Int = 1)
    dict["priority"] = priority
end

function getpriority()
    return haskey(dict, "priority") ? dict["priority"] : PRIORITY
end

function TimeArray(dates::Vector{Date}, values::Vector{Float64}, name::String)
    nrows = length(values)
    return TimeArray(dates, reshape(values,(1,nrows)), [Symbol(name)])
end

function __getcolnames(ta)
    ta != nothing ? colnames(ta) : Symbol[]
end

include("quandl.jl")
include("EODH.jl")
include("dbread.jl")
include("history.jl")
include("globalstores_redis.jl")
include("api.jl")

end

