using API
using HistoryAPI
using TechnicalAPI

using YRead
using TimeSeries
using Logger
using BackTester
using Dates
using Statistics

fname_full = @__FILE__
dir = Base.source_dir()

#find fname_full in dir
idx_arr = something(findfirst(dir, fname_full), 0:-1)

#fname is used downstream in handleErrors
fname = length(idx_arr) != 0 ? fname_full[(idx_arr[end] + 2):end] : fname_full

#wrt the temp folder
const PATH = Base.source_dir()

include(PATH*"/handleErrors.jl")
include(PATH*"/Run_Algo.jl")

#Reset the initialize/ondata
include(PATH*"/reset.jl")

