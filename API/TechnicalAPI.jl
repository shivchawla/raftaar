__precompile__()
module TechnicalAPI
	
using MarketTechnicals 
using TimeSeries
using YRead
using Dates

import API.getuniverse
import API.getresolution
import API.getstartdate
import API.getenddate

import API.Resolution
import API.Resolution_Minute
import API.Resolution_Day

import Base.filter
import Base.getindex

minuteDataStore = Dict{String, TimeArray}()

mutable struct Condition 
    _ta::TimeArray
end

Condition(cond::Condition) = Condition(deepcopy(cond._ta))

getindex(cond::Condition, date::Date) =  cond._ta[date]
getindex(cond::Condition, datetime::DateTime) =  cond._ta[datetime]
getindex(cond::Condition, sym::Symbol) =  cond._ta[sym]
getindex(cond::Condition, syms::Vector{Symbol}) =  cond._ta[syms]

mutable struct Indicator
   _ta::TimeArray
end

Indicator(ind::Indicator) = Indicator(deepcopy(ind._ta))

getindex(ind::Indicator, date::Date) =  ind._ta[date]
getindex(ind::Indicator, datetime::DateTime) =  ind._ta[datetime]
getindex(ind::Indicator, sym::Symbol) =  ind._ta[sym]
getindex(ind::Indicator, syms::Vector{Symbol}) =  ind._ta[syms]

export Condition, Indicator, getindex

function Base.:(==)(c1::Indicator, c2::Indicator)
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .== c2._ta[names_c1], names_c1))

end

function Base.:>(c1::Indicator, c2::Indicator) 
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .> c2._ta[names_c1], names_c1))

end

function Base.:<(c1::Indicator, c2::Indicator) 
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .< c2._ta[names_c1], names_c1))

end

function Base.:>=(c1::Indicator, c2::Indicator)
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .>= c2._ta[names_c1], names_c1))

end

function Base.:<=(c1::Indicator, c2::Indicator)
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .<= c2._ta[names_c1], names_c1))

end

function Base.:&(c1::Condition, c2::Condition)
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .& c2._ta[names_c1], names_c1))
    
end

function Base.:|(c1::Condition, c2::Condition)
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .| c2._ta[names_c1], names_c1))

end

function filter(condition::Condition, date::Date)
    fcond = Condition(condition)
    _ta = fcond._ta[Date.(TimeSeries.timestamp(fcond._ta)) .== date]
    
    return _ta
end
export filter

# function TimesSeries.:[](c:)


function setupMinuteDataStore(open, high, low, close, volume)
    global minuteDataStore["Open"] = open
    global minuteDataStore["High"] = high
    global minuteDataStore["Low"] = low
    global minuteDataStore["Close"] = close
    global minuteDataStore["Volume"] = volume
end

function setupMinuteDataStore(ohlcv)
    global minuteDataStore = ohlcv
end

function _getTA(;price::String="Close", horizon = 10)
    ta = nothing

    if getresolution() == Resolution_Minute
        if price == "Open"
          ta = minuteDataStore["Open"]
        elseif price == "High"
          ta = minuteDataStore["High"]
        elseif price == "Low"
          ta = minuteDataStore["Low"]
        elseif price == "Close"
          ta = minuteDataStore["Close"]
        elseif price == "Volume"
          ta = minuteDataStore["Volume"]
        end
    elseif getresolution() == Resolution_Day
        YRead.history([sec.symbol.ticker for sec in getuniverse()], price, :Day, DateTime(getstartdate() - Dates.Day(2*horizon)), DateTime(getenddate()), displaylogs = false)
    end
end

horizonDefault() = getresolution() == :Day ? 22 : 1000

"""
Simple Moving Average
"""
function SMA(;horizon = horizonDefault(), price="Close")
  
    names = [security.symbol.ticker for security in getuniverse()]
    ta = _getTA(price = price, horizon = horizon)

    # println("Historical Prices")
    # println(ta)

    if ta != nothing
      _ind = sma(ta, horizon)
      
      # println(_ind)
      
      return Indicator(rename(_ind, colnames(ta)))
    end
    
end

export SMA

"""
Exponential Moving Average
"""
function EMA(;horizon = horizonDefault(), price="Close", wilder = false)
    
    names = [security.symbol.ticker for security in getuniverse()]
    ta = _getTA(price)


    if ta != nothing
      return Indicator(rename(ema(ta, horizon, wilder = wilder), colnames(ta)))
    end
    
end

export EMA

"""
Rate of change
"""
function ROC(;horizon = horizonDefault(), price="Close")
    
    names = [security.symbol.ticker for security in getuniverse()]

    ta = _getTA(price)

    if ta != nothing
      return Indicator(rename(roc(ta, horizon), colnames(ta)))
    end

end

export ROC


fastKAMADefault() = getresolution() == :Day ? 5 : 200
slowKAMADefault() = getresolution() == :Day ? 66 : 3000

"""
Kaufman Adaptive Moving Average
"""
function KAMA(;horizon = horizonDefault(), price="Close", fast = fastKAMADefault(), slow = slowKAMADefault())
    
    names = [security.symbol.ticker for security in getuniverse()]

    ta = _getTA(price)

    if ta != nothing
      return Indicator(rename(kama(ta, horizon, fast, slow), colnames(ta)))
    end
    
end

export KAMA

# """
# Moving Average Envelope
# """
# function ENVELOPE(;horizon = 1000, frequency="1m", price="Close", env = 0.1, type="UP")
#     ta = _getTA(price)

