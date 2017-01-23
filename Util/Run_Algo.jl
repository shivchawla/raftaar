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

function _getlabels()

  #alldata = history([benchmark], "Close", :Day, 100, enddate = "2016-01-01")
  global alldata = history([API.getbenchmark()], "Close", :Day, startdate = getstartdate(), enddate = getenddate())
  
  alldata = sort(alldata, cols=:Date, rev=false) 
  
  alldates = alldata[:Date]

  labels = Dict{String,Float64}()
  for d in alldates
    labels[d] = 1.0
  end
  
  return labels

end

function run_algo()

  benchmark = "CNX_NIFTY"
  setbenchmark(benchmark)

  try
    initialize(getstate()) 
  catch err
    handleexception(err)
  end

  labels = _getlabels()
   
  outputlabels(labels)  

  startdate = getstartdate()
  enddate = getenddate()

  alldata = history(getuniverse(), "Close", :Day, startdate = getstartdate(), enddate = getenddate())
  
  alldata = sort(alldata, cols = :Date, rev=false)

  i = 1
  for date in sort(collect(keys(labels)))
      mainfnc(date, i, dynamic = false, dataframe = alldata)
      i = i + 1
  end

  _outputbackteststatistics()

end
 
function mainfnc(date::String, counter::Int; dynamic::Bool = true, dataframe::DataFrame = DataFrame())  

  if dynamic
    date = DateTime(date)
    setcurrentdatetime(date)
    updatepricestores(date, fetchprices(date))
  else
    date = DateTime(dataframe[counter,:Date])
    setcurrentdatetime(date)
    updatepricestores(date, dataframe[counter, :])
  end

  ip = getinvestmentplan()
  seedcash = getstate().account.seedcash
  
  if (ip == InvestmentPlan(IP_Weekly) && Dates.dayofweek(date)==1)
      addcash(seedcash)
  elseif (ip == InvestmentPlan(IP_Monthly) && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7)
      addcash(seedcash)
  end

  #println(alldata[i,:CNX_BANK][1])
  
  #If a stock doesn't come with a price?????, liquidate at a last known price.
  #If a stock goes through a split, position and orders are adjusted accordingly.
  #If a stock has a dividend, cash is updated
  #_updateportfoliofordividends()
  #_updatportfolioforsplits()
  
  
  #Update pending orders for splits
  #A 2:1 split causes 100 shares order to go to 200 shares       
  #What if there is a split?
  #What if there is no price and it doesnn't trade anymore?
  
  #_updatependingordersforsplits()
  
  #Internal function to execute pending orders using todays's close

  _updatependingorders()   
  _updateaccountforprice()
  
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




