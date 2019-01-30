
using Mongo
using YRead
using DataStructures
using LibBSON

function curatequandlsecurity(quandlsecurity, quandlsource::String)

    curateddata = Dict{String,Any}()

    if quandlsource == "NSE"
        curateddata["ticker"] = quandlsecurity["dataset_code"]
        curateddata["exchange"] = "NSE"
        curateddata["securitytype"] = "EQ"
        curateddata["country"] = "IN"
    elseif quandlsource == "XNSE"    
        
        #XNSE has dataset codes as ticker_ADJ or ticker_UADJ
        dataset_code = quandlsecurity["dataset_code"]
        
        if(contains(dataset_code, "_ADJ")) 
            curateddata["ticker"] = replace(dataset_code, "_ADJ", "")
        elseif (contains(dataset_code, "_UADJ"))
            curateddata["ticker"] = replace(dataset_code, "_UADJ", "")
        else 
            curateddata["ticker"] = dataset_code
        end

        curateddata["exchange"] = "NSE"
        curateddata["securitytype"] = "EQ"
        curateddata["country"] = "IN"
    end

    return curateddata
end


client = MongoClient()

YRead.configure(client)

dcol = Mongoc.Collection(client, "aimsquant", "data_test")
scol = Mongoc.Collection(client, "aimsquant", "security_test")

doc = command_simple(client,
               "aimsquant",
               OrderedDict(
                "distinct" => "data_test",
                "key" => "securityid",
                "query" => Dict("priority"=>1),
            ))

secids = LibBSON.vector(doc["values"])

for i = 1:length(secids)

    query = ("securityid"=>secids[i], "priority"=>1)
    doc = first(find(dcol, query))

    priority = doc["priority"]

    #sourcedata = LibBSON.dict(doc["datasource"])   
    #println(sourcedata)

    sourcedata = Dict{String, Any}()
    for (k,v) in doc["datasource"]
        
        if isa(v, LibBSON.BSONArray)
            sourcedata[k] = vector(v)
        else
            sourcedata[k] = v
            #break
        end
    end

    #println(sourcedata)
    #println(sourcedata["refreshed_at"])
    #break

    
    sourcedata["sourcename"] = "quandl_"*sourcedata["database_code"]

    source = priority==1 ? "NSE" : "XNSE"

    csecurity = curatequandlsecurity(sourcedata, source)

    csecurity["name"] = sourcedata["name"]

    
    if(count(scollection, ("securityid"=>securityid))==0)
        csecurity["datasources"] = [sourcedata]
        insert(scollection, csecurity)

    else if(count(scollection, ("securityid"=>securityid, 
                                    "datasources"=>Dict("\$elemMatch"=>Dict("sourcename"=>"quandl_"*sourcedata["database_code"],
                            "id"=>sourcedata["id"])))) == 0)

        update(securitycollection, Dict("securityid"=>securityid), Dict("\$push"=>Dict("datasources"=>sourcedata)))
    end             

    #=if length(csecurity["datasources"]) == 0
        csecurity["datasources"] = [sourcedata]
    else
        push!(csecurity["datasources"], sourcedata)
    end=#

    
end  


