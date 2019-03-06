println(ENV)

using YWrite
using Mongoc
using JSON
using Logger
using ZipFile
using Dates
using DelimitedFiles

println("Running data update process for NSE at $(now())")
println()

function connect(host::String, port::Int, user::String="", pass::String="")
    usr_pwd_less = user=="" && pass==""

    #info_static("Configuring datastore connections")
    client = usr_pwd_less ? Mongoc.Client("mongodb://$(host):$(port)") :
                            Mongoc.Client("mongodb://$(user):$(pass)@$(host):$(port)/?authMechanism=MONGODB-CR&authSource=admin")
end


function fetchBulkFromQuandl(exchange::String, token::String)
    try
        zip_data=source_dir*"/tmp/zip_data"*exchange

        download("https://www.quandl.com/api/v3/databases/XNSE/data?auth_token=$(token)&download_type=partial", zip_data)

        r = ZipFile.Reader(zip_data)
        fdir=source_dir*"/data/"

        if length(r.files) > 0
            f = r.files[1]
            println("Extracting file")
            if !isfile(fdir*f.name)
                writedlm(fdir*f.name, readdlm(f))
            else
                println("File already exists. Skipping extraction")
            end
        end

        #Delete the downloaded file
        println("Deleting the downloaded file")
        rm(zip_data)

    catch err
        println(err)
    end
end

function fetchBulkFromEODH(exchange::String, token::String)
    try
        bulk_data="$(source_dir)/data/EODH_$(exchange)_$(Dates.format(Dates.now(), "yyyymmdd")).csv"
        #download("http://eodhistoricaldata.com/api/eod-bulk-last-day/$(exchange)?api_token=$(token)", bulk_data)

    catch err
        println(err)
    end
end

function updateSecuritiesList(download=true)
    try
        Logger.info("Updating security list")
        security_file = source_dir * "/data/securities/securities.csv"

        if download
            Logger.info("Downloading security list from DEB database")
            download("https://s3.amazonaws.com/quandl-static-content/DEB/deb_tickers.csv", security_file);
        end

        alldata = readdlm(security_file, ',', Any, '\n'; header=true)
        YWrite.update_fromquandldeb_securitylist(alldata)

    catch err
        println(err)
    end
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
debDownload = haskey(parameters, "debDownload") ? parameters["debDownload"] : true


#updateSecuritiesList(debDownload)

#There is no latest file for NSE
#Indices list
allIndices = JSON.parsefile(source_dir*"/../src/data/indices.json")
YWrite.updatedb_fromNSEIndices(allIndices, priority=2, refreshAll=true)

#fetchBulkFromEODH("NSE", auth_token_EODH)
YWrite.updatedb_fromEODH("NSE", priority=3, refreshAll = refreshAll)
