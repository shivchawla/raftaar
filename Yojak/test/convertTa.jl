using Mongo
using YRead
using TimeSeries

client = MongoClient()

YRead.configure(client)
YRead.configure(priority = 2)

#df = YRead.history(["ACC","ADANIPORTS"],"Close",:Day, 50, DateTime("2015-01-01"))
#=ta = YRead.history(["ACC","ADANIPORTS","AMBUJACEM",
    "ASIANPAINT","AUROPHARMA","AXISBANK","BAJAJ-AUTO",
    "BANKBARODA","BHEL","BPCL", "BHARTIARTL","INFRATEL",
    "BOSCHLTD","CIPLA","COALINDIA","DRREDDY","EICHERMOT",
    "GAIL","GRASIM","HCLTECH","HDFCBANK","HEROMOTOCO","HINDALCO",
    "HINDUNILVR","HDFC","ITC","ICICIBANK","IDEA",
    "INDUSINDBK","INFY","KOTAKBANK","LT","LUPIN","M&M",
    "MARUTI","NTPC","ONGC","POWERGRID","RELIANCE","SBIN",
    "SUNPHARMA","TCS","TATAMTRDVR","TATAMOTORS","TATAPOWER",
    "TATASTEEL","TECHM","ULTRACEMCO","WIPRO","YESBANK","ZEEL"],"Close",:Day, 50, DateTime("2015-01-01"))
=
println(ta)=#
#ta = convert(TimeArray, df)

#println(ta)


ta = YRead.history(["ACC","ADANIPORTS"],"Close",:Day, 50, DateTime("2015-01-01"))
println(ta)

ta = YRead.history_unadj(["ACC","ADANIPORTS"],"Close",:Day, 50, DateTime("2015-01-01"))
println(ta)

ta = YRead.history(["ACC","ADANIPORTS"],"Close",:Day, DateTime("2014-06-01"), DateTime("2015-01-01"))
println(ta)

ta = YRead.history_unadj(["ACC","ADANIPORTS"],"Close",:Day, DateTime("2014-06-01"), DateTime("2015-01-01"))
println(ta)
