include("../src/dbwrite.jl")

setauthtoken("gWf2CLShwrGUBVnqzsT4")
getmetadata("NSE")
docs = getsecuritydata("NSE")

client = MongoClient()
securitycollection = Mongoc.Collection(client , "aimsquant","security_test")
#datacollection = Mongoc.Collection(client , "aimsquant","data_test")

Mongo.delete(securitycollection, ("securityid"=>34))
#Mongo.delete(datacollection, ("securityid"=>34))

insertsecuritydata_fromquandl(securitycollection, 34, docs[1])
insertsecuritydata_fromquandl(securitycollection, 34, docs[2])
updatesecuritydata_fromquandl(securitycollection, 34, docs[1])

#=insertdata_fromquandl(datacollection, 34, k)=#

#=for doc in find(securitycollection, ("securityid" => 34))
    println(doc)
end=#
#insertdata_fromquandl(datacollection, 34, k, data["columns"], dd)

#println(count(securitycollection, ("securityid" => 34)))
#println(count(datacollection, ("securityid" => 34)))

#find_one(datacollection, Dict("securityid"=>34))#
