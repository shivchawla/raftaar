using YRead
import Mongo: MongoClient
using API

include("../Util/handleErrors.jl")
include("../Util/parseArgs.jl")
include("../Util/processArgs.jl")
include("../Util/Run_Algo.jl")

parsed_args = ""
fname = ""
try
    info("Parsing arguments from settings panel", datetime=now())    
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
info("Configuring datastore connections", datetime=now())    

YRead.configure(client)
YRead.configure(priority=2)
try
    info("Processing parsed arguments from settings panel", datetime = now())    
    fname = processargs(parsed_args)
catch err
    handleexception(err)
end

setlogmode(:console, true)
  
try
    info("Building user algorithm", datetime=now())
    
    include(fname)
    
    info("Starting Backtest", datetime=now())
    
    run_algo()

    info("Ending Backtest", datetime=now())
catch err
    handleexception(err)
end

