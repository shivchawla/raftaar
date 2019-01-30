
using YRead

function connect(host::String, port::Int, user::String="", pass::String="")
    usr_pwd_less = user=="" && pass==""

    client = Mongoc.Client("mongodb://myUserAdmin:abc123@localhost/?authMechanism=SCRAM-SHA-256&authSource=admin")

    #info_static("Configuring datastore connections")
    client = usr_pwd_less ? Mongoc.Client("mongodb://$(host):$(port)") :
                            Mongoc.Client("mongodb://$(user):$(pass)@$(host):$(port)/?authMechanism=MONGODB-CR&authSource=admin")
end

function getredisclient(host::String="127.0.0.1", port::Int=6379, password::String="")

    println("Setting up redis client at $(host)/$(port)")
    try
        return RedisConnection(host=host, port=port, password=password, db=0)
    catch err
        println("Error while setting redis-client")
        println(err)
    end
end


# Setup data stores 
function setdatastores(connections)
    try
        yojak_conn = connections["yojak_datastore"]
        
        yuser = get(yojak_conn, "user", "")
        ypass = get(yojak_conn, "pass", "")
        yhost = get(yojak_conn, "host", "127.0.0.1")
        yport = get(yojak_conn, "port", 27017)
        priority = get(yojak_conn, "priority", 3)
        ydatabase = get(yojak_conn, "database", "dbYojak_develop")
       
        yclient = connect(yhost, yport, yuser, ypass)
        YRead.configure(yclient, database = ydatabase, priority = priority)
    catch err
        println(err)  
    end
end


# Setup logger database connection
function setredisconnection(connections)
    try
        redis_conn = connections["redis"]

        rpass = get(redis_conn, "pass", "")
        rhost = get(redis_conn, "host", "127.0.0.1")
        rport = get(redis_conn, "port", "13472")

        delete!(connections, "redis")
           
        Logger.setredisclient(getredisclient(rhost, rport, rpass))    
    catch err
        println(err)
    end
end

connections = JSON.parsefile(Base.source_dir()*"/connection.json")

setdatastores(connections)
setredisconnection(connections)

connections = nothing
