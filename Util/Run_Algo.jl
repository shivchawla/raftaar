# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#include("../Examples/constantpct.jl")
#include("../Util/Run_Helper.jl")

#alldata = history(["CNX_BANK","CNX_100","CNX_ENERGY"], "Close", :Day, 500, enddate = "2016-01-01")
#alldata = history(["CNX_ENERGY"], "Close", :A, 200, enddate = "2016-01-01")

# import Logger: warn, info, error

using DataFrames
using TimeSeries
using Logger

function run_algo(forward_test::Bool = false)

  benchmark = "CNX_NIFTY"
  setbenchmark(benchmark)

  setcurrentdate(getstartdate())

  if forward_test
    # we're doing a forward test
    # Let's check if we have already saved data or not

    if !wasDataFound()
      # Oh no, no data found
      # let's call the initialize function
      try
        initialize(getstate())
      catch err
        handleexception(err)
        return
      end

      if _run_algo_internal(forward = forward_test)
          _serializeData()
      end
    else
      # Aww yeah, data found
      # just set the start date from where you want to continue the forward testing
      # and let the fun begin

      # Start simulation for the "next" day where simulation ended
      # start_date = getenddate() + Base.Dates.Day(1)
      # end_date = getenddate() + Base.Dates.Day(1)

      # The following dates are the dates for which the simuation will run
      #start_date = getrunstartdate()
      #end_date = getrunenddate()
      _run_algo_internal(forward = forward_test)

      # Even if the simuation returned nothing (in case of missing security data)
      # we would like to reflect the end date for which the simuation ran
      # and then pass the previously serialized data itself
      # because this code region means, we already had some deserialized data to begin with
      
      #setenddate(end_date)
      _serializeData()
    end

    #=if _run_algo_internal(start_date, end_date)
      # Don't forget that we were running a forward test
      # that is we need to serialize everything back into database
      _serializeData()

    end=#
  else
    # this means we are doing a backtest
    # nothing much to do here except for calling initialize

    try
      initialize(getstate())
    catch err
      handleexception(err)
      return
    end

    _run_algo_internal()

  end
end

function _run_algo_internal(start_date::Date = getstartdate(), end_date::Date = getenddate(); forward = false)
  
  setcurrentdate(getstartdate())

  # The parameters start_date and end_date here represent the datesfor which I want to run the simulation
  # In case of backtest, they're by default set to the ones provided as external parameters or from initialize function
  # In case of forward test, they are just one single day
  benchmark = API.getbenchmark()

  # Let's download new data now

  #alldata = history([benchmark], "Close", :Day, 100, enddate = "2016-01-01")
  alldata = history_unadj([benchmark], "Close", :Day, startdate = DateTime(start_date), enddate = DateTime(end_date))

  if alldata == nothing
      return false
  end

  cp = history_unadj(getuniverse(), "Close", :Day, startdate = DateTime(start_date), enddate = DateTime(end_date))

  if cp == nothing
      return false
  end

  vol = history_unadj(getuniverse(), "Volume", :Day, startdate = DateTime(start_date), enddate = DateTime(end_date))

  if vol == nothing
      return false
  end

  #Join benchmark data with close prices
  cp = !isempty(cp) && !isempty(alldata) ? merge(cp, alldata, :outer) : cp
  labels = Dict{String,Float64}()

  bvals = values(cp[benchmark.ticker])

  for i = 1:length(cp)
    val = bvals[i]

    j = i-1

    while isnan(val) && j > 0
      val = bvals[j]
      j = j - 1
    end

    val = isnan(val) ? 0.0 : val

    labels[string(cp.timestamp[i])] = val
  end

  # Global data stores
  allsecurities_includingbenchmark = push!([d.symbol for d in getuniverse()], API.getbenchmark())
  adjustedprices = history(allsecurities_includingbenchmark, "Close", :Day, startdate = DateTime(start_date), enddate = DateTime(end_date))

  #Set benchmark value and Output labels from graphs
  setbenchmarkvalues(labels)
  adjustments = getadjustments(getuniverse(), DateTime(start_date), DateTime(end_date))

  #continue with backtest if there are any rows in price data.
  if !isempty(cp)
    outputlabels(labels)
  else
    error("No price data found. Aborting Backtest!!!")
    return
  end

  i = 1

  success = true
  for date in sort(collect(keys(labels)))
      success = mainfnc(Date(date), i, cp, vol, adjustments, forward, dynamic = false)
      
      if(!success)
          break
      end
      i = i + 1
  end

  _updatelogtracker()

  if !forward
    _outputbackteststatistics()
  end
  
  return true
end

function mainfnc(date::Date, counter::Int, close, volume, adjustments, forward; dynamic::Bool = true)
  
  setcurrentdate(date)
  if dynamic
    #DYNAMIC doesn't work
    updatedatastores(date, fetchprices(date), fetchvolumes(date), getadjustments())
  else
    setcurrentdate(date)

    # check if volume dataframe has same rows as close OR if it has row
    #nrows_volume = length(volume)
    #currentvolume = nrows_volume > counter ? volume[date] : DataFrame()

    currentvolume = nothing
    try
      currentvolume = volume[date]
    end

    if (currentvolume == nothing)
      names = push!([d.symbol.ticker for d in getuniverse()], API.getbenchmark().ticker)
      currentvolume = TimeArray([date], 10000000.*ones(1, length(names)), names)
    end

    currentprices = nothing
    try
      currentprices = close[date]
    end

    if (currentprices == nothing)
      names = push!([d.symbol.ticker for d in getuniverse()], API.getbenchmark().ticker)
      currentprices = TimeArray([date], zeros(1, length(names)), names)
    end

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
    ondata(currentprices, getstate())
  catch err
    handleexception(err)
    return false
  end

  if !forward
    _outputdailyperformance()
  end

  return true

  #this is called every data stamp, user can
  # user defines this functions where he sets universe,
  #creates new orders for the next session
  #(give option to trading at open/close/or worst price)
  #Internal system checks policy for stocks not in universe
  #If liquidation is set to true, add additional pending orders of liquidation

end
