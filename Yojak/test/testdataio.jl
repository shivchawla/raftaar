
using YWrite
using Mongo

mongo_user = "admin"
mongo_pass = "aimsquant05!"
mongo_host = "35.154.134.30"
mongo_port = 27017

#client = MongoClient(mongo_host, mongo_port, mongo_user, mongo_pass)
client = MongoClient()


YWrite.configure(client, database = "aimsquant")

#YWrite.deleteAll()

YWrite.setauthtoken("gWf2CLShwrGUBVnqzsT4")

YWrite.updatedb_fromquandl("XNSE", perpage=5, pages=1, priority=2)



