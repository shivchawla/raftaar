# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#Include the strategy code
pattern = ""

if (parsed_args["code"] == nothing)
  pattern = parsed_args["file"]
  include(parsed_args["file"])
elseif (parsed_args["file"] == nothing)
  open(tf, "w") do f
               write(f, parsed_args["code"])
            end
  pattern = tf
  include(tf)
  
end

if (parsed_args["capital"] != nothing)
  setcash(parsed_args["capital"])
end

if (parsed_args["sdate"] != nothing)
  setstartdate(parsed_args["sdate"])
end

if (parsed_args["edate"] != nothing)
  setstartdate(parsed_args["edate"])
end

if (parsed_args["universe"] != nothing)
  setuniverse(parsed_args["universe"])
end

#=if (parsed_args["sdate"] != nothing)
  setstartdate(parsed_args["sdate"])
end=#

if (parsed_args["investmentplan"] != nothing)
  #setinvestmentplan(parsed_args["investmentplan"])
end

if (parsed_args["rebalance"] != nothing)
  #setrebalance(parsed_args["rebalance"])
end

if (parsed_args["cancelpolicy"] != nothing)
  cancelpolicy = parsed_args["cancelpolicy"]
  if cancelpolicy == "EOD"
    setcancelpolicy(CancelPolicy(EOD))
  elseif cancelpolicy == "GTC"
    setcancelpolicy(CancelPolicy(GTC))  
  end  
end
  
if (parsed_args["resolution"] != nothing)
  #setrebalance(parsed_args["rebalance"])
end

if (parsed_args["commission"] != nothing)
  #setcommission(parsed_args["commission"])
end

if (parsed_args["slippage"] != nothing)
  #setcommission(parsed_args["commission"])
end