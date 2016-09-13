include("../Security/Security.jl")

type TradingEnvironment
  startdate::DateTime
  enddate::DateTime
  currentdatetime::DateTime
  livemode::Bool
  benchmark::SecuritySymbol
  resolution::Resolution
  fullrun::Bool
  defaultsecuritytype::SecurityType
  defaultmarket::ASCIIString

  #calendar::TradingCalendar
  #WHAT IS A TRADING CALENDAR
end

TradingEnvironment() = TradingEnvironment(
                          DateTime(), DateTime(), DateTime(), false, 
                          SecuritySymbol(), Resolution(Daily), true,
                          SecurityType(Equity), "IN")

function setresolution!(tradeenv::TradingEnvironment, resolution::Resolution)
  tradeenv.resolution = resolution
end

function setstartdate!(tradeenv::TradingEnvironment, datetime::DateTime)
  tradeenv.startdate = datetime
end

function setenddate!(tradeenv::TradingEnvironment, datetime::DateTime)
  tradeenv.enddate = datetime
end

function setbenchmark!(tradeenv::TradingEnvironment, symbol::ASCIIString)
  benchmarksymbol = createsymbol(symbol, tradeenv.defaultsecuritytype)
  tradeenv.benchmark = benchmarksymbol
end

function setcurrentdatetime!(tradeenv::TradingEnvironment, datetime::DateTime)
  if !tradeenv.livemode 
    tradeenv.currentdatetime = datetime
  end
end


#=
TradingCalendar(startdate::DateTime, enddate::DateTime, calendar::TradingCalendar)
  = TradingCalendar(startdate, enddate, false, calendar)

TradingCalendar(startdate::DateTime, enddate::DateTime, livemode:Bool)
  = TradingCalendar(startdate, enddate, livemode, TradingCalendar())
  
TradingCalendar(startdate::DateTime, enddate::DateTime)
  = TradingCalendar(startdate, enddate, false, TradingCalendar())
=#
