# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("../Benchmark/benchmark.jl")

function processargs(parsed_args::Dict{String,Any})
  
  #Include the strategy code
  if (parsed_args["code"] == nothing)
    fname = parsed_args["file"]
  elseif (parsed_args["file"] == nothing)
    parsed_args["code"] = replace(parsed_args["code"], "Base.", "_")
    parsed_args["code"] = replace(parsed_args["code"], "run(", "_run(")
  end

  #When there is serialized data, this is the FIRST step 
  if (parsed_args["serializedData"] != "")
        _deserializeData(parsed_args["serializedData"])
  else

      if (parsed_args["capital"] != nothing)
        setcash(parsed_args["capital"])
      end
      
      benchmark = get(parsed_args, "benchmark", "NIFTY_50")
      if typeof(parse(benchmark)) == Int64
          setbenchmark(parse(benchmark))
      else
          setbenchmark(benchmark)  
      end
      
      universeconstituents = Vector{String}()    
      
      universe = get(parsed_args, "universe", "")
      if (universe!="" && universe!=nothing)
          universeconstituents = [strip(String(ticker)) for ticker in split(universe,",")] 
      end

      if length(universeconstituents) == 0 
          index = get(parsed_args, "index", "Nifty 50")
          index = index != "" && index!=nothing ? index : "Nifty 50"
          setuniverseindex(index)
          universeconstituents = getindexconstituents(index)
      end
     
      n_universeconstituents = length(universeconstituents)
    
      for ticker in universeconstituents
          #str = strip(String(ss[i]))
          if(ticker != "")
              parsed = parse(ticker)

              if(typeof(parsed) == Int64)
                adduniverse(parsed)
              #Handle M&M like symbols (parse resolves to expression)  
              elseif (typeof(parsed)==Symbol || typeof(parsed)==Expr) 
                adduniverse(ticker)
                #replace(ticker, r"[^a-zA-Z0-9]", "_")
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

      if (parsed_args["executionpolicy"] != nothing)
        executionpolicy = parsed_args["executionpolicy"]
        setexecutionpolicy(executionpolicy)
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

end
