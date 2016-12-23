# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using ArgParse
using BufferedStreams
using JSON

function showerror(io::IO, exception::Exception, st::StackTrace)
    Base.showerror(io, exception)
    println(io)
    for sf in st 
        println(io, sf)
    end
end

function handleexception(error::Exception)
    
    out = BufferedOutputStream()
    showerror(out, error, catch_stacktrace())
    str = takebuf_string(out) 
  
    println(str)
    errorlist = Vector{String}()

    ss = split(str,'\n')
    for err in ss      
        if(pattern!="")
            if searchindex(err, pattern) > 0 
                push!(errorlist, String(err))
            end
        else 
            println(err)    
        end
    end

    if length(errorlist) > 1
        Logger.error(errorlist[1]*" "*errorlist[2])
    elseif length(errorlist) == 1 
        Logger.error(errorlist[1])
    else
        Logger.error(String(ss[1]))
    end

    exit(0)

end
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--code"
            help = "strategy code"
            arg_type = String
        "--file"
            help = "file containing strategy code"
            arg_type = String 
        "--capital"
            help = "Starting Capital of the backtest"
            arg_type = Float64
            required = true
        "--startdate", "-s"
            help = "Start date of the backtest"
            arg_type = Date
            default = Date("2016-01-01")
        "--enddate", "-e"
            help = "End date of the backtest"
            arg_type = Date
            default = Date(now())    
        "--universe","-u"
            help = "Static universe for the backtest"
            arg_type = Vector{String}
        "--exclude"
            help = "Exclude from universe"
            arg_type = Vector{String}
        "--investmentplan"
            help = "Flow or investment structure"
            arg_type = String
            default = "AllIn"
        "--rebalance"
            help = "Rebalance frequency of the strategy"
            arg_type = String
            default = "Daily"
        "--cancelpolicy"
            help = "Cancel Policy of the the backtest"
            arg_type = String
            default = "EOD"    
        "--resolution"
            help = "Resolution frequency of the backtest"
            arg_type = String
            default = "Day"
        "--commission"
            help = "Commission Structure of the backtest"
            arg_type = String
            default="PerTrade, 0.1"
        "--slippage"
            help = "Slippage Structure of the backtest"
            arg_type = String
            default = "Variable, 0.05"
    end

    return parse_args(s)
end

parsed_args = ""
try
    parsed_args = parse_commandline()
catch err
    handleexception(err)
end

#Check for parsed arguments
if (parsed_args["code"] == nothing && parsed_args["file"] == nothing)
  println("Atleast one of the code or file arguments should be provided")
  exit(0)
end


#Include the strategy code
if (parsed_args["code"] == nothing)
  include(parsed_args["file"])
elseif (parsed_args["file"] == nothing)
  tf = tempname()
  open(tf, "w") do f
               write(f, parsed_args["code"])
            end
  include(tf)
end

m = JSON.parsefile("/users/shivkumarchawla/Raftaar/Output/datarealtime.json")
k = JSON.parsefile("/users/shivkumarchawla/Raftaar/Output/databacktest.json")

for i = 1:length(m)
    #sleep(0.001)
    JSON.print(m[i])
    println()
end

println()
JSON.print(k)