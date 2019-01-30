using API
using HistoryAPI
using UtilityAPI
using OptimizeAPI
using BackTester
using YRead

using Logger
using Mongoc
using JSON

include("./dbConnections.jl")
include("./parseArgs.jl")
include("./processArgs.jl")
include("./handleErrors.jl")

global parsed_args = Dict{String, Any}()

function evaluate_strategy(args)
    try 
        Logger.configure(style=:json, modes=[:redis])
        global parsed_args = parse_arguments(args)
        backtestid = haskey(parsed_args, "backtestid") ? parsed_args["backtestid"] : ""
        Logger.setbacktestid(backtestid)

        info_static("Starting Backtest")
        info_static("Processing parsed arguments from settings panel")
        
    catch err
        println(err)
        error_static("Internal Error while processing settings")
        return 0
    end
    
    try
        processargs(parsed_args)
    catch err
        println(err)
        error_static("Error parsing arguments from settings panel")
        handleexception(err, parsed_args["forward"])
        API.reset()
        return 0
    end

    #Run the complete file
    try
        eval(parse("""include("$(source_dir)/boilerPlate.jl")"""))
        
        info_static("Checking user algorithm for errors")
        if (parsed_args["code"] == nothing)
            eval(parse("""include(parsed_args["file"])"""))
        elseif (parsed_args["file"] == nothing)
            eval(parse("""include_string(parsed_args["code"])"""))
        end
        
        st = "run_algo(false)"
        if parsed_args["forward"] 
            st = "run_algo(true)"
        end
        
        eval(parse(st))
        
    catch err
        println(err)
        handleexception(err, parsed_args["forward"])
    end

    # Finally reset the API if completed successfully
    API.reset()
    return 0
end