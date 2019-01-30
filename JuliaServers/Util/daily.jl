function __toPricesTA(prices, date)
  currentprices = nothing
  try
    currentprices = prices[date]
  catch err
  end

  if (currentprices == nothing)
    #Logger.warn("Price Data is missing")
    names = push!([d.symbol.ticker for d in getuniverse(validprice=false)], API.getbenchmark().ticker)
    currentprices = TimeArray([date], zeros(1, length(names)), names)
  end

  return currentprices
end

function __toVolumeTA(volume, date)
  try
    currentvolume = volume[date]
  catch err
  end

  if (currentvolume == nothing)
    #Logger.warn("Volume data is missing")
    #Logger.warn("Assuming default volume of 10mn")
    names = push!([d.symbol.ticker for d in getuniverse(validprice=false)], API.getbenchmark().ticker)
    currentvolume = TimeArray([date], zeros(1, length(names)), names)
  end

  return currentvolume
end


function _run_algo_day(startdate::Date = getstartdate(), enddate::Date = getenddate(), forward::Bool = false) 
    try
      Logger.info_static("Fetching data")
      setcurrentdate(getstartdate())

      # The parameters start_date and end_date here represent the datesfor which I want to run the simulation
      # In case of backtest, they're by default set to the ones provided as external parameters or from initialize function
      # In case of forward test, they are just one single day
      benchmark = API.getbenchmark()

      #Let's download new data now
      benchmarkdata = YRead.history_unadj([benchmark.id], "Close", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false, strict = false)

      if benchmarkdata == nothing
          Logger.warn_static("Benchmark data not available from $(startdate) to $(enddate)")
          Logger.warn_static("Aborting test")
          return false
      end

      # Get all ids for stocks in universe 
      universeIds = [security.symbol.id  for security in getuniverse(validprice=false)]

      if(length(universeIds) == 0) 
          Logger.error("Empty Universe")
          return false
      end

      closeprices = YRead.history_unadj(universeIds, "Close", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)
      if closeprices == nothing
          Logger.warn_static("Close Price Data not available from $(startdate) to $(enddate)")
          Logger.warn_static("Aborting test")
          return false
      end

      openprices = YRead.history_unadj(universeIds, "Open", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)
      if openprices == nothing
          #Logger.warn_static("Open Price Data not available from $(startdate) to $(enddate)")
          openprices = closeprices
      end

      highprices = YRead.history_unadj(universeIds, "High", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)
      if highprices == nothing
          #Logger.warn_static("High Price Data not available from $(startdate) to $(enddate)")
          highprices = closeprices
      end

      lowprices = YRead.history_unadj(universeIds, "Low", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)
      if lowprices == nothing
          #Logger.warn_static("Low Price Data not available from $(startdate) to $(enddate)")
          lowprices = closeprices
      end

      vol = YRead.history_unadj(universeIds, "Volume", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)      
      if vol == nothing
          Logger.warn_static("No volume data available for any stock in the universe")
      end

      #Join benchmark data with close prices
      #Right join (benchmark data comes from NSE database and excludes the holidays)
      closeprices = !isempty(closeprices) && !isempty(benchmarkdata) ? merge(closeprices, benchmarkdata, :right) : closeprices
      labels = Dict{String,Float64}()

      bvals = values(closeprices[Symbol(benchmark.ticker)])

      for (i, dt) in enumerate(TimeSeries.timestamp(closeprices))
        val = bvals[i]

        j = i-1

        while isnan(val) && j > 0
          val = bvals[j]
          j = j - 1
        end

        val = isnan(val) ? 0.0 : val

        labels[string(dt)] = val
      end

      # Global data stores
      #Get Adjusted history once for the full universe (from start to end date)
      #THis will be used for any history calls in user algorithm
      #allsecurities_includingbenchmark = push!(universeIds, benchmark.id)
      #adjustedcloseprices = YRead.history(allsecurities_includingbenchmark, "Close", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)

      #Set benchmark value and Output labels from graphs
      setbenchmarkvalues(labels)

      adjustments = YRead.getadjustments(universeIds, DateTime(startdate), DateTime(enddate), displaylogs = false)

      #continue with backtest if there are any rows in price data.
      if !isempty(closeprices)
        outputlabels(labels)
      else
        Logger.error_static("No price data found. Aborting Backtest!!!")
        return
      end

      Logger.info_static("Running algorithm for each timestamp")
      success = true
      for (i, date) in enumerate(sort(collect(keys(labels))))
          success = mainfnc(Date(date), i, openprices, highprices, lowprices, closeprices, vol, adjustments, forward)
          
          if(!success)
              break
          end
      end

      if success
          Logger.info_static("Ending Backtest")
      end

      if !forward
        _outputbackteststatistics()
      end
      
      return true
    
    catch err
      println(err)
      API.error("Internal Exception")
    end
end

function mainfnc(date::Date, counter::Int, open, high, low, close, volume, adjustments, forward; dynamic::Bool = false)
  
  currentData = Dict{String, TimeArray}()

  setcurrentdate(date)
  
  if dynamic
    #DYNAMIC doesn't work
    updatedatastores(date, fetchprices(date), fetchvolumes(date), YRead.getadjustments())
  else
    setcurrentdate(date)

    currentData["Open"] = __toPricesTA(open, date)
    currentData["High"] = __toPricesTA(high, date)
    currentData["Low"] = __toPricesTA(low, date)
    currentData["Close"] = __toPricesTA(close, date)
    currentData["Volume"] = __toVolumeTA(volume, date)

    updatedatastores(DateTime(date), currentData, adjustments)
  end

  ip = getinvestmentplan()
  seedcash = getstate().account.seedcash

  if ip == IP_Weekly && Dates.dayofweek(date)==1
      addcash(seedcash)
  elseif ip == IP_Monthly && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7
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
    API.setparent(:ondata)

    if length(getuniverse()) !=0
      ondata(currentData["Close"], getstate())
    end
    API.setparent(:all)
  catch err
    API.setparent(:all)
    handleexception(err, forward)
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