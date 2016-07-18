
Step 1: Create Algorithm
Step 2: Initialize Brokerage
Step 3: Initialize Datafeed
Step 4: Initialize history provider
Step 5: Initialize brokerage message handler
Step 6: Initialize Algorithm



type TradingEnvironment
  startDate::Date
  endDate::Date
  liveMode::Bool
  calendar::TradingCalendar
end  

function initialize()
  
  "initialize trading enviroment"
  tradeenv::TradingEnvironment
  
  "What is trading environment?"
  "SEE ABOVE"


  "Initialize algorithm parameters"
  
"""
  ******"DO WE NEED BLOTTER? HOW IS IT DIFFERENT FROM TRANSACTION HANDLER? WHO MANAGES OPEN ORDERS"
    

  Security Transaction Manager : Stores all the open orders . Accepts the add/update/cancel order requests 
  and forwards it to: 
  BROKERAGE TRANSACTION HANDLER: saves the request, creates order ticket and immediately returns the ticket.

  Now, on a separate thread , requests are checked and orders are created and sent to the broker.



  "Create algorithm"
  algorithm = createalgorithm(algoparameters, tradeenv)


  "Once algorithm is created, Initialize brokerage and transaction handler for the algorithm...Decide whats required"

  "Now initialze the tick data feeds"


  "Now initialize the historical data source"

  "Based on above initializations, run teh algorithm"


end


SIGNALS in TradingLogic (Julia)


Step 1 : Setup all signals

Signal 1: s_ohlc => A tuple (pair) value of date-time and ohlc data
Signal 2: s_pnow => s_ohlc signal tansformed to point to next value for a specified symbol
Signal 3: s_status => status signal after calling run trading function. In run trading fucntion
Signal 4: s_perf => signal after calculating the performance based on "s_status"

Step 2: Calculate equity values using above signals  running core of the backtesting


CORE of the backtesting:

1. Find the length of data
2. Initialize equity value array of the same length (from 1)
3. for each time stamp, update (push new) values to s_ohlc with next data
4. Record the equity values from the respective signals
5. Repeat 3

Nice thing: All the signals are calculated asynchronously but return final result snychronously. 
Dnt have to worry about the finishing one a unit of work to trigger next. It's automatically taken care of.

     _____________________________________________________________________________________________________ 
    |                                                                                                     |
    |                                                                                                     |
Signal 1 ----- (computation)----Signal 2----------computation--------signal 4---                          |
                          |                 |                                   |---computatation---Signal 1
                          |                 |--------computation-----signal 5----       |
                          |                 |                                           | 
                          ----- Signal 3------------------------------------------------- 



Now, define your algorithm and tehen try to setup in terms in signals
1. Initialize the trading environment
2. Initialize the brokerage, algorithm
3. for every data point:
      Step 1: Handle Symbol changes: cancel orders for symbol changes
      Step 2: Update universe: add securities 
      Step 3. Scans all the outstanding ORDERS and apply the algorithm model fills to generate the order events. New Portfolio.
      Step 4: Remove delisted securities from universe with filled orders
      Step 5: Stop algorithm if signaled stop/cancel by the user
      Step 6: Check for margin call. Release warning or liquidate.         
      Step 7. Apply Dividends and Split Adjustment to existing portfolio
      Step 8. Handle delisitng: Logic is debatable. liquidate as of last known price OR let it stay.
      Step 9: Fire Pricing Event OnData()
      Step 10: Calculate new portfolio stats based on portfolio as EOD



























