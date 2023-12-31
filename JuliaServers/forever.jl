using JSON
import Redis

port = ARGS[1]
env = ARGS[2]

if env == "develop"
    env = "development"
end

BACKTEST_QUEUE = "backtest-request-queue-$(env)"
THIS_PROCESS_BACKTEST_SET = "backtest-request-set-julia-$(port)"
COMPLETE_BACKTEST_SET  = "backtest-completion-set-$(env)";
BACKTEST_REALTIME_CHANNEL_PREFIX = "backtest-realtime-"
BACKTEST_FINAL_CHANNEL_PREFIX = "backtest-final-"
DEFAULT_WAIT_TIME = 5
CURRENT_WAIT_TIME = 0.1

source_dir = Base.source_dir()
include("$(source_dir)/Util/evalStrategy.jl")

backtests_requests = []
redisClient = nothing
restart = true 

function setupRedisClient()
    println("Setting up redis client")
    try
        connections = JSON.parsefile("$(source_dir)/connection.json")
        redis_conn = get(connections, "redis", Dict())
        
        pass = get(redis_conn, "pass", "")
        host = get(redis_conn, "host", "127.0.0.1")
        port = get(redis_conn, "port", 13472)
        delete!(connections, "redis")
        global redisClient = Redis.RedisConnection(host=host, port=port, password=pass, db=0)
    catch err
        println(err)
    end
end

function save_backtest(args)
    push!(backtests_requests, args)
end

function get_backtest()
    if length(backtests_requests) > 0
        popfirst!(backtests_requests)
    end
end

function process_backtest()
    args = get_backtest()
    if args != nothing
        evaluate_strategy(args)
    end

end

"""
Add requests to active sets
"""
function addRequestToActiveSet(request)
    try
        println("Assigning Julia port to request")
        request["juliaPort"] = port
        backtestId = get(request, "backtestId", "")
        
        println("Adding request to current process request set")
        Redis.hset(redisClient, THIS_PROCESS_BACKTEST_SET, backtestId, JSON.json(request))
    catch err
        println("Error adding request to active set")
        println(err)
        
        if (typeof(err) == Redis.ConnectionException)
            println("Reconnect and retry")
            setupRedisClient()
            if (Redis.is_connected(redisClient))
                addRequestToActiveSet(request)
            else
                println("Error reconnecting redis")
                rethrow(err)
            end
        else
            rethrow(err)
        end
    end

end

"""
Remove request from active sets
Push them back to full list based on success flag
"""
function removeRequestFromActiveSet(request; success=true)

    try
        backtestId = get(request, "backtestId", "")
        
        println("Removing request from current process request set")
        Redis.hdel(redisClient, THIS_PROCESS_BACKTEST_SET, backtestId)

        #On failure, add the request back to the queue 
        if !success
            delete!(request, "juliaPort")
            println("Request Failed: Adding request back to full list")
            Redis.lpush(redisClient, BACKTEST_QUEUE, JSON.json(request))
        #On success, add to completion set
        else
            println("Request Success: Setting completion flag to true in completion set")
            Redis.hset(redisClient, COMPLETE_BACKTEST_SET, backtestId, "1")
        end
    catch err
        println("Error removing request from Active Set");
        println(err)

        if (typeof(err) == Redis.ConnectionException)
            println("Reconnect and retry")
            setupRedisClient()
            if (Redis.is_connected(redisClient))
                removeRequestFromActiveSet(request, success = success)
            else 
                println("Error reconnecting redis")
                rethrow(err)
            end  
        else 
            rethrow(err)
        end
    end

end

"""
Add back the original request in case of failure
"""
function addBackOriginalRequest(rawRequest)
    try
        if rawRequest != nothing 
            println("Pushing the request in original queue")
            Redis.rpush(redisClient, BACKTEST_QUEUE, rawRequest)
        end
    catch
        println("Error while adding back the original request")
        println(err)
        if (typeof(err) == Redis.ConnectionException)
            println("Reconnect and retry")
            setupRedisClient()
            
            if (Redis.is_connected(redisClient))
                addBackOriginalRequest(rawRequest)
            else
                println("Error reconnecting redis")
                rethrow(err)
            end
        else 
            rethrow(err)
        end
    end
end


"""
Remove all active requests on restart 
Push them back to Full-list
"""
function removeActiveRequestOnRestart()
    if restart
        
        #Now push all active requests to full list
        allRawRequests = Redis.hgetall(redisClient, THIS_PROCESS_BACKTEST_SET)

        for (key, rawRequest) in allRawRequests 
            
            if rawRequest != nothing
                try
                    request = rawRequest != nothing ? JSON.parse(rawRequest) : nothing
                    backtestId = request != nothing ? get(request, "backtestId", "") : ""

                    if backtestId != ""
                        #Delete from active set
                        Redis.hdel(redisClient, THIS_PROCESS_BACKTEST_SET, backtestId)

                        #Delete all realtime data in realtime channel for this request
                        Redis.del(redisClient, BACKTEST_REALTIME_CHANNEL_PREFIX*backtestId)

                        #Delete all static data in realtime channel for this request
                        Redis.del(redisClient, BACKTEST_FINAL_CHANNEL_PREFIX*backtestId)

                        #Remove julia port related info
                        delete!(request, "juliaPort")

                        #Add back to the front of the overall queue
                        Redis.rpush(redisClient, BACKTEST_QUEUE, JSON.json(request))
                    end

                catch err 
                    println(err)
                end
            end

        end
    end

    global restart = false
end


"""
Fetch request to process
Tries to fetch from the restart list before actual list
"""
function fetchRequest()
    rawRequest = nothing
    
    countRequests = Redis.llen(redisClient, BACKTEST_QUEUE)
    if countRequests > 0 
        println("Fetching request from full list")
        rawRequest = Redis.rpop(redisClient, BACKTEST_QUEUE)
    end
   
    return rawRequest
end


"""
Function to process the full list (1-by-1)
"""
function processRedisQueue()
    global restart

    if redisClient == nothing
        throw(Redis.ConnectionException("Client unavailable"))
    end

    if restart
        removeActiveRequestOnRestart()
    end

    rawRequest = fetchRequest()
    request = nothing    
    
    try
        if rawRequest != nothing 
            request = rawRequest != nothing ? JSON.parse(rawRequest) : nothing
        end
        
        if request != nothing && rawRequest != nothing 
            
            #Add the request to active sets (overall and this process)
            println("Pushing the request to active/julia set")
            addRequestToActiveSet(request) 
            
            argsString = request["argArray"]
            args = [String(ss) for ss in split(argsString,"??##")]
            
            save_backtest(args)
            
            try
                process_backtest()
                println("Finish processing backtest")

                removeRequestFromActiveSet(request, success = true)
            catch  err
                println("Error processing backtest")
                println(err)

                removeRequestFromActiveSet(request, success = false)
            end

            CURRENT_WAIT_TIME = 0.1

        end
    catch err 
        println(err)
        addBackOriginalRequest(rawRequest)
    end
    
end

"""
Entry function (runs every 5 seconds when idle/runs immediately otherwise)
"""
function startProcess() 
    try 
        #Reset current wait time
        CURRENT_WAIT_TIME = DEFAULT_WAIT_TIME
        processRedisQueue()
        
    catch err 
        println("Error processing redis queue")
        println(err) 
        
        if (typeof(err) == Redis.ConnectionException)
            setupRedisClient()
        end
    end

end

setupRedisClient()

println("Starting to process redis queue")
#Updating the logic to keep the process running without using any recursion
while true
    startProcess()
    wait(Timer(CURRENT_WAIT_TIME))
end



