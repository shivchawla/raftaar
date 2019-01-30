
using YRead
using Mongo
using JSON

connection = JSON.parsefile("/Users/shivkumarchawla/aqbackend/Julia/connection.json")
mongo_user = connection["mongo_user"]
mongo_pass = connection["mongo_pass"]
mongo_host = connection["mongo_host"]
mongo_port = connection["mongo_port"]
 
usr_pwd_less = mongo_user=="" && mongo_pass==""
const client = usr_pwd_less ? MongoClient(mongo_host, mongo_port) :
                        MongoClient(mongo_host, mongo_port, mongo_user, mongo_pass)
 
YRead.configure(client, database = connection["mongo_database"], priority = 2)

#YRead.history_unadj(["WIPRO"],"Close",:Day, DateTime("2017-06-01"), DateTime(Date(now())))


#YRead.history(["WIPRO"],"Close",:Day, DateTime("2017-06-01"), DateTime("2017-06-30"))

#YRead.history_unadj(["WIPRO"],"Close",:Day, 1 , now(), offset=-1)
#YRead.history_unadj(["WIPRO"],"Close",:Day, now()-Dates.Week(52) , now())

#YRead.history(["INFY"], "Close", :Day, 1 , now())
#YRead.history(["TCS"], "Close", :Day, 1 , now(), forwardfill=true)

newStartDate = DateTime("2018-06-20")
YRead.history(["TCS"], "Close", :Day, 1, now(), displaylogs=false, forwardfill=true)
#YRead.history(["TCS"], "Close", :Day, newStartDate, now(), displaylogs=false, forwardfill=true)

date = now()
start_date = DateTime(Date(date) - Dates.Week(52))
end_date = date

#fetch stock data and drop where all values are NaN
#stock_value_52w = TimeSeries.dropnan(YRead.history_unadj(["TCS"], "Close", :Day, start_date, end_date, displaylogs=false), :all)
YRead.history_unadj(["NIFTY_50"], "Close", :Day, start_date, end_date, strict=false) 
