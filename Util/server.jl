using YRead
import Mongo: MongoClient
using API
using HttpServer
using WebSockets
using JSON

port = 2000
host = "127.0.0.1"

println(ARGS)

try
  port = parse(ARGS[1])
  host = ARGS[2]
end

include("../Util/handleErrors.jl")
include("../Util/parseArgs.jl")
include("../Util/processArgs.jl")
include("../Util/Run_Algo.jl")

#Setup database connections
connection = JSON.parsefile("../raftaar/Util/connection.json")
println(connection)
#const client = MongoClient(connection["mongo_host"], connection["mongo_user"], connection["mongo_pass"], connection["mongo_database"])
const client = MongoClient()
info("Configuring datastore connections", datetime=now())    

YRead.configure(client, database = connection["mongo_database"])
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
    
    setlogmode(:log, :socket, true, client)

    write(client,"Hello");

    while !busy

        global busy = true
        msg = read(client)
      
        argsString = decodeMessage(msg)
        
        args = [String(ss) for ss in split(argsString,"??##")]
        println(args)

        # Parse arguments from the connection message.
        try
          write(client,"Hello 2");
    
          info("Parsing arguments from settings panel", datetime = now())    
          parsed_args = parse_arguments(args)
          #return parsed_args
          
          println(1)

          write(client,"Hello 3");

          info("Processing parsed arguments from settings panel", datetime = now())    
          fname = processargs(parsed_args)
        
          println(2)
          #fname = "/users/shivkumarchawla/raftaar/Examples/momentumStrategy.jl"
         
          info("Building user algorithm", datetime = now())
          include(fname)

          println(3)
          write(client,"Hello 4");
          
          info("Starting Backtest", datetime = now())
          run_algo()
          
          info("Ending Backtest", datetime = now())

          API.reset()

          println("LOL")
        
        catch err
          println(err)
          handleexception(err)
        end

        global busy = false
        

        # close conection
        # close(client)
        break

        #=output = takebuf_string(Base.mystreamvar)
        val = val == nothing ? "<br>" : val
        write(client,"$val<br>$output")=#
    end

   # close conection
    close(client)
     
end

server = Server(wsh)
run(server, host=IPv4(host), port=port)

