function _filterTA(ta::TimeArray, date::Date)
  return ta[Date.(TimeSeries.timestamp(ta)) .== date]
end

function _filterTA(ohlcv, date::Date)
    output = Dict{String, TimeArray}()
    
    for (key, value) in ohlcv
      output[key] = value != nothing ? _filterTA(value, date) : nothing
    end
    
    return output
end

function _fetch_EOD_prices(universeIds, startdate::DateTime, enddate::DateTime)
    closeprices_EOD = YRead.history_unadj(universeIds, "Close", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)

    if closeprices_EOD == nothing
      return Dict()
    end

    # println("closeprices_EOD")
    # println(closeprices_EOD)

    openprices_EOD = YRead.history_unadj(universeIds, "Open", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)
    if openprices_EOD == nothing
        #Logger.warn_static("Open Price Data not available from $(startdate) to $(enddate)")
        openprices_EOD = closeprices_EOD
    end

    # println("openprices_EOD")
    # println(openprices_EOD)

    highprices_EOD = YRead.history_unadj(universeIds, "High", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)
    if highprices_EOD == nothing
        #Logger.warn_static("High Price Data not available from $(startdate) to $(enddate)")
        highprices_EOD = closeprices_EOD
    end

    # println("highprices_EOD")
    # println(highprices_EOD)

    lowprices_EOD = YRead.history_unadj(universeIds, "Low", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)
    if lowprices_EOD == nothing
        #Logger.warn_static("Low Price Data not available from $(startdate) to $(enddate)")
        lowprices_EOD = closeprices_EOD
    end

    # println("lowprices_EOD")
    # println(lowprices_EOD)

    vol_EOD = YRead.history_unadj(universeIds, "Volume", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false)      
    
    if vol_EOD == nothing
        Logger.warn_static("No EOD volume data available for any stock in the universe")
    end

    # println("vol_EOD")
    # println(vol_EOD)

    return Dict(
        "Open" => openprices_EOD, 
        "High" => highprices_EOD,
        "Low" => lowprices_EOD,
        "Close" => closeprices_EOD,
        "Volume" => vol_EOD)
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

      ohlcvEOD = _fetch_EOD_prices(universeIds, DateTime(startdate), DateTime(enddate))

      closeprices = get(ohlcvEOD, "Close", nothing)
      if closeprices == nothing
        Logger.warn_static("Close Price EOD Data not available from $(startdate) to $(enddate)")
        Logger.warn_static("Aborting test")
        return false
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

      Logger.info_static("Evaluating ENTRY/EXIT criteria")
      techConds = _evaluate_technical_conditions(forward)
      
      Logger.info_static("Running algorithm for each timestamp")
      success = true

      for (i, date) in enumerate(sort(collect(keys(labels))))
          success = mainfnc(Date(date), ohlcvEOD, adjustments, techConds, forward)
          
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

_getcolnames(ta) = ta != nothing ? colnames(ta) : Symbol[]

function _process_long_entry(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit)
    allPositions = getallpositions()
    universe = getuniverse()

    otherConditionTickers = String.(union(_getcolnames(currentLongExit), _getcolnames(currentShortEntry), _getcolnames(currentShortExit)))

    for ticker in String.(_getcolnames(currentLongEntry))

        if ticker in otherConditionTickers
          Logger.warn_static("Skipping Long Entry!! Conflicting entry/exit condtions for $(ticker)")
          continue
        end

        pos = Position()

        if length(allPositions) > 0
          idx = findall(x -> x.securitysymbol.ticker == ticker, allPositions)
          if length(idx) == 1
            pos = allPositions[idx[1]]
          end
        end

        if (pos.quantity != 0)
          continue
        else
          # println("Setting Long Holding in $(ticker)")
          setholdingpct(ticker, 1/length(universe))
        end
    end
end

