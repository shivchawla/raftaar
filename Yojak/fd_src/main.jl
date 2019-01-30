using Redis, Mongo, LibBSON, JSON, ZipFile, HTTP, TimeSeries
using YRead
import Base.Float64

include("types.jl")          # Custom Types
include("API.jl")            # Core API functions
include("retrieve.jl")       # Functions to retrieve data from cache/db/Quandl
include("store.jl")          # Functions to store data in cache/db
include("helpers.jl")        # Other Helper functions

# Following conventions from - https://docs.julialang.org/en/release-0.6/manual/style-guide/

# Global variables
source_dir = Base.source_dir()

# Dictionary to store global parameters
const dict = Dict{String, Any}()

securitycollection() = Mongoc.Collection(dict["client"], dict["db"], "security_test")
fd_dbcollection() = Mongoc.Collection(dict["client"], dict["db"], "fundamental_data")
#fd_redisconnection() = RedisConnection()
fd_redisconnection() = RedisConnection(host=dict["redis_host"], port=dict["redis_port"])

function configure_db(cl::MongoClient; database::String = "dbYojak_dev")
    dict["client"] = cl
    dict["db"] = database
end

function configure_redis(host="127.0.0.1", port=13472, db=0, password="")
    dict["redis_host"] = host
    dict["redis_port"] = port
    dict["redis_db"] = db
    dict["redis_password"] = password
end

client = MongoClient()
YRead.configure(client, database = "aimsquant")
configure_db(client; database="aimsquant")
configure_redis()

# createindexbyticker(fd_dbcollection())

# ========================
#  Examples for using API
# ========================

@sync begin
    # Need to wrap in sync because Redis-save/Mongo-save operations needs to be completed

    # Single security, single metric, horizon of 100 days starting from 30-03-2015
    tmp = history(19164, "OEXPNS", Date(2015,3,30), Date(2016,3,30); accountingType = Standalone)
    println(tmp)

    # Multiple securities, single metric, horizon of 100 days starting from 30-03-2015
    tmp = history([19164, 40527, 96256], "CWIP", Date(2015,3,30), 100; accountingType = Standalone)
    println(tmp)

    # Multiple securities, single metric, from 30-03-2015 to today
    tmp = history([19164, 40527, 96256], "BSEL", Date(2015,3,30), Dates.today(); accountingType = Standalone)
    println(tmp)

    # Single security, multiple metrics, horizon of 365 days starting from 01-01-2018
    tmp = history(19164, ["OEXPNS", "REVSH", "CFO", "CFROA"], Date(2018,1,1), 365; accountingType = Standalone)
    println(tmp)

    # Single security, single metric, horizon of 100 days starting from 30-03-2015
    tmp = raw(19164, "OEXPNS", Date(2015,3,30), Date(2016,3,30); accountingType = Standalone)
    println(tmp)

    # Multiple securities, single metric, from 30-03-2015 to today
    tmp = raw([19164, 40527, 96256], "BSEL", Date(2015,3,30), Dates.today(); accountingType = Standalone)
    println(tmp)

    # Single security, multiple metrics, horizon of 365 days starting from 01-01-2018
    tmp = raw(19164, ["OEXPNS", "REVSH", "CFO", "CFROA"], Date(2018,1,1), 365; accountingType = Standalone)
    println(tmp)
end
