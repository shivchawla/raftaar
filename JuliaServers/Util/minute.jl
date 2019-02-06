using TechnicalAPI

function _filterConditionsForDate(LONGENTRY, LONGEXIT, SHORTENTRY, SHORTEXIT, date::Date)
    Dict(
        "LONGENTRY" => (LONGENTRY != nothing ? filter(LONGENTRY, date) : nothing), 
        "LONGEXIT" => (LONGEXIT != nothing ? filter(LONGEXIT, date) : nothing), 
        "SHORTENTRY" => (SHORTENTRY != nothing ? filter(SHORTENTRY, date) : nothing), 
        "SHORTEXIT" => (SHORTEXIT != nothing ? filter(SHORTEXIT, date) : nothing)
    ) 
end

function _computeTradeTimePerTicker(ticker, entryTA, exitTA, prices, direction::String, stopLoss::Float64, profitTarget::Float64)
  allPos = getallpositions()

  pos = Position()

  if length(allPos) > 0
    idx = findall(x -> x.securitysymbol.ticker == ticker, allPos)
    if length(idx) == 1
      pos = allPos[idx[1]]
    end
  end

  highprices = get(prices, "High", nothing)
  lowprices = get(prices, "Low", nothing)
  closeprices = get(prices, "Close", nothing)
  openprices = get(prices, "Open", nothing)

  if highprices == nothing  || lowprices == nothing || closeprices == nothing || openprices == nothing
      println("Invalid intraday prices. Aborting")
      return []
  end

  qty = pos.quantity > 0 ? 1 : pos.quantity < 0 ? -1 : 0;
  
  tradeDates = []

  allEntryDates = [] 
  allExitDates = [] 

  if entryTA != nothing
    entryTA = entryTA[entryTA .== true]
    allEntryDates = TimeSeries.timestamp(entryTA) 
  end
  
  if exitTA != nothing
    exitTA = exitTA[exitTA .== true]
    allExitDates = TimeSeries.timestamp(exitTA)
  end

  entryDate = nothing
  entryPrice = nothing
  exitDate = nothing
  stopLossPrice = nothing
  profitTargetPrice = nothing

  # println("OK-1")
  # println("allEntryDates: $(length(allEntryDates))")
  # println("allExitDates: $(length(allExitDates))")
  # println("Direction: $(direction)")
  # println("Qty: $(qty)")


  while length(allEntryDates) > 0 || length(allExitDates) > 0  
    if qty > 0 && length(allExitDates) > 0 && direction == "LONG" 
        exitDate = allExitDates[1]
        push!(tradeDates, (ticker, exitDate, "LONGEXIT"))

        allEntryDates = allEntryDates[allEntryDates .> exitDate]
        allExitDates = allExitDates[allExitDates .> exitDate]
        
        # println("OK-2")
        qty = 0

    elseif qty < 0 && length(allExitDates) > 0 && direction == "SHORT" 
        exitDate = allExitDates[1]
        push!(tradeDates, (ticker, exitDate, "SHORTEXIT"))
        
        allEntryDates = allEntryDates[allEntryDates .> exitDate]
        allExitDates = allExitDates[allExitDates .> exitDate]
        
        qty = 0

        # println("OK-3")

    elseif qty <= 0 && length(allEntryDates) > 0 && direction == "LONG"
        entryDate = allEntryDates[1]
        allEntryDates = allEntryDates[allEntryDates .> entryDate]
        allExitDates = allExitDates[allExitDates .> entryDate]

        #Find entry price
        try
          entryPrice = nothing
          entryPrice = values(openprices[TimeSeries.timestamp(openprices) .> entryDate])[1]
        catch err
        end

        if entryPrice != nothing
          push!(tradeDates, (ticker, entryDate, "LONGENTRY"))

          qty = 1

          profitTargetPrice = (1 + profitTarget)*entryPrice
          stopLossPrice = (1 - stopLoss)*entryPrice

          highPriceTs = TimeSeries.timestamp(highprices)
          lowPriceTs = TimeSeries.timestamp(lowprices)

          profitTargetDates = length(allExitDates) > 0 ? 
              highPriceTs[
                 (highPriceTs .> entryDate) .& #1
                 (TimeSeries.values(highprices) .>= profitTargetPrice)  .& #2
                 (highPriceTs .< allExitDates[1])] :

              highPriceTs[
                 (highPriceTs .> entryDate) .& #1
                 (TimeSeries.values(highprices) .>= profitTargetPrice)]
          
          stopLossDates = length(allExitDates) > 0 ? 
              lowPriceTs[
                 (lowPriceTs .> entryDate) .& #1
                 (TimeSeries.values(lowprices) .<= stopLossPrice)  .& #2
                 (lowPriceTs .< allExitDates[1])] : 
                 
              lowPriceTs[(lowPriceTs .> entryDate) .& #1
                 (TimeSeries.values(lowprices) .<= stopLossPrice)]

          #append the profit/loss dates to possible exit dates
          allExitDates = unique([allExitDates; profitTargetDates; stopLossDates])
          # println("OK-4")
        end
     
    elseif qty >= 0 && length(allEntryDates) > 0 && direction == "SHORT"
        
        entryDate = allEntryDates[1]
        #First set of conditional date for exit (doesn't include PT/SL)
        allExitDates = allExitDates[allExitDates .> entryDate]
        allEntryDates = allEntryDates[allEntryDates .> entryDate]

        #Find entry price
        try
          entryPrice = nothing
          entryPrice = values(t[TimeSeries.timestamp(openprices) .> entryDate])[1]
        catch err
        end

        if entryPrice != nothing
          push!(tradeDates, (ticker, entryDate, "SHORTENTRY"))
          qty = -1  

          profitTargetPrice = (1 - profitTarget)*entryPrice
          stopLossPrice = (1 + stopLoss)*entryPrice

          highPriceTs = TimeSeries.timestamp(highprices)
          lowPriceTs = TimeSeries.timestamp(lowprices)

          profitTargetDates = length(allExitDates) > 0 ? 
              lowPriceTs[
                   (lowPriceTs .> entryDate) .& #1
                   (TimeSeries.values(lowprices) .<= profitTargetPrice)  .& #2
                   (lowPriceTs .< allExitDates[1])] :

              lowPriceTs[
                   (lowPriceTs .> entryDate) .& #1
                   (TimeSeries.values(lowprices) .<= profitTargetPrice)]

            
          stopLossDates = length(allExitDates) > 0 ? 
              highPriceTs[
                   (highPriceTs .> entryDate) .& #1
                   (TimeSeries.values(highprices) .>= stopLossPrice)  .& #2
                   (highPriceTs .< allExitDates[1])] :

              highPriceTs[
                   (highPriceTs .> entryDate) .& #1
                   (TimeSeries.values(highprices) .>= stopLossPrice)]

          #append the profit/loss dates to possible exit dates
          allExitDates = unique([allExitDates; profitTargetDates; stopLossDates])

          # println("OK-5")
        end
    end

    #Refresh allLongEntryDate and allLongExitDates

    #NextEntryDate is after the FIRST EXIT DATE (if position is non-zero)
    try
      allEntryDates = length(allEntryDates) == 0 ? [] : 
            abs(qty) > 0 && length(allExitDates) > 0 ? 
                allEntryDates[allEntryDates .> allExitDates[1]] :
            qty == 0  ? allEntryDates : []
    catch err
      println("Error in long entry dates")
      println(err)
    end
    # println("OK-6")

    #NextExitDate is after the FIRST ENTRY DATE (if position is zero)
    try
      allExitDates = length(allExitDates) == 0 ? [] : 
          qty == 0 && length(allEntryDates) > 0 ? 
              allExitDates[allExitDates .> allEntryDates[1]] :
          abs(qty) > 0  ? allExitDates : [] 
    catch err
      println("Error in long exit dates")
      println(err)
    end

  end #While ends

  return tradeDates
