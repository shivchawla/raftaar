using YRead
import Mongo: MongoClient
using API
using HttpServer
using WebSockets
using JSON

port = 2000
host = "127.0.0.1"

try
  port = parse(ARGS[1])
  host = ARGS[2]
end

include("../Util/handleErrors.jl")
include("../Util/parseArgs.jl")
include("../Util/processArgs.jl")
include("../Util/Run_Algo.jl")

#Setup database connections
#=
connection = JSON.parsefile("../raftaar/Util/connection.json")
println(connection)
const client = MongoClient(connection["mongo_host"], connection["mongo_user"], connection["mongo_pass"])
info("Configuring datastore connections", datetime=now())
=#

const client = MongoClient();
# YRead.configure(client, database = connection["mongo_database"])
YRead.configure(client, database = "aimsquant")
YRead.configure(priority = 2)

#global Dict to store open connections in
global connections = Dict{Int,WebSocket}()

function decodeMessage(msg)
    String(copy(msg))
end

wsh = WebSocketHandler() do req, client
    global connections
    connections[client.id] = client

    setlogmode(:json, :socket, true, client)

    msg = read(client)
    argsString = decodeMessage(msg)
    args = [String(ss) for ss in split(argsString,"??##")]

    # Parse arguments from the connection message.
    info_static("Parsing arguments from settings panel")
    parsed_args = parse_arguments(args)

    parseError = false
    info_static("Processing parsed arguments from settings panel")
    fname = ""
    try
        fname = processargs(parsed_args)
    catch err
        info_static("Error parsing arguments from settings panel")
        parseError = true
        handleexception(err)
    end
        
    if !parseError
        info_static("Building user algorithm")
        
        #catch compile time errors in the user file
        compileError = false
        try
            include(fname)
        catch err
            compileError = true
            handleexception(err)
        end

        if !compileError
            info_static("Starting Backtest")
            run_algo(parsed_args["forward"])
            API.reset()
            info_static("Ending Backtest")
        end
    end

    close(client)

end

server = Server(wsh)
run(server, host=IPv4(host), port=port)
