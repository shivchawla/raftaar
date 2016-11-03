# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#="""
Implements the backtester logic
Runs the backtesting logic from the start date to the end date.
Updates the universe with each time stamp, run user defined strategy 
at every time steps and updates portfolio, orders and performance for fills
and latest prices
"""=#

using DataFrames
using DataStructures

include("../API/API.jl")
#include("../Examples/firstalgorithm.jl")
include("../Examples/constantvalue.jl")


sym = "CNX_BANK"
alldata = history("CNX_BANK", "Close", :A, 100, enddate = "2016-01-01")

setstartdate(DateTime(alldata[:Date][end]))
setenddate(DateTime(alldata[:Date][1]))

setlogmode(:json)

initialize()

startdate = getstartdate()
enddate = getenddate()

i = 0

dynamic = 0

updateuniverseforids()

for i = size(alldata,1):-1:1   
  
  Logger.warn("This is going to be big")
  date = DateTime(alldata[i,:Date])
  setcurrentdatetime(date)

  if dynamic > 0
    updateuniverseforids()
    updatepricestores(date, fetchprices(date))
  else
    updatepricestores(date, alldata[i,:])
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

  #once orders are placed, internal system calls onData();
  ondata() #this is called every data stamp, user can 
  # user defines this functions where he sets universe, 
  #creates new orders for the next session 
  #(give option to trading at open/close/or worst price)
  #Internal system checks policy for stocks not in universe
  #If liquidation is set to true, add additional pending orders of liquidation

  #this should only be called once a day in case of high frequency data
  _updateaccounttracker()

  _updateperformance()

  _outputperformance()
  println(getallpositions())
end  

#_calculateperformance()
 

#initialize()
#for data in alldata
  #this data is per time stamp
  #Perform various steps
  #Step 1: Handle Symbol changes: cancel orders for symbol changes
  #Step 2: Update universe: add securities 
  #Step 3. Scans all the outstanding ORDERS and apply the algorithm model fills to generate the order events. New Portfolio.
  #Step 4: Remove delisted securities from universe with filled orders
  #Step 5: Stop algorithm if signaled stop/cancel by the user
  #NOT REQUIRED FOR BACKTESTING Step 6: Check for margin call. Release warning or liquidate.         
  #Step 7. Apply Dividends and Split Adjustment to existing portfolio
  #Step 8. Handle delisitng: Logic is debatable. liquidate as of last known price OR let it stay
  #Step 9: Fire Pricing Event OnData()"
  #Step 10: Calculate new portfolio stats based on portfolio as EOD"
#end

#end


#learn how to call julia file from commandline and how the commandline arguments play role

#=
THINKING IN SIGNALS
1. Signal to update price data in the dataframe
2. When data is updated, 
a. Signal to update open orders (in backtest orders are executed at next tick)
      Signal to update the portfolio
          Signal to update the performance with new portfolio
          
          Signal to call the trading function 
              Signal to place new orders  


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

=#


function run_algo()
  algorithm = Algorithm()

  initialize()


end
























