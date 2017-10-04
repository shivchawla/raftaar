using YRead
import Mongo: MongoClient
using API
using JSON

fname_full = @__FILE__

dir = Base.source_dir()

#find fname_full in dir
idx_arr = search(fname_full, dir)
fname = length(idx_arr) != 0 ? fname_full[(idx_arr[end] + 1):end] : fname_full

#wrt the temp folder
#const PATH = Base.source_dir()*"/.."
const PATH = Base.source_dir()

include(PATH*"/handleErrors.jl")
include(PATH*"/Run_Algo.jl")
