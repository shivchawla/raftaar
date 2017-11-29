
function connect(host::String, port::Int, user::String="", pass::String="")
    usr_pwd_less = user=="" && pass==""

    #info_static("Configuring datastore connections")
    client = usr_pwd_less ? MongoClient(host, port) :
                            MongoClient(host, port, user, pass)
end

# Setup data stores 
function setdatastores(connections)
    try
        yojak_conn = connections["yojak_datastore"]
        yuser = yojak_conn["user"]
        ypass = yojak_conn["pass"]
        yhost = yojak_conn["host"]
        yport = yojak_conn["port"]
        ydatabase = yojak_conn["database"]
           
        const yclient =  connect(yhost, yport, yuser, ypass)
        YRead.configure(yclient, database = ydatabase, priority = 2)
    catch err
        println(err)  
    end
end

# Setup logger database connection
function setloggerconnection(connections)
    try
        logger_conn = connections["logger"]
        user = logger_conn["user"]
        pass = logger_conn["pass"]
        host = logger_conn["host"]
        port = logger_conn["port"]
        database = logger_conn["database"]
        collection = logger_conn["collection"]
           
        const lclient =  connect(host, port, user, pass)
        Logger.setmongoclient(MongoCollection(lclient, database, collection)) 
    catch err
        println(err)
    end
end

# Setup logger database connection
function setredisconnection(connections)
    try
        logger_conn = connections["redis"]
        user = logger_conn["user"]
        pass = logger_conn["pass"]
        host = logger_conn["host"]
        port = logger_conn["port"]
           
        Logger.setredisclient(host, port) 
    catch err
        println(err)
    end
end

connections = JSON.parsefile(Base.source_dir()*"/connection.json")
setdatastores(connections)
#setloggerconnection(connections)
setredisconnection(connections)

