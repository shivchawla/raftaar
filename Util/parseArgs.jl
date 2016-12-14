# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using ArgParse

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

