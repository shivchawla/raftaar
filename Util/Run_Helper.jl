
import Logger: warn, info, error
import Base: isvalid, showerror

pattern = ""
using DataFrames

#include("../API/API.jl")
include("../Examples/constantpct.jl")
include("../Util/handleErrors.jl")
#include("../Util/parseArgs.jl")
#include("../Util/processArgs.jl")

alldata = DataFrame()
dynamic = 0

function mainfnc(i::Int) 
  
  date = DateTime(alldata[i,:Date])
  
  setcurrentdatetime(date)
  
  if dynamic > 0
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
