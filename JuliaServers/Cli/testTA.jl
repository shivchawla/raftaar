using Mongoc
using YRead
using Dates
import Redis

client = Mongoc.Client("mongodb://127.0.0.1:27017")
redisClient = Redis.RedisConnection(host="127.0.0.1", port=13472, password="", db=0)

YRead.configureMongo(client, database="dbYojak_develop", priority=3)
YRead.configureRedis(redisClient)

# ta = YRead.history_unadj(["YESBANK", "TCS", "WIPRO"], "Close", :Day, DateTime("2017-08-01"), DateTime("2017-09-30"), displaylogs = false, strict = false)
# tb = YRead.history(["YESBANK, TCS"], "Close", :Day, DateTime("2017-08-01"), DateTime("2017-09-30"), displaylogs = false, strict = false)
# benchmarkdata = YRead.history_unadj(["YESBANK"], "Close", Symbol("1m"), DateTime("2018-12-01"), DateTime("2018-12-31"))

# tickers= ["ACC","ADANIPORTS","AMBUJACEM",
# 	"ASIANPAINT","AUROPHARMA","AXISBANK","BAJAJ_AUTO"]

# for ticker in tickers
# 	println(ticker)
# 	adjustments = YRead.getadjustments([ticker], DateTime("2016-01-01"), now(), displaylogs = false)
# 	println(adjustments)
# end



 YRead.history_unadj(["TCS"], "Close", :Day, DateTime("2018-12-01"), DateTime("2018-12-31"), displaylogs = false, strict = false)