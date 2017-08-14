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
    info_static("Parsing arguments from settings panel")
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

info_static("Configuring datastore connections")

YRead.configure(client, database = "aimsquant")
YRead.configure(priority = 2)
try
    info_static("Processing parsed arguments from settings panel")
    fname = processargs(parsed_args)
catch err
    handleexception(err)
end

#fname = "/users/shivkumarchawla/raftaar/Examples/momentumStrategy.jl"

try
    info_static("Building user algorithm")

    include(fname)

    info_static("Starting Backtest")

    run_algo(parsed_args["forward"])

    info_static("Ending Backtest")
catch err
    handleexception(err)
end
