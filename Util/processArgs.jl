# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

function processargs(parsed_args::Dict{AbstractString,Any})

  pattern = ""
  #Include the strategy code
  if (parsed_args["code"] == nothing)
    pattern = parsed_args["file"]
    include(parsed_args["file"])
  elseif (parsed_args["file"] == nothing)
    tf=tempname()
    open(tf, "w") do f
                 write(f, parsed_args["code"])
              end
    pattern = tf
    include(tf) 
  end

  if (parsed_args["capital"] != nothing)
    setcash(parsed_args["capital"])
  end

  if (parsed_args["startdate"] != nothing)
    setstartdate(parsed_args["startdate"])
  end

  if (parsed_args["enddate"] != nothing)
    setstartdate(parsed_args["enddate"])
  end

  if (parsed_args["universe"] != nothing)
    setuniverse(parsed_args["universe"])
  end

  if (parsed_args["investmentplan"] != nothing)
    #setinvestmentplan(parsed_args["investmentplan"])
  end

  if (parsed_args["rebalance"] != nothing)
    #setrebalance("Rebalance_"*parsed_args["rebalance"])
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
    
    #eval(parse(ss[1]))
    #println(eval(parse(ss[1])))
    setcommission((String(ss[1]), parse(ss[2])))

  end

  if (parsed_args["slippage"] != nothing)
    ss = split(parsed_args["slippage"],',');
    
    if length(ss)!=2
      Logger.error("""Can't parse the "slippage" argument. Need Name,Value type""");
    end  
    
    setslippage((String(ss[1]), parse(ss[2])))

  end

  return pattern
end

try 
  pattern = processargs(parsed_args)
catch err
  handleexception(err)
end