function _process_short_entry(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit)
    allPositions = getallpositions()
    universe = getuniverse()

    otherConditionTickers = String.(union(_getcolnames(currentLongEntry), _getcolnames(currentLongExit), _getcolnames(currentShortExit)))

    for ticker in String.(colnames(currentShortEntry))
        
        if ticker in otherConditionTickers
          Logger.warn_static("Skipping Short Entry!! Conflicting entry/exit condtions for $(ticker)")
          continue
        end

        pos = Position()

        if length(allPositions) > 0
          idx = findall(x -> x.securitysymbol.ticker == ticker, allPositions)
          if length(idx) == 1
            pos = allPositions[idx[1]]
          end
        end

        if pos.quantity != 0 
          continue
        else
          # println("Setting Short Holding in $(ticker)")
          setholdingpct(ticker, 1/length(universe))
        end
    end
end

function _process_long_exit(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit)
    allPositions = getallpositions()
    universe = getuniverse()

    otherConditionTickers = String.(union(_getcolnames(currentLongEntry), _getcolnames(currentShortEntry), _getcolnames(currentShortExit)))

    exitedNames = String[]
    for ticker in String.(colnames(currentLongExit))

        if ticker in otherConditionTickers
          Logger.warn_static("Skipping Long Exit!! Conflicting entry/exit condtions for $(ticker)")
          continue
        end

        pos = Position()

        if length(allPositions) > 0
          idx = findall(x -> x.securitysymbol.ticker == ticker, allPositions)
          if length(idx) == 1
            pos = allPositions[idx[1]]
          end
        end

        if pos.quantity <= 0
          continue

        else
          push!(exitedNames, ticker)
          setholdingpct(ticker, 0.0)
        end
    end

    return exitedNames
end

function _process_short_exit(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit)
    allPositions = getallpositions()
    universe = getuniverse()

    otherConditionTickers = String.(union(_getcolnames(currentLongEntry), _getcolnames(currentLongExit), _getcolnames(currentShortEntry)))
    exitedNames = String[]

    for ticker in String.(colnames(currentShortExit))

        if ticker in otherConditionTickers
          Logger.warn_static("Skipping Short Exit!! Conflicting entry/exit condtions for $(ticker)")
          continue
        end
        
        pos = Position()

        if length(allPositions) > 0
          idx = findall(x -> x.securitysymbol.ticker == ticker, allPositions)
          if length(idx) == 1
            pos = allPositions[idx[1]]
          end
        end

        if pos.quantity >= 0
          continue
        else
          push!(exitedNames, ticker)
          setholdingpct(ticker, 0.0)
        end
    end

    return exitedNames
end


function _process_target_stoploss(pos)
    stopLoss = getStopLoss()
    profitTarget = getProfitTarget()

    println("Ticker: $(pos.securitysymbol.ticker)")
    println("Stop Loss: $(stopLoss)")
    println("Profit Target: $(profitTarget)")

    if abs(pos.quantity) > 0
      _chg = pos.averageprice > 0  && pos.lastprice > 0 ? (pos.lastprice - pos.averageprice)/pos.averageprice : 0.0

      chg = pos.quantity > 0 ? _chg : -_chg

      println("Chg: $(chg)")

      if chg <= -stopLoss || chg >= profitTarget
         setholdingpct(pos.securitysymbol.ticker, 0.0)
      end
    end
end

#Find true active conditions: WORKS for only one timestamp
function _findActive(ta) 
  if ta == nothing
    return nothing
  end

  # println(ta)

  vals = values(ta)
  idx = findall(x->x==true, reshape(vals, (length(vals),)))

  if length(idx) == 0
    return nothing
  end

  vs = vals[idx]

  TimeArray(timestamp(ta), reshape(vs , (1, length(vs))), colnames(ta)[idx])

end

