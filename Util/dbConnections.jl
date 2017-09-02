using YRead
import Mongo: MongoClient
using API
using JSON

#Setup database connections
connection = JSON.parsefile(Base.source_dir()*"/connection.json")
mongo_user = connection["mongo_user"]
mongo_pass = connection["mongo_pass"]
mongo_host = connection["mongo_host"]
mongo_port = connection["mongo_port"]
   
usr_pwd_less = mongo_user=="" && mongo_pass==""

#info_static("Configuring datastore connections")
const client = usr_pwd_less ? MongoClient(mongo_host, mongo_port) :
                        MongoClient(mongo_host, mongo_port, mongo_user, mongo_pass)

YRead.configure(client, database = connection["mongo_database"])
YRead.configure(priority = 2)
