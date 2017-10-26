using YRead
using Mongo
using Optimize

connection = JSON.parsefile("/Users/shivkumarchawla/Raftaar/Util/connection.json")
mongo_user = connection["mongo_user"]
mongo_pass = connection["mongo_pass"]
mongo_host = connection["mongo_host"]
mongo_port = connection["mongo_port"]
   
usr_pwd_less = mongo_user=="" && mongo_pass==""

#info_static("Configuring datastore connections")
const client = usr_pwd_less ? MongoClient(mongo_host, mongo_port) :
                        MongoClient(mongo_host, mongo_port, mongo_user, mongo_pass)

YRead.configure(client, database = connection["mongo_database"], priority = 2)

universe = ["ACC","ADANIPORTS","AMBUJACEM",
    "ASIANPAINT","AUROPHARMA","AXISBANK","BAJAJ_AUTO",
    "BANKBARODA","BHEL","BPCL", "BHARTIARTL","INFRATEL",
    "BOSCHLTD","CIPLA","COALINDIA","DRREDDY","EICHERMOT",
    "GAIL","GRASIM","HCLTECH","HDFCBANK","HEROMOTOCO","HINDALCO",
    "HINDUNILVR","HDFC","ITC","ICICIBANK","IDEA",
    "INDUSINDBK","INFY","KOTAKBANK","LT","LUPIN","M_M",
    "MARUTI","NTPC","ONGC","POWERGRID","RELIANCE","SBIN",
    "SUNPHARMA","TCS","TATAMTRDVR","TATAMOTORS","TATAPOWER",
    "TATASTEEL","TECHM","ULTRACEMCO","WIPRO","YESBANK","ZEEL"]

println(Optimize.minimumabsolutedeviation(universe, 22, DateTime("2017-01-01")))
println(Optimize.minimumabsolutesemideviation(universe, 22, DateTime("2017-01-01")))
println(Optimize.minimumloss(universe, 22, DateTime("2017-01-01")))
println(Optimize.minimumvolatility(universe, 22, DateTime("2017-01-01")))


