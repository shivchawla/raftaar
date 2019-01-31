using Mongoc
using YRead
using Dates

client = Mongoc.Client("mongodb://127.0.0.1:27017")
YRead.configure(client, database="dbYojak_develop", priority=3)

#benchmarkdata = YRead.history_unadj([75769], "Close", :Day, DateTime("2018-01-01"), DateTime("2018-12-31"), displaylogs = false, strict = false)
#benchmarkdata = YRead.history_unadj(["TCS"], "Close", Symbol("1m"), DateTime("2018-12-01"), DateTime("2018-12-31"))

tickers= ["ACC","ADANIPORTS","AMBUJACEM",
	"ASIANPAINT","AUROPHARMA","AXISBANK","BAJAJ_AUTO"]

for ticker in tickers
	println(ticker)
	adjustments = YRead.getadjustments([ticker], DateTime("2016-01-01"), now(), displaylogs = false)
	println(adjustments)
end

