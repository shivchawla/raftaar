# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

function processargs(parsed_args::Dict{String,Any}, tmpdir::String)
  fname = ""
  #Include the strategy code
  if (parsed_args["code"] == nothing)
    fname = parsed_args["file"]
  elseif (parsed_args["file"] == nothing)

    #tf = tempname()


    #open(tf, "w") do f
    (tf, f) = mktemp(tmpdir)
    write(f, "using Raftaar\n")
    write(f, "using TimeSeries\n")

    #replace Base. with empty String
    #disallow explicit use of Base. module
    write(f, replace(parsed_args["code"], "Base.", ""))
    close(f)
    fname = tf
  end

  #When there is serialized data, this is the FIRST step 
  if (parsed_args["serializedData"] != "")
    _deserializeData(parsed_args["serializedData"])
  else
      if (parsed_args["capital"] != nothing)
        setcash(parsed_args["capital"])
      end

      if (parsed_args["universe"] != nothing)

        ss = split(parsed_args["universe"],",")

        nss = length(ss)
        universe = Vector{String}(nss)

        flag = false
        for i = 1:nss
            str = strip(String(ss[i]))

            if(str != "")
                parsed = parse(str)

                if(typeof(parsed) == Int64)
                  adduniverse(parsed)
                elseif (typeof(parsed)==Symbol)
                  adduniverse(str)
                end
            end
        end

      end

      if (parsed_args["investmentplan"] != nothing)
        setinvestmentplan(parsed_args["investmentplan"])
      end

      if (parsed_args["rebalance"] != nothing)
        setrebalance(parsed_args["rebalance"])
      end

      if (parsed_args["cancelpolicy"] != nothing)
        cancelpolicy = parsed_args["cancelpolicy"]
        setcancelpolicy(cancelpolicy)
      end

      if (parsed_args["resolution"] != nothing)
        setresolution(parsed_args["resolution"])
      end

      if (parsed_args["commission"] != nothing)
        ss = split(parsed_args["commission"],',');

        if length(ss)!=2
          Logger.error("""Can't parse the "commission" argument. Need Name,Value type""");
        end

        setcommission((String(ss[1]), parse(ss[2])/100.0))

      end

      if (parsed_args["slippage"] != nothing)
        ss = split(parsed_args["slippage"],',');

        if length(ss)!=2
          Logger.error("""Can't parse the "slippage" argument. Need Name,Value type""");
        end

        setslippage((String(ss[1]), parse(ss[2])/100.0))

      end
  end 

  if (parsed_args["startdate"] != nothing)
      setstartdate(parsed_args["startdate"])
      #, forward_with_serialize_data = (parsed_args["serializedData"] != ""))
  end

  if (parsed_args["enddate"] != nothing)
      setenddate(parsed_args["enddate"])
        #, forward_with_serialize_data = (parsed_args["serializedData"] != ""))
  end

  return fname
end
