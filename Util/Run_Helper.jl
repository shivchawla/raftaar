
import Logger: warn, info, error
using Raftaar
#using StackTraces
import Base: isvalid, showerror

pattern = ""

include("../API/API.jl")
include("../Examples/constantpct.jl")
include("../Util/handleErrors.jl")
#include("../Util/parseArgs.jl")
#include("../Util/processArgs.jl")

