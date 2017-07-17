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
busy = false
fname = ""

function decodeMessage(msg)
    String(copy(msg))
end

wsh = WebSocketHandler() do req, client
    global connections
    connections[client.id] = client

    try
        setlogmode(:json, :socket, true, client)

        while !busy

            global busy = true
            msg = read(client)
            argsString = decodeMessage(msg)
            args = [String(ss) for ss in split(argsString,"??##")]

            # Parse arguments from the connection message.

            info("Parsing arguments from settings panel", datetime = now())
            parsed_args = parse_arguments(args)

            info("Processing parsed arguments from settings panel", datetime = now())
            fname = processargs(parsed_args)

            info("Building user algorithm", datetime = now())
            include(fname)

            info("Starting Backtest", datetime = now())
            run_algo(parsed_args["forward"])

            info("Ending Backtest", datetime = now())

            API.reset()

            global busy = false
            break

        end
    catch err
        handleexception(err)
    end

    close(client)

end

server = Server(wsh)
run(server, host=IPv4(host), port=port)