end

function _computeTradeTimes(date::Date, ENTRY, EXIT, prices;direction::String = "LONG", stopLoss::Float64 = 0.05, profitTarget::Float64 = 0.05)
  
  # println("In Every Minute")
  entryNames = ENTRY != nothing ? colnames(ENTRY) : Symbol[]
  exitNames = EXIT != nothing ? colnames(EXIT) : Symbol[]

  allTradingMinutes = []
  for name in unique([entryNames; exitNames])
    pricesThisTicker = Dict(k => v[name] for (k,v) in prices)

    entryForDate = name in entryNames ? ENTRY[name] : nothing
    # entryForDate = entryForDate != nothing ? entryForDate[Date.(timestamp(entryForDate)) .== date] : nothing

    exitForDate = name in exitNames ? EXIT[name] : nothing
    # exitForDate = exitForDate != nothing ? exitForDate[Date.(timestamp(exitForDate)) .== date] : nothing

    allTradingMinutes = [allTradingMinutes; _computeTradeTimePerTicker(String(name), entryForDate, exitForDate, pricesThisTicker, direction, stopLoss, profitTarget)]
  end

  return allTradingMinutes
end

function _after_start(date::Date, eodPrices, adjustments, forward; dynamic::Bool = false)
  
  # println("Initial State")
  # println(getstate())

  ip = getinvestmentplan()
  seedcash = getstate().account.seedcash

  if ip == IP_Weekly && Dates.dayofweek(date)==1
      addcash(seedcash)
  elseif ip == IP_Monthly && Dates.dayofweek(date)==1 && Dates.dayofmonth(date)<=7
      addcash(seedcash)
  end

  #UPDATE EOD DATASTORES -- *******THIS SHOULD BE FIRST DATA POINT FROM MINUTE DATA (FIX IT !!)******
  if dynamic
    #DYNAMIC doesn't work
    updatedatastores(DateTime(date), fetchprices(date), fetchvolumes(date), YRead.getadjustments())
  else
    updatedatastores(DateTime(date), eodPrices, adjustments)
  end

  _updateaccount_splits_dividends()
  _updatependingorders_splits()
