# Regexes to extract the relevant codes out of non-sense
const dataset_code_regex = r"(?<=^DEB/)[0-9A-Z]*_(A|Q|T)_[A-Z]*"
const ticker_regex = r"(?<=^DEB/)[0-9A-Z]*"
const freq_regex = r"(?<=_)(A|Q|T)(?=_)"
const metric_regex = r"(?<=_(A|Q|T)_)[A-Z]*"

function getbaseurl()
    return "https://www.quandl.com/api/v3/"
end

function getapikey()
    return "MX4zkypoSjUzp8CyotQg"
end

function getqueryargs()
    return Dict("api_key" => getapikey())
end

# Returns (ticker, freq, metric) from ticker_freq_metric
function extract_fromdatasetcode(dataset_code::String)
    tmp = map(String, split(dataset_code, "_"))
    return (tmp[1], tmp[2], tmp[3])
end

# Returns ticker_freq_metric from (ticker, freq, metric)
function todatasetcode(ticker::String, freq::String, metric::String)
    return ticker * "_" * freq * "_" * metric
end

# Download DEB-dataset-codes.csv
function download_datasetcodes(token::String; force::Bool = false)
	try
        zipped_codes_dir = source_dir * "/tmp"
        Base.mkpath(zipped_codes_dir)

        zipped_codes = zipped_codes_dir * "/zipped_codes"

		download(getbaseurl() * "databases/DEB/codes?api_key=$(token)", zipped_codes)

		r = ZipFile.Reader(zipped_codes)
        fdir=source_dir*"/data/"
        Base.mkpath(fdir)

        if length(r.files) > 0
            f = r.files[1]
            println("Extracting file")
            if force
                writedlm(fdir * f.name, readdlm(f))
            else
                if !isfile(fdir * f.name)
                    writedlm(fdir * f.name, readdlm(f))
                else
                    println("File already exists. Skipping extraction")
                end
            end
        end

        #Delete the downloaded file
        println("Deleting the downloaded zipped file")
        rm(zipped_codes)

		return 0

    catch err
        println(err)
    end

	return 1
end

# To load downloaded DEB dataset codes from file into memory
function getdatasetcodes(token::String; force::Bool = false)
    # Each ticker key points to all the datset codes for that stock
	ticker_to_datasetcodes = Dict{String, Array{String}}()

    # Download dataset codes
	success = download_datasetcodes(token, force = force)
	# success = 0

	if (success != 0)
		println("Error - while retrieving dataset codes file. Returning")
		return Dict{String, Array{String}}()
	end

	f = open(source_dir * "/data/DEB-datasets-codes.csv")
	lines = readlines(f)
    close(f)

	for x in lines
        # Extract required dataset code from a bunch of extra non sense
		if !ismatch(dataset_code_regex, x)
			println("Couldn't match $(x) with the dataset code regex")
			continue
		end

		m = match(dataset_code_regex, x)
		dataset_code = String(m.match)

        # Extract ticker name from this dataset code
		if !ismatch(ticker_regex, dataset_code)
			println("Couldn't match $(dataset_code) with the ticker regex")
			continue
		end

		m = match(ticker_regex, dataset_code)
		ticker = String(m.match)

        # Push the dataset code against this ticker in the dicttionary
		if !haskey(ticker_to_datasetcodes, ticker)
			ticker_to_datasetcodes[ticker] = []
		end
		push!(ticker_to_datasetcodes[ticker], dataset_code)
	end

	return ticker_to_datasetcodes
end

# Downloads data from given dataset_code
function getstockdata_fromquandl(dataset_code::String)
    # Downloads the data for the given dataset code
	url = getbaseurl() * "datasets/DEB/" * dataset_code * ".json"
    metric_data = Dict{String, Any}()

    println(url)
    
    try
        r = HTTP.request("GET", url; query = getqueryargs())
        if r.status == 200
    		raw_data = IOBuffer(r.body)
    		parsed_data = JSON.parse(raw_data)
            if haskey(parsed_data, "dataset")
                metric_data = parsed_data["dataset"]
            else
                println("Data is in unknown format for $(dataset_code)")
            end
    	else
            throw(HTTP.ExceptionRequest.StatusError)
        end
    catch (err)
        if typeof(err) == HTTP.ExceptionRequest.StatusError && err.status == 404
            println("Error - $(dataset_code) doesn't exist")
        else
            println(err)
        end
    end

	return metric_data
end

# For indexing our collection using securityid
function createindexbyticker(securitycollection::Mongoc.Collection)
    command_simple(
        securitycollection.client,
        securitycollection.db,
        Dict(
            "createIndexes" => securitycollection.name,
            "indexes" => [
                Dict(
                    "key" => Dict("securityid" => 1),
                    "name" => "symbol",
                    "unique" => 1
                )
            ]
        )
    )
end

function Float64(::Void)
    return NaN
end

# Insert your logic here for having custom redis key
function getrediskey(securityid::Int64, metric::String, freq::String)
    return string(securityid) * ":" * metric * ":" * freq
end

# Functions to convert securityid to ticker name
function getsecurityticker(securityid::Int64)
    return YRead.getsecurity(securitycollection(), securityid).symbol.ticker
end
