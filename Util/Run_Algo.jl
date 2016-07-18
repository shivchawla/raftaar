



"""
Here is the engine of the backtest or live trading
For backtest, the data is fetched based on dates provided
and loop is called

"""

"""
Inputs:
  1.Dataframe DateTime/Security/Close values OR dictionary for date-time including OHLC prices for each security/date
  2.

Returns:
  1.Date/Trade
  2.Date/Portfolio
"""

date security open high low close volume

function RunBacktest(data::Dataframe)
    "get unique time stamps in the dataframe"
    for dataForDateTime in groupby(data, :DateTime)
      Evaluate(dataForDateTime)
      OnData(data)
    end
end

function Evaluate(data::DataFrame)
  "this data is per time stamp"
  "Perform various steps"
  "Step 1: Handle Symbol changes: cancel orders for symbol changes"
  "Step 2: Update universe: add securities "
  "Step 3. Scans all the outstanding ORDERS and apply the algorithm model fills to generate the order events. New Portfolio."
  "Step 4: Remove delisted securities from universe with filled orders" 
  "Step 5: Stop algorithm if signaled stop/cancel by the user"
  "Step 6: Check for margin call. Release warning or liquidate."         
  "Step 7. Apply Dividends and Split Adjustment to existing portfolio"
  "Step 8. Handle delisitng: Logic is debatable. liquidate as of last known price OR let it stay."
  "Step 9: Fire Pricing Event OnData()"
  "Step 10: Calculate new portfolio stats based on portfolio as EOD"
end

function run(algorithm::Algorithm, backtest::Bool)
end

function onData(data::DataFrame)

end
