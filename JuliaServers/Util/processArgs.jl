# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

const tempDir = "$(ENV["HOME"])/raftaar/tmp"

function processargs(parsed_args::Dict{String,Any})
  
  fname = nothing

  #Include the strategy code
  if (parsed_args["code"] == nothing)
    fname = parsed_args["file"]
  elseif (parsed_args["file"] == nothing)
    
    #Added security features (to prevent malicious code)
    #System related code leads to warning
    #Exit/Run/Eval/Filesystem/quit not allowed
    parsed_args["code"] = replace(parsed_args["code"], "Base." => "_")
    parsed_args["code"] = replace(parsed_args["code"], "run(" => "_run(") 
    parsed_args["code"] = replace(parsed_args["code"], "exit(" => "_exit(") 
    parsed_args["code"] = replace(parsed_args["code"], "quit(" => "_quit(") 
    parsed_args["code"] = replace(parsed_args["code"], "eval(" => "_eval(")

    parsed_args["code"] = replace(parsed_args["code"], "Filesystem" => "_")

    (tf, io) = mktemp(tempDir)

    open(tf, "w") do f
      write(f, parsed_args["code"])
    end

    fname = tf 

  end

  #When there is serialized data, this is the FIRST step 
  if (parsed_args["serializedData"] != "")
        _deserializeData(parsed_args["serializedData"])
  else

      if (parsed_args["capital"] != nothing)
        setcash(parsed_args["capital"])
      end
      
      benchmark = get(parsed_args, "benchmark", "NIFTY_50")
      setbenchmark(benchmark)  

      if (parsed_args["resolution"] != nothing)
        setresolution(parsed_args["resolution"])
      end

      universeconstituents = Vector{String}()    
      
      universe = get(parsed_args, "universe", "")
      if (universe!="" && universe!=nothing)
          universeconstituents = [String(strip(ticker)) for ticker in split(universe,",")] 
      end

      if length(universeconstituents) == 0 
          index = get(parsed_args, "index", "Nifty 50")
          index = index != "" && index!=nothing ? index : "Nifty 50"
          setuniverseindex(index)
          universeconstituents = getBenchmarkConstituents(index)
      end
     
      n_universeconstituents = length(universeconstituents)
        
      MAX_CONSTITUENTS = getresolution() == Resolution_Day ? 50 : 20
      #Trim to a max of 20 ticker
      #Add more for professional users (paid) -- LATER (when max as limit)
      universeconstituents = universeconstituents[1:min(MAX_CONSTITUENTS, n_universeconstituents)]
      setuniverse(universeconstituents)

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

      if (parsed_args["executionpolicy"] != nothing)
        executionpolicy = parsed_args["executionpolicy"]
        setexecutionpolicy(executionpolicy)
      end

      
      if (parsed_args["commission"] != nothing)
        ss = split(parsed_args["commission"],',');

        if length(ss)!=2
          Logger.error("""Can't parse the "commission" argument. Need Name,Value type""");
        end

        setcommission((String(ss[1]), Meta.parse(ss[2])/100.0))

      end

      if (parsed_args["slippage"] != nothing)
        ss = split(parsed_args["slippage"],',');

        if length(ss)!=2
          Logger.error("""Can't parse the "slippage" argument. Need Name,Value type""");
        end

        setslippage((String(ss[1]), Meta.parse(ss[2])/100.0))

      end
      
      if (parsed_args["stopLoss"] != nothing)
        println("Setting stop loss")
        setStopLoss(parsed_args["stopLoss"]/100.0)
      end

      if (parsed_args["profitTarget"] != nothing)
        println("Setting progit target")
        setProfitTarget(parsed_args["profitTarget"]/100.0)
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
