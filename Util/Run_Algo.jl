# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#=
Implements the backtester logic
Runs the backtesting logic from the start date to the end date.
Updates the universe with each time stamp, run user defined strategy 
at every time steps and updates portfolio, orders and performance for fills
and latest prices
"""=#

#Logger.info("Starting backtest: "*string(now()))
include("../Util/Run_Helper.jl")


#alldata = history(["CNX_BANK","CNX_100","CNX_ENERGY"], "Close", :Day, 500, enddate = "2016-01-01")
#alldata = history(["CNX_ENERGY"], "Close", :A, 200, enddate = "2016-01-01")
function _init()
  global alldata = history(["CNX_NIFTY","CNX_BANK","CNX_100","CNX_ENERGY"], "Close", :Day, 100, enddate = "2016-01-01")
  
  setstartdate(Date(alldata[:Date][end]))
  setenddate(Date(alldata[:Date][1]))
  setlogmode(:json, true)
  setbenchmark("CNX_NIFTY")
end

function run_algo()

  _init()

  try 
    initialize(getstate()) 
  catch err
    handleexception(err)
  end

  startdate = getstartdate()
  enddate = getenddate()

  global alldata = sort(alldata, cols = :Date, rev=true)

  for i in size(alldata,1):-1:1    
    mainfnc(i)
  end

  _outputbackteststatistics()

end

precompile(run_algo,())


#Logger.info("Backtesting Finished: "*string(now()))

#=catch err
  handleexception(err)
end=#
 



