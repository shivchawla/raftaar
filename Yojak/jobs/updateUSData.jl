println(ENV)

using YWrite
using Mongoc
using JSON
using Dates


println("Running data update process for NSE at $(now())")
println()

function connect(host::String, port::Int, user::String="", pass::String="")
    usr_pwd_less = user=="" && pass==""

    #info_static("Configuring datastore connections")
    client = usr_pwd_less ? Mongoc.Client("mongodb://$(host):$(port)") :
                            Mongoc.Client("mongodb://$(user):$(pass)@$(host):$(port)/?authMechanism=MONGODB-CR&authSource=admin")
end

const source_dir = Base.source_dir()

parameters = JSON.parsefile(source_dir*"/configuration_quandl_update.json")
mongo_user = parameters["mongo_user"]
mongo_pass = parameters["mongo_pass"]
mongo_host = parameters["mongo_host"]
mongo_port = parameters["mongo_port"]

mongo_database = parameters["mongo_database"]

client = connect(mongo_host, mongo_port, mongo_user, mongo_pass)
YWrite.configure(client, database = mongo_database)

#Download partial file for today
auth_token_quandl = replace(read(joinpath(source_dir*"/../src/token/auth_token_quandl"), String),"\n" => "")
auth_token_EODH = replace(read(joinpath(source_dir*"/../src/token/auth_token_EODH"), String),"\n" => "")
refreshAll = haskey(parameters, "refreshAll") ? parameters["refreshAll"] : false


#YWrite.updatedb_fromEODH_US()
#YWrite.initialFullDownload("2019-01-01")
#YWrite.updateFundamentalAll()

