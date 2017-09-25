using API
using WebSockets
using HttpServer
using Logger

include("parseArgs.jl")
include("processArgs.jl")
include("handleErrors.jl")
include("dbConnections.jl")

port = 2000
host = "127.0.0.1"

try
  port = parse(ARGS[1])
  host = ARGS[2]
end

#global Dict to store open connections in
global connections = Dict{Int,WebSocket}()

function decodeMessage(msg)
    String(copy(msg))
end

global fname = ""
global parsed_args = Dict{String, Any}()

wsh = WebSocketHandler() do req, client
    
    connections[client.id] = client

    setlogmode(:json, :socket, true, client)

    msg = read(client)
    argsString = decodeMessage(msg)
    args = [String(ss) for ss in split(argsString,"??##")]

    info_static("Starting Backtest")

    # Parse arguments from the connection message.
    info_static("Parsing arguments from settings panel")
    global parsed_args = parse_arguments(args)

    parseError = false
    info_static("Processing parsed arguments from settings panel")

    try
        global fname = processargs(parsed_args)
    catch err
        info_static("Error parsing arguments from settings panel")
        handleexception(err)
        
        if !parsed_args["forward"] 
            #_outputbackteststatistics()
            _outputbacktestlogs()
        end

        close(client)
        return
    end
        
    info_static("Checking user algorithm for errors")
    try
        include(fname)
    catch err
        handleexception(err)
        if !parsed_args["forward"] 
            #_outputbackteststatistics()
            _outputbacktestlogs()
        end
        close(client)
        return
    end

    #create a temporary file to copy all the relevant code required
    #to run the backtest
    tf = tempname()

    #copy the boilerplate code
    #includes relevant modules and create db connections
    cp(Base.source_dir()*"/boilerPlate.jl", tf)

    #Append user source code to the fle
    open(tf, "a") do f
        open(fname, "r") do ff
            source_code = readlines(ff)
            for l in source_code
                write(f, "\n$l")
            end                
        end
        
        #Append the actual backtesting function
        if parsed_args["forward"] 
            write(f, "\nrun_algo(true)")
        else
            write(f, "\nrun_algo(false)")
        end
        write(f, "\nAPI.reset()")
    end

    nf = Base.source_dir()*"/temp/temp_run_$(now()).jl"
    cp(tf, nf, remove_destination=true)
    
    #Run the complete file
    try
        evalfile(nf)
    catch err
        if !parsed_args["forward"] 
            _outputbacktestlogs()
            #_outputbackteststatistics() ERROR
        end
        
        println(err)
    end

    #remove the tempfile after completion
    rm(nf)

    #close the ws client on successful completion
    close(client)

end

server = Server(wsh)
run(server, host=IPv4(host), port=port)

