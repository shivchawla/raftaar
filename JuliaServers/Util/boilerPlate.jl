using API
using HistoryAPI

using YRead
using TimeSeries
using Logger
using BackTester
using Dates

fname_full = @__FILE__
dir = Base.source_dir()

#find fname_full in dir
idx_arr = something(findfirst(dir, fname_full), 0:-1)
fname = length(idx_arr) != 0 ? fname_full[(idx_arr[end] + 2):end] : fname_full

#wrt the temp folder
const PATH = Base.source_dir()

include(PATH*"/Util/handleErrors.jl")
include(PATH*"/Util/Run_Algo.jl")

#Reset the initialize/ondata
include(PATH*"/Util/reset.jl")