#     if ta != nothing
#       env(ta, horizon, e = env)
#     end
# end

##########MODIFY REST AFTER TESTING THE ABOVE

"""
Average Directional Movement Index
"""
function ADX(;horizon = 1000, frequency="1m")
    
    names = [security.symbol.ticker for security in getuniverse()]

    close = _getTA("Close")
    high = _getTA("High")
    low = _getTA("Low")

    output = Indicators()

    for name in names
        h = high[name]
        l = low[name]
        c = close[name]

        h = length(h) != 0 ? h : nothing
        l = length(h) != 0 ? l : nothing
        c = length(h) != 0 ? c : nothing

        hlc = h != nothing && l != nothing && c != nothing ? 
              merge(merge(h, l, :outer), c, :outer) : nothing
        
        output[name] = hlc != nothing ? rename(adx(ohlc, horizon), [name]) : nothing
    end

    return output
end

export ADX



"""
Aroon Oscillator
"""
function AROON(;horizon = 1000, frequency="1m")
    
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    hl = merge(high, low, :inner)

    if hl != nothing
      aroon(hl, horizon)
    end
end

"""
Relative Strength Indicator
"""
function RSI(;horizon = 1000, frequency="1m", price = "Close", wilder = wilder )
    
    ta = _getTA(price)

    if ta != nothing
      rsi(ta, horizon, wilder = wilder)
    end
end

"""
Moving Average Convergence Divergence
"""
function MACD(;horizon = 1000, frequency="1m", price = "Close", wilder = wilder, fast = 120, slow = 260, signal = 90)
    
    ta = _getTA(price)

    if ta != nothing
      macd(ta, fast, slow, signal, wilder = wilder)
    end
end

"""
Chaikin Oscillator
"""
function CHAIKIN_OSC(;horizon = 1000, frequency="1m", fast = 30, slow = 180)
    
    open = rename(_getTA("Open"), ["Open"])
    close = rename(_getTA("Close"), ["Close"])
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    ohlc = merge(merge(merge(open, close, :inner), high, :inner), low, :inner)

    if ohlc != nothing
      chaikinoscillator(ohlc, fast, slow)
    end
end

"""
Stochastic Oscillator
"""
function STOCHASTIC_OSC(;horizon = 1000, frequency="1m", fast = 30, slow = 30)
    
    open = rename(_getTA("Open"), ["Open"])
    close = rename(_getTA("Close"), ["Close"])
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    ohlc = merge(merge(merge(open, close, :inner), high, :inner), low, :inner)

    if ohlc != nothing
      chaikinoscillator(ohlc, horizon, fast, slow)
    end
end

"""
Bollinger Band
"""
function BOLLINGER(;horizon = 1000, frequency="1m", price="Close", width = 2.0)
    ta = _getTA(price)

    if ta != nothing
      bollingerbands(ta, horizon, width = width)
    end
end

"""
Chaikin Volatility
"""
function CHAIKIN_VOL(;horizon = 1000, frequency="1m", price="Close", width = 2.0, previous = 100)
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    hl = merge(high, low, :inner)

    if hl != nothing
      chaikinvolatility(hl, horizon, previous)
    end
end


"""
True Range
"""
function TRUERANGE(;frequency="1m")
    
    open = rename(_getTA("Open"), ["Open"])
    close = rename(_getTA("Close"), ["Close"])
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    ohlc = merge(merge(merge(open, close, :inner), high, :inner), low, :inner)

    if ohlc != nothing
      truerange(ohlc)
    end
end


"""
Average True Range
"""
function AVGTRUERANGE(;horizon = 1000, frequency="1m")
    
    open = rename(_getTA("Open"), ["Open"])
    close = rename(_getTA("Close"), ["Close"])
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    ohlc = merge(merge(merge(open, close, :inner), high, :inner), low, :inner)

    if ohlc != nothing
      atr(ohlc, horizon)
    end
end


"""
Accumulation/Distributin Line
"""
function ADL(;frequency="1m")
    
    volume = rename(_getTA("Volume"), ["Volume"])
    close = rename(_getTA("Close"), ["Close"])
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    hlcv = merge(merge(merge(volume, close, :inner), high, :inner), low, :inner)

    if hlcv != nothing
      adl(hlcv)
    end
end

"""
On Balance Volume
"""
function OBV(;frequency="1m")
    
    volume = rename(_getTA("Volume"), ["Volume"])
    close = rename(_getTA("Close"), ["Close"])
    
    cv = merge(volume, close, :inner)

    if cv != nothing
      adl(cv)
    end
end

"""
Volume Weighted Adjusted Price
"""
function VWAP(;frequency="1m", price = "Close")
    
    open = rename(_getTA("Open"), ["Open"])
    close = rename(_getTA("Close"), ["Close"])
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])
    volume = rename(_getTA("Volume"), ["Volume"])

    ohlcv = merge(merge(merge(merge(open, close, :inner), high, :inner), low, :inner), volume, :inner)

    if ohlcv != nothing
      vwap(ohlcv, price = price)
    end
end

"""
Typical Price (H+L+C/3)
"""
function TYPICAL(;frequency="1m", price = "Close")
    
    close = rename(_getTA("Close"), ["Close"])
    high = rename(_getTA("High"), ["High"])
    low = rename(_getTA("Low"), ["Low"])

    hlc = merge(merge(low, close, :inner), high, :inner)

    if hlc != nothing
      typical(hlc)
    end
end

end #end module
