


#=
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
end=#


include("../Engine/API.jl")
include("../Examples/firstalgorithm.jl")

using DataFrames
using DataStructures
#using Dates

#import Raftaar.history
#=
Need to make a data module.
Work in pipeline: Yojak
=#


  algorithm = Algorithm()

  sym = "GOOG/NASDAQ_QQQ"
  #alldata = history(sym, 1000)    

  alldata = DataFrame()

  alldata[:Date] = Date(2001,01,01):Date(2016,01,31)
  #println(size(alldata,1))
  alldata[:Close] = 1.0:size(alldata,1)

  DateTime(date::Date) = Dates.DateTime(Dates.year(date), Dates.month(date), Dates.day(date))

  sd = Date(2001,01,01)
  ed = Date(2016,01,31)

  setstartdate(DateTime(sd))
  setenddate(DateTime(ed))
  
  initialize()

  startdate = getstartdate()
  enddate = getenddate()
  
  i = 0

  for i in 1:size(alldata,1)
    
    close = alldata[i,:Close]
    datetime = DateTime(alldata[i,:Date])

    _setcurrentdatetime(datetime)

    tradebar = TradeBar(datetime, close, close, close, close, 1000000)
    ss = createsymbol(sym, SecurityType(Equity))

    tradebars = Dict{SecuritySymbol, Vector{TradeBar}}() #_fetchprices(date) 
    tradebars[ss] = Vector{TradeBar}()
    push!(tradebars[ss], tradebar) 

       
    #If a stock doesn't come with a price?????, liquidate at a last known price.
    #If a stock goes through a split, position and orders are adjusted accordingly.
    #If a stock has a dividend, cash is updated
    #_updateportfoliofordividends()
    #_updatportfolioforsplits()
    _updateprices(tradebars)

 
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
  end  

  _calculateperformance()
  


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



