end

function _before_close(date::Date, eodPrices, adjustments, forward; dynamic::Bool = false)
  
  #UPDATE EOD DATASTORES
  if dynamic
    #DYNAMIC doesn't work
    updatedatastores(DateTime(date), fetchprices(date), fetchvolumes(date), YRead.getadjustments())
  else
    updatedatastores(DateTime(date), eodPrices, adjustments)
  end

  #Internal function to update account value/pnl with latest price
  _updateaccount_price()

  #this should only be called once a day in case of high frequency data
  _updatedailyperformance()
  _updatestate()

  # println("NEW STATE")
  # println(getstate())

  try
    API.setparent(:ondata)

    if length(getuniverse()) !=0
      ondata(eodPrices["Close"], getstate())
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

  #this is called every data stamp, user can
  # user defines this functions where he sets universe,
  #creates new orders for the next session
  #(give option to trading at open/close/or worst price)
  #Internal system checks policy for stocks not in universe
  #If liquidation is set to true, add additional pending orders of liquidation
end

function _process_conditions(date::Date, prices, conditions, options, forward; dynamic::Bool = false)
  
  # println("In Minute Main Function")
  allMinuteDataForDate = prices

  LONGENTRY = get(conditions, "LONGENTRY", nothing)
  LONGEXIT = get(conditions, "LONGEXIT", nothing)

  SHORTENTRY = get(conditions, "SHORTENTRY", nothing)
  SHORTEXIT = get(conditions, "SHORTEXIT", nothing)

  stopLoss = get(options, "stopLoss", 0.05)
  profitTarget = get(options, "profitTarget", 0.05)

  # println("Long Trade Times")
  longTradeTimes = _computeTradeTimes(date, LONGENTRY, LONGEXIT, prices, direction = "LONG", stopLoss = stopLoss, profitTarget = profitTarget)
  
  # println("Short Trade Times")
  shortTradeTimes = _computeTradeTimes(date, SHORTENTRY, SHORTEXIT, prices, direction = "SHORT", stopLoss = stopLoss, profitTarget = profitTarget)

  allTradeTimes = sort([longTradeTimes; shortTradeTimes], by=x->x[2])

  # println("After Trade Times")
  # println("Placing orders")
  for (name, dt, direction) in allTradeTimes

      currentMinuteData = Dict{String, TimeArray}()
      for (k,v) in allMinuteDataForDate
        currentMinuteData[k] = v[TimeSeries.timestamp(v) .== dt]
      end  
        

      # println("Update Date Stores")
      # println("DateTime: $(dt)")
      # println(currentMinuteData)
      

      #println("Updating data stores")
      updatedatastores(dt, currentMinuteData, Dict{SecuritySymbol, Adjustment}())
        


      # println("Placing orders")

      # println("Name: $(name)")
      # println("DateTime: $(dt)")
      # println("Condition: $(direction)")

      #After updating the data, process longEntry/longExit conditions
      pct = 1/length(getuniverse())
      if direction == "LONGENTRY"
        setholdingpct(name, pct)
      elseif direction == "SHORTENTRY"
        setholdingpct(name, -pct)
      elseif direction == "LONGEXIT" || direction == "SHORTEXIT"
        setholdingpct(name, 0.0)
      end 

      #println("Evaluating pending orders")
      
      #Internal function to execute pending orders using latest price
      _updatependingorders_price()

      # println("All Positions after order")
      # println(getallpositions())

      # println("Account after order")
      # println(getaccount())

  end

  return true
end

