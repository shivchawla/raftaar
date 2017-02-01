using YRead
import Mongo: MongoClient
using API

include("../Util/handleErrors.jl")
include("../Util/parseArgs.jl")
include("../Util/processArgs.jl")
include("../Util/Run_Algo.jl")

parsed_args = ""
try
    parsed_args = parse_commandline()
catch err
    handleexception(err)
end
  

#Check for parsed arguments
if (parsed_args["code"] == nothing && parsed_args["file"] == nothing)
  println("Atleast one of the code or file arguments should be provided")
  exit(0)
end

using JSON
connection = JSON.parsefile("../../raftaar/Util/connection.json")

const client = MongoClient(connection["mongo_host"], connection["mongo_port"], connection["mongo_user"], connection["mongo_pass"])
YRead.configure(client)
YRead.configure(priority=2)

fname = ""
try
    fname = processargs(parsed_args)
catch err
    handleexception(err)
end

setlogmode(:json, true)
  
try
    include(fname)
    run_algo()
catch err
    handleexception(err)
end

