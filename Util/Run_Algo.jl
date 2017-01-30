# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#include("../Examples/constantpct.jl")
#include("../Util/Run_Helper.jl")

#alldata = history(["CNX_BANK","CNX_100","CNX_ENERGY"], "Close", :Day, 500, enddate = "2016-01-01")
#alldata = history(["CNX_ENERGY"], "Close", :A, 200, enddate = "2016-01-01")

import Logger: warn, info, error

using DataFrames

alldata = DataFrame()

function run_algo()

  benchmark = "CNX_NIFTY"
  setbenchmark(benchmark)

  benchmark = API.getbenchmark()

  #alldata = history([benchmark], "Close", :Day, 100, enddate = "2016-01-01")
  global alldata = history_unadj([benchmark], "Close", :Day, startdate = DateTime(getstartdate()), enddate = DateTime(getenddate()))
  
  try
    initialize(getstate()) 
  catch err
    handleexception(err)
  end
   
  startdate = getstartdate()
  enddate = getenddate()

  cp = history_unadj(getuniverse(), "Close", :Day, startdate = DateTime(getstartdate()), enddate = DateTime(getenddate()))
  vol = sort(history_unadj(getuniverse(), "Volume", :Day, startdate = DateTime(getstartdate()), enddate = DateTime(getenddate())), cols = :Date, rev=false)
  
  #Join benchmark data with close prices
  cp = sort(join(cp, alldata, on = :Date, kind = :outer), cols = :Date, rev=false)

  labels = Dict{String,Float64}()
  
  for i = 1:size(cp)[1]
    val = cp[Symbol(benchmark.ticker)][i]

    j = i-1
    
    while isna(val) && j > 0
      val = cp[Symbol(benchmark.ticker)][j]
      j = j - 1
    end

    val = isna(val) ? 0.0 : val
    
    labels[cp[:Date][i]] = val 
  end

  #Set benchmark value and Output labels from graphs
  setbenchmarkvalues(labels)

  adjs = getadjustments(getuniverse(), DateTime(getstartdate()), DateTime(getenddate()))

  #continue with backtest if there are any rows in price data.
  if(size(cp)[1]>0)
    outputlabels(labels)  
  else
    return
  end

  i = 1
  for date in sort(collect(keys(labels)))
      mainfnc(date, i, dynamic = false, close = cp, volume = vol, adjustments = adjs)
      i = i + 1
  end

  _outputbackteststatistics()

end
 
function mainfnc(date::String, counter::Int; dynamic::Bool = true, close::DataFrame = DataFrame(), volume::DataFrame = DataFrame(), adjustments = Dict())  

  if dynamic
    date = Date(date)
    setcurrentdate(date)

    #DYNAMIC doesn't work
    updatedatastores(date, fetchprices(date), fetchvolumes(date), getadjustments())
  else 
    date = Date(close[counter,:Date])

    setcurrentdate(date)

    # check if volume dataframe has same rows as close OR if it has row
    nrows_volume = size(volume)[1]
    currentvolume = nrows_volume > counter ? volume[counter, :] : DataFrame()

    nrows_close = size(close)[1]
    currentprices = nrows_close > counter ? close[counter, :] : DataFrame()

    updatedatastores(date, currentprices, currentvolume, adjustments)
  end

  ip = getinvestmentplan()
  seedcash = getstate().account.seedcash
  
  if (ip == InvestmentPlan(IP_Weekly) && Dates.dayofweek(date)==1)
      addcash(seedcash)
  elseif (ip == InvestmentPlan(IP_Monthly) && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7)
      addcash(seedcash)
  end

  _updateaccount_splits_dividends()
  
  _updatependingorders_splits()
  
  #Internal function to execute pending orders using todays's close

  _updatependingorders_price()   
  _updateaccount_price()
  
  #Internal function to update portfolio value using today's close
  #What if there is no price and it doesnn't trade anymore?

  #Internal system already has the close price but not yet visible to the user
  #Internal system fetches prices for all the stocks in the portfolio 
  #and for all the stocks with pending orders.

  #beforeclose()

  #this should only be called once a day in case of high frequency data
  _updatedailyperformance()
  _updatestate() 

  #once orders are placed and performance is updated based on last know portfolio,
  #call the user defined
  
  try 
    ondata(alldata, getstate())
  catch err
    handleexception(err)
  end

  _outputdailyperformance() 

  #this is called every data stamp, user can 
  # user defines this functions where he sets universe, 
  #creates new orders for the next session 
  #(give option to trading at open/close/or worst price)
  #Internal system checks policy for stocks not in universe
  #If liquidation is set to true, add additional pending orders of liquidation

end




