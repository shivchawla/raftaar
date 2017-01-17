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

const client = MongoClient()
YRead.configure(client)

fname = processargs(parsed_args)

#fname = "/users/shivkumarchawla/Desktop/temp.jl"

setlogmode(:json, true)
  
try
    include(fname)
catch err
    handleexception(err)
end

run_algo()
