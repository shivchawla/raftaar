# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using ArgParse
using Dates

function ArgParse.parse_item(::Type{Date}, x::AbstractString)
    return Date(x)
end

function getargparsesettings()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--backtestid"
            help = "Backtest Id"
            arg_type = String
            default = ""
        "--code"
            help = "strategy code"
            arg_type = String
        "--file"
            help = "file containing strategy code"
            arg_type = String
        "--capital"
            help = "Starting Capital of the backtest"
            arg_type = Float64
            default = 1000000.0
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
            arg_type = String
        "--index", "-i"
            help = "Universe Index for the backtest"
            arg_type = String
        "--benchmark","-b"
            help = "Benchmark Index for the backtest"
            arg_type = String
            default="NIFTY_50"
        "--exclude"
            help = "Exclude from universe"
            arg_type = String
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
        "--executionpolicy"
            help = "Execution Policy of the the backtest (Time of execution)"
            arg_type = String
            default = "Close"    
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
        "--profitTarget"
            help = "Profit target for trade"
            arg_type = Float64
            default = 5.0
        "--stopLoss"
            help = "Stop loss for trade"
            arg_type = Float64
            default = 5.0
        "--forward"
            help = "Enable forward testing"
            arg_type = Bool
            default = false
        "--serializedData"
            help = "Serialized data for forward testing"
            arg_type = String
            default = ""
    end

    return s
end

function parse_commandline()
    s = getargparsesettings()
    return parse_args(s)
end

function parse_arguments(args)
    s = getargparsesettings()
    return parse_args(args, s)
end