function _evaluate_technical_conditions(forward::Bool=false)
  LONGENTRY = nothing
  LONGEXIT = nothing
  SHORTENTRY = nothing
  SHORTEXIT = nothing

  try
  
    API.setparent(:ondata)

    LONGENTRY = longEntryCondition() 
    LONGEXIT = longExitCondition()
    SHORTENTRY = shortEntryCondition() 
    SHORTEXIT = shortExitCondition()

  catch err
    println(err)
    println("Error evaluating technical conditions ")
    handleexception(err, forward)
  end

  return Dict(
      "LONGENTRY" =>  LONGENTRY,
      "LONGEXIT" =>  LONGEXIT,
      "SHORTENTRY" =>  SHORTENTRY,
      "SHORTEXIT" =>  SHORTEXIT
  )

end

function _process_technical_conditions(date::Date, LONGENTRY, LONGEXIT, SHORTENTRY, SHORTEXIT)

    currentLongEntry = _findActive(LONGENTRY != nothing ? LONGENTRY[date] : nothing)
    currentLongExit = _findActive(LONGEXIT != nothing ? LONGEXIT[date] : nothing)
    currentShortEntry = _findActive(SHORTENTRY != nothing ? SHORTENTRY[date] : nothing)
    currentShortExit = _findActive(SHORTEXIT != nothing ? SHORTEXIT[date] : nothing)
    
    #Continue if some of the conditions are valid   
    if currentLongEntry != nothing
      _process_long_entry(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit)
    end

    if currentShortEntry != nothing
      _process_short_entry(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit)
    end

    exitedNames = String[]
    if currentLongExit != nothing
      push!(exitedNames, _process_long_exit(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit))
    end

    if currentShortExit != nothing
      push!(exitedNames, _process_short_exit(currentLongEntry, currentLongExit, currentShortEntry, currentShortExit))
    end

    #Check stopLoss/profitTarget conditions for name not exited already
    allPositions = getallpositions()
    if length(allPositions) == 0
      return 
    else
      for pos in allPositions
        if !(pos.securitysymbol.ticker in exitedNames)
          _process_target_stoploss(pos)
        end
      end
    end
end

function mainfnc(date::Date, ohlcv, adjustments, technicalConds, forward; dynamic::Bool = false)
  
  currentData = Dict{String, TimeArray}()

  setcurrentdate(date)
  
  if dynamic
    #DYNAMIC doesn't work
    updatedatastores(date, fetchprices(date), fetchvolumes(date), YRead.getadjustments())
  else
    setcurrentdate(date)

    currentData = _filterTA(ohlcv, date)
  
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

  _updateaccount_price()

  #Pre-execution state 
  _updatestate()

  #Internal function to update portfolio value using today's close
  #What if there is no price and it doesnn't trade anymore?

  #Internal system already has the close price but not yet visible to the user
  #Internal system fetches prices for all the stocks in the portfolio
  #and for all the stocks with pending orders.

  #beforeclose()

  #once orders are placed and performance is updated based on last know portfolio,
  #call the user defined

  try
    
    Logger.update_display(true)


    LONGENTRY = get(technicalConds, "LONGENTRY", nothing)
    LONGEXIT = get(technicalConds, "LONGEXIT", nothing)
    SHORTENTRY = get(technicalConds, "SHORTENTRY", nothing)
    SHORTEXIT = get(technicalConds, "SHORTEXIT", nothing)

    # println("Long Entry")
    # println(LONGENTRY)

    # println("Long Exit")
    # println(LONGEXIT)

    _process_technical_conditions(date, LONGENTRY, LONGEXIT, SHORTENTRY, SHORTEXIT) 

    if length(getuniverse()) !=0
      ondata(currentData["Close"], getstate())
    end

    API.setparent(:all)
  catch err
    println(err)
    API.setparent(:all)
    handleexception(err, forward)
    return false
  end

  #Internal function to execute pending orders using todays's close
  _updatependingorders_price()
  _updateaccount_price()
 
  #this should only be called once a day in case of high frequency data
  _updatedailyperformance()
  _updatestate()

  if !forward
      Logger.update_display(true)
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
