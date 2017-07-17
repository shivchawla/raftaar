using YRead
import Mongo: MongoClient
using JSON
using API

include("../Util/handleErrors.jl")
include("../Util/parseArgs.jl")
include("../Util/processArgs.jl")
include("../Util/Run_Algo.jl")

setlogmode(:json, :console, true)

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

connection = JSON.parsefile(Base.source_dir()*"/connection.json")

const client = MongoClient()

info("Configuring datastore connections", datetime=now())

YRead.configure(client, database = "aimsquant")
YRead.configure(priority = 2)
try
    info("Processing parsed arguments from settings panel", datetime = now())
    fname = processargs(parsed_args)
catch err
    handleexception(err)
end

#fname = "/users/shivkumarchawla/raftaar/Examples/momentumStrategy.jl"

try
    info("Building user algorithm", datetime=now())

    include(fname)

    info("Starting Backtest", datetime=now())

    run_algo(parsed_args["forward"])

    info("Ending Backtest", datetime=now())
catch err
    handleexception(err)
end
