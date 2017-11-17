using API
using WebSockets
using HttpServer
using Logger
using Mongo
using JSON

port = 2000
host = "127.0.0.1"

SERVER_READY = false
SERVER_AVAILABLE = false

try
  port = parse(ARGS[1])
  host = ARGS[2]
end

#const dir = "/home/jp_$(port)/local"
const dir = "/Users/shivkumarchawla/local"

include("../Util/parseArgs.jl")
include("../Util/processArgs.jl")
include("handleErrors.jl")
include("../Util/dbConnections.jl")

#global Dict to store open connections in
global connections = Dict{Int, Bool}()

function decodeMessage(msg)
    println(msg)
    JSON.parse(String(copy(msg)))
end

global fname = ""
global tf = ""
global parsed_args = Dict{String, Any}()

function remove_files()
    try
        #remove the tempfile after completion
        rm(tf)
        rm(fname)
        rm("$dir/handleErrors.jl")
        rm("$dir/Run_Algo.jl")
        rm("$dir/*")
    end
end

function close_connection(client)
    
    println("Closing Connection: $client")
    global connections = delete!(connections, client.id)
    try
        close(client)
    catch
        println("Error Closing: $client")
        println("Ready to take messages")
    end
end

function isserveravailable()
    return length(collect(keys(connections))) == 0 && SERVER_READY
end

wsh = WebSocketHandler() do req, client

    connections[client.id] = true
    println(client)

    msg = ""
    try
        
        msg = decodeMessage(read(client))
        println(msg)

        requestType = haskey(msg, "requestType") ? msg["requestType"] : ""

        if requestType == "execute" 
            if isserveravailable()
                remove_files()
                #contiue procee
            else
                msg = Dict{String, Any}("msg" => "Server Unavailable", "code" => 503, "outputtype" => "internal");
                write(client, JSON.json(msg))
                close_connection(client)
            end 
        elseif requestType == "setready"
            println("Setting Server to be ready")
            global SERVER_READY = true
            close_connection(client)
            return
        else
            println("Request: $requestType not found")
            close_connection(client)
            return
        end

    catch err
        println("Error")
        println(err)
        close_connection(client)   
        return 
    end
    
    try 
        Logger.setwebsocketclient(client)
        Logger.configure(style=:json, modes=[:socket])

        argsString = msg["args"]
        args = [String(ss) for ss in split(argsString,"??##")]

        info_static("Starting Backtest")
        info_static("Processing parsed arguments from settings panel")
        global parsed_args = parse_arguments(args)

        backtestid = haskey(parsed_args, "backtestid") ? parsed_args["backtestid"] : ""
        Logger.setbacktestid(backtestid)

    catch err
        println(err)
        error_static("Internal Error while processing settings")
        close_connection(client)
        return
    end
    
    try
        global fname = processargs(parsed_args, dir)
    catch err
        println(err)
        error_static("Error parsing arguments from settings panel")
        handleexception(err, parsed_args["forward"])
        close_connection(client)
        API.reset()
        return
    end

    info_static("Checking user algorithm for errors")
    try
        include(fname)
    catch err
        handleexception(err, parsed_args["forward"])
        close_connection(client)
        API.reset()
        return
    end
   
    try
        #create a temporary file to copy all the relevant code required
        #to run the backtest
        (tf, io) = mktemp(dir)
        global tf = tf
        close(io)
        
        cp(Base.source_dir()*"/handleErrors.jl", "$dir/handleErrors.jl", remove_destination=true)
        cp(Base.source_dir()*"/Run_Algo.jl", "$dir/Run_Algo.jl", remove_destination=true)

        #copy the boilerplate code
        #includes relevant modules and create db connections
        cp(Base.source_dir()*"/boilerPlate.jl", tf, remove_destination=true)

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
        end
    catch err
        println(err)
        error_static("Internal Error")
        if !parsed_args["forward"]
            _outputbacktestlogs()
        end
        close_connection(client)
        API.reset()
        return
    end

    #Run the complete file
    try
        evalfile(tf)
    catch err
        handleexception(err, parsed_args["forward"])
    end

    # Finally close the ws client on successful/failed completion
    close_connection(client)
    API.reset()
end

try
    server = Server(wsh)
    run(server, host=IPv4(host), port=port)
catch err
    println(err)
    println("Error while launching WS server")
end

