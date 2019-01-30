include("../src/dbread.jl")

client = MongoClient()
securitycollection = Mongoc.Collection(client , "aimsquant","security_test") 

secid = getsecurityid(securitycollection,"CNX_200")
datacollection = Mongoc.Collection(client , "aimsquant","data_test")

println(getdatabyyear(datacollection, secid, "Open", 2010))
println(getdatabyyear(datacollection, secid, ["Open"], 2010))
println(getdatabyyear(datacollection, secid, ["Close"], 2010))
println(getdatabyyear(datacollection, secid, ["Close","Open"], 2010))


println(getdata(datacollection, secid, "Close", "2001-01-01","2012-03-03"))
println(getdata(datacollection, secid, "Open", 10000 ,"2012-03-03"))

println(getdata(datacollection, secid, ["Open"], "2001-01-01","2012-03-03"))
println(getdata(datacollection, secid, ["Close"], 10000 ,"2012-03-03"))

println(getdata(datacollection, secid, ["Close","Open"], "2001-01-01","2012-03-03"))
println(getdata(datacollection, secid, ["Close","Open"], 10000 ,"2012-03-03"))
