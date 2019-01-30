using API
using Raftaar
using YRead
using Mongo

client = MongoClient()

YRead.configure(client)

#=function adduniverse(ticker::String;
                        securitytype::String="EQ",
                        exchange::String="NSE")=#

adduniverse(56145)
println(getuniverse())

adduniverse([23423, 56145])
println(getuniverse())

adduniverse("CNX_BANK")
println(getuniverse())

adduniverse(["CNX_BANK", "CNX_NIFTY"])
println(getuniverse())

setuniverse("CNX_BANK")
println(getuniverse())

setuniverse(["CNX_BANK", "CNX_NIFTY"])
println(getuniverse())





setuniverse("CNX_BANK")
println(getuniverse())

setuniverse(["CNX_BANK", "CNX_NIFTY"])
println(getuniverse())


println(ispartofuniverse("CNX_BANK"))
println(ispartofuniverse("CNX"))
println(ispartofuniverse(getsecurity("CNX_BANK")))
println(ispartofuniverse(getsecurity("CNX_BANK").symbol))
println(ispartofuniverse(getsecurity("CNX_BANK").symbol.id))
println(ispartofuniverse(getsecurity("CNX_BANK").symbol.ticker))