function _fetch_minute_prices(universeIds, startdate::DateTime, enddate::DateTime)
    closeprices = YRead.history(universeIds, "Close", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    # println("closeprices_minute")
    # println(closeprices)

    openprices = YRead.history(universeIds, "Open", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    if openprices == nothing
        #Logger.warn_static("Open Price Data not available from $(startdate) to $(enddate)")
        openprices = closeprices
    end

    # println("openprices_minute")
    # println(openprices)
 

    highprices = YRead.history(universeIds, "High", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    if highprices == nothing
        #Logger.warn_static("High Price Data not available from $(startdate) to $(enddate)")
        highprices = closeprices
    end

    # println("highprices_minute")
    # println(highprices)
 

    lowprices = YRead.history(universeIds, "Low", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    if lowprices == nothing
        #Logger.warn_static("Low Price Data not available from $(startdate) to $(enddate)")
        lowprices = closeprices
    end

    # println("lowprices_minute")
    # println(lowprices)
 
    vol = YRead.history(universeIds, "Volume", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)      
    
    if vol == nothing
        Logger.warn_static("No volume data available for any stock in the universe")
    end

    # println("vol_minute")
    # println(vol)

    closeprices_unadj = YRead.history_unadj(universeIds, "Close", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    if closeprices_unadj == nothing
        Logger.warn_static("Close Price Data not available from $(startdate) to $(enddate)")
        Logger.warn_static("Aborting test")
        return false
    end

    # println("closeprices_minute")
    # println(closeprices)

    openprices_unadj = YRead.history_unadj(universeIds, "Open", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    if openprices_unadj == nothing
        #Logger.warn_static("Open Price Data not available from $(startdate) to $(enddate)")
        openprices_unadj = closeprices_unadj
    end

    # println("openprices_minute")
    # println(openprices)
 

    highprices_unadj = YRead.history_unadj(universeIds, "High", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    if highprices_unadj == nothing
        #Logger.warn_static("High Price Data not available from $(startdate) to $(enddate)")
        highprices_unadj = closeprices_unadj
    end

    # println("highprices_minute")
    # println(highprices_unadj)
 

    lowprices_unadj = YRead.history_unadj(universeIds, "Low", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)
    if lowprices_unadj == nothing
        #Logger.warn_static("Low Price Data not available from $(startdate) to $(enddate)")
        lowprices_unadj = closeprices_unadj
    end

    # println("lowprices_minute")
    # println(lowprices_unadj)
 
    vol_unadj = YRead.history_unadj(universeIds, "Volume", Symbol("1m"), DateTime(startdate) - Dates.Month(1), DateTime(enddate), displaylogs = false)      
    
    if vol_unadj == nothing
        Logger.warn_static("No volume data available for any stock in the universe")
    end

    # println("vol_minute")
    # println(vol_unadj)

    return Dict(
      "Adjusted" => 
        Dict("Open" => openprices, 
            "High" => highprices, 
            "Low" => lowprices, 
            "Close" => closeprices, 
            "Volume" => vol),
      "Unadjusted" => 
      Dict("Open" => openprices_unadj, 
        "High" => highprices_unadj, 
        "Low" => lowprices_unadj, 
        "Close" => closeprices_unadj, 
        "Volume" => vol_unadj)
      )
end

function _run_algo_minute(startdate::Date = getstartdate(), enddate::Date = getenddate(), forward::Bool = false)
    try
      Logger.info_static("Fetching data")
      setcurrentdate(getstartdate())

      # The parameters start_date and end_date here represent the datesfor which I want to run the simulation
      # In case of backtest, they're by default set to the ones provided as external parameters or from initialize function
      # In case of forward test, they are just one single day
      benchmark = API.getbenchmark()

      #Let's download new data now
      benchmarkdata_EOD = YRead.history_unadj([benchmark.id], "Close", :Day, DateTime(startdate), DateTime(enddate), displaylogs = false, strict = false)

       if benchmarkdata_EOD == nothing
          Logger.warn_static("Benchmark EOD data not available from $(startdate) to $(enddate)")
          Logger.warn_static("Aborting test")
          return false
      end

      # println("benchmarkdata_EOD")
      # println(benchmarkdata_EOD)

      # Get all ids for stocks in universe 
      universeIds = [security.symbol.id  for security in getuniverse(validprice=false)]

      if(length(universeIds) == 0) 
          Logger.error("Empty Universe")
          return false
      end

      ohlcvEOD = _fetch_EOD_prices(universeIds, DateTime(startdate), DateTime(enddate))
      ohlcv = _fetch_minute_prices(universeIds, DateTime(startdate), DateTime(enddate))
      
      #Join benchmark data with close prices
      #Right join (benchmark data comes from NSE database and excludes the holidays)
      closeprices_EOD = get(ohlcvEOD, "Close", nothing)
      if closeprices_EOD == nothing
        Logger.warn_static("Close Price EOD Data not available from $(startdate) to $(enddate)")
        Logger.warn_static("Aborting test")
        return false
      end

      closeprices = get(get(ohlcv, "Adjusted", Dict{String, TimeArray}()), "Close", nothing)
      if closeprices == nothing
        Logger.warn_static("Close Price Data (Minute) not available from $(startdate) to $(enddate)")
        Logger.warn_static("Aborting test")
        return false
      end

      closeprices_EOD = !isempty(closeprices_EOD) && !isempty(benchmarkdata_EOD) ? merge(closeprices_EOD, benchmarkdata_EOD, :right) : closeprices_EOD
      labels = Dict{String,Float64}()

      # println("WTFFF")

      bvals = values(closeprices_EOD[Symbol(benchmark.ticker)])
      for (i, dt) in enumerate(TimeSeries.timestamp(closeprices_EOD))
        val = bvals[i]

        j = i-1

        while isnan(val) && j > 0
          val = bvals[j]
          j = j - 1
        end

        val = isnan(val) ? 0.0 : val

        labels[string(dt)] = val
      end

      # println("WTFFF-2")

      #Set benchmark value and Output labels from graphs
      setbenchmarkvalues(labels)

      #continue with backtest if there are any rows in price data.
      if !isempty(closeprices_EOD)
        outputlabels(labels)
      else
        Logger.error_static("No price data found. Aborting Backtest!!!")
        return
      end

      adjustments = YRead.getadjustments(universeIds, DateTime(startdate), DateTime(enddate), displaylogs = false)

      #Setup technical datastores with adjusted prices
      TechnicalAPI.setupMinuteDataStore(get(ohlcv, "Adjusted", Dict{String, TimeArray}()))

      Logger.info_static("Evaluating ENTRY/EXIT criteria")

      LONGENTRY = nothing
      LONGEXIT = nothing
      SHORTENTRY = nothing
      SHORTEXIT = nothing

      try
        #API.setparent(:condition)
        API.setparent(:all)

        LONGENTRY = longEntryCondition() 
        # LONGENTRY =  LONGENTRY !=nothing ? rename(LONGENTRY, TimeSeries.colnames(closeprices)) : nothing
        
        LONGEXIT = longExitCondition()
        # LONGEXIT = LONGEXIT != nothing ? rename(LONGEXIT, TimeSeries.colnames(closeprices)) : nothing

        SHORTENTRY = shortEntryCondition() 
        # SHORTENTRY = SHORTENTRY !=nothing ? rename(SHORTENTRY, TimeSeries.colnames(closeprices)) : nothing
        
        SHORTEXIT = shortExitCondition() 
        # SHORTEXIT = SHORTEXIT !=nothing ? rename(SHORTEXIT, TimeSeries.colnames(closeprices)) : nothing
        

        # println("Finished Evaluating Conditions")
        # println("LONGENTRY")
        # println(LONGENTRY)

        # println("LONGEXIT")
        # println(LONGEXIT)

        API.setparent(:all)
      catch err
        API.setparent(:all)
        handleexception(err, forward)
        return false
      end
      
      Logger.info_static("Running algorithm for each date")
      success = true
      for (i, dateString) in enumerate(sort(collect(keys(labels))))
          
          date = Date(dateString)

          # println("NOw...")
          setcurrentdate(date)
          
          ohlcvMinuteToday = _filterTA(get(ohlcv, "Unadjusted", Dict{String, TimeArray}()), date)
                  
          # println("_after_start")
          #update account/pending order before the start of new date
          _after_start(date, ohlcvMinuteToday, adjustments, forward)

          # println("_process_conditions")
          
          # println("Filter Conditions For $(date)")
          todayTradeConditions = _filterConditionsForDate(LONGENTRY, LONGEXIT, SHORTENTRY, SHORTEXIT, date)

          # println("Process Conditions")

          success = _process_conditions(date, 
              ohlcvMinuteToday, todayTradeConditions,
              Dict("stopLoss" =>  getStopLoss(), "profitTarget" => getProfitTarget()),
              forward)

          if(!success)
              break
          end


          # println("After Process")
          # println(getallpositions())

          # println("Filtering EOD")
          ohlcvEODToday = _filterTA(ohlcvEOD, date)
          # println(ohlcvEODToday)

          # println("_before_close")
          _before_close(date, ohlcvEODToday, adjustments, forward)
      end #end for loop

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
