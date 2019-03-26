__precompile__(true)
module YWrite

using Mongoc 
using Logger
using HTTP
using JSON
using ZipFile
using Dates

import Logger: info, warn

const dict = Dict{String, Any}()

function configure(cl::Mongoc.Client; database::String = "dbYojak_dev")
    dict["client"] = cl
    dict["db"] = database
end

securitycollection() = dict["client"][dict["db"]]["security_test"]
datacollection() = dict["client"][dict["db"]]["data_test"]
minutedatacollection() = dict["client"][dict["db"]]["data_minute"]
fundamentaldatacollection() = dict["client"][dict["db"]]["data_fundamental"]

function deleteAll() 
    Mongoc.delete_many(securitycollection(), BSON(Dict("securityid"=>gt(0))))
    Mongoc.delete_many(datacollection(), BSON(Dict("securityid"=>gt(0))))       
end

include("quandl.jl")
include("EODH.jl")
include("dbread.jl")
include("dbwrite.jl")
include("dataio.jl")
include("USData.jl")
include("fundamental.jl")

end

