#using Yojak

using Mongo

#=include("../src/history.jl")

client = MongoClient()
securitycollection = Mongoc.Collection(client, "aimsquant", "security_test") 
datacollection = Mongoc.Collection(client, "aimsquant", "data_test")=#

#=println(history(securitycollection, datacollection,
        "CNX_200","Close",:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        "CNX_200","Close",:A, 100, "2014-05-08"))

println(history(securitycollection, datacollection,
        ["CNX_200"],"Close",:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        ["CNX_200"],"Close",:A, 100, "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        ["CNX_200"],["Close"],:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        ["CNX_200"],["Close"],:A, 100, "2014-05-08"))

println(history(securitycollection, datacollection,
        "CNX_200",["Close", "Open"],:A,"2004-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        "CNX_200",["Close", "Open"],:A, 100, "2014-05-08"))

println(history(securitycollection, datacollection,
        ["CNX_200"],["Close", "Open"],:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        ["CNX_200"],["Close", "Open"],:A, 100, "2014-05-08"))=#

#=
println(history(securitycollection, datacollection,
        34,"Close",:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        34,"Close",:A, 100, "2014-05-08"))

println(history(securitycollection, datacollection,
        [34],"Close",:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        [34],"Close",:A, 100, "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        [34],["Close"],:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        [34],["Close"],:A, 100, "2014-05-08"))

println(history(securitycollection, datacollection,
        34,["Close", "Open"],:A,"2004-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        34,["Close", "Open"],:A, 100, "2014-05-08"))

println(history(securitycollection, datacollection,
        [34],["Close", "Open"],:A,"2009-01-07", "2014-05-08"))
                    
println(history(securitycollection, datacollection,
        [34],["Close", "Open"],:A, 100, "2014-05-08"))

#=println(history(securitycollection, datacollection,
        [],[],:A, 100, "2014-05-08"))=#

println(history(securitycollection, datacollection,
        [34,34],["Close","Open"],:A, 100, "2014-05-08"))

println(history(securitycollection, datacollection,
        [34],[""],:A, 100, "2014-05-08"))=#

#history(securitycollection, datacollection,
 #       ["CNX_BANK"],"Close",:A, 500, "2014-05-08")

#history(securitycollection, datacollection,
 #       collect(2:16),"Close",:A,"2009-01-07", "2014-05-08")
   

history(securitycollection, datacollection,["CNX_BANK"],"Close",:A, 500, "2014-05-08")
#history("CNX_BANK", "Close", :A, 500, enddate="2014-05-08")

