import API
import HistoryAPI
import UtilityAPI
import OptimizeAPI
import Raftaar
import YRead

using WebSockets
using HttpServer
using JSON

user="jp"
host = "127.0.0.1"
port = 8000

SERVER_READY = false
MAX_PENDING_REQUESTS = 4

try
  user = ARGS[1]  
  host = ARGS[2]
  port = parse(ARGS[3])
end

busy_worker_dict = Dict{Int, Bool}()
for id in workers()
    busy_worker_dict[id] = false
end

source_dir = Base.source_dir()
@eval @everywhere source_dir = $source_dir
@everywhere include("$(source_dir)/evalStrategy.jl")

function decodeMessage(msg)
    JSON.parse(String(copy(msg)))
end

function isserveravailable()
    server_available = SERVER_READY && length(backtests_requests) < MAX_PENDING_REQUESTS
    println("Server Available: $server_available")
    server_available
end

backtests_requests = []

function getfreeprocess()
    for (k,v) in busy_worker_dict
        if v == false
            return k
        end 
    end

    return -1  
end

function save_backtest(args)
    push!(backtests_requests, args)
end

function get_backtest()
    shift!(backtests_requests)
end

function hasavailableworkers()
    getfreeprocess() != -1
end

function process_backtest()
    
    process_number = getfreeprocess() 
    
    if process_number != -1
        busy_worker_dict[process_number] = true
        try
            args = get_backtest()
            r = @spawnat process_number evaluate_strategy(args)
            f = fetch(r)

            busy_worker_dict[process_number] = false
            process_backtest()
        catch err
            busy_worker_dict[process_number] = false
        end
    end
end

function close_connection(client)  
    println("Closing Connection: $client")
    try
        close(client)
    catch
        println("Error Closing: $client")
    end
end

wsh = WebSocketHandler() do req, client

    println("Got Client: $client")
    msg = ""
    try
        
        msg = decodeMessage(read(client))

        requestType = haskey(msg, "requestType") ? msg["requestType"] : ""

        if requestType == "execute" 
            if !isserveravailable()
                responseMsg = Dict{String, Any}("msg" => "Server Unavailable", "code" => 503, "outputtype" => "internal")
                write(client, JSON.json(responseMsg))
                close_connection(client)
                return
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
        println(err)
        close_connection(client)   
        return 
    end
    
    #Acknowledge the requests by sending code 200
    responseMsg = Dict{String, Any}("msg" => "Server Available", "code" => 200, "outputtype" => "internal")
    write(client, JSON.json(responseMsg))
    close_connection(client)
    
    argsString = msg["args"]
    args = [String(ss) for ss in split(argsString,"??##")]
    save_backtest(args)
    
    if hasavailableworkers()
        process_backtest()
    end

end

try
    server = Server(wsh)
    run(server, host=IPv4(host), port=port)
catch err
    println(err)
    println("Error while launching WS server")
end
