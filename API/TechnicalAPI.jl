__precompile__()
module TechnicalAPI
	
using MarketTechnicals 
using TimeSeries
using HistoryAPI

import API.getuniverse

minuteDataStore = Dict{String, TimeArray}()

const Conditions = Dict{String, TimeArray}
const Indicators = Dict{String, TimeArray}

export Conditions, Indicators

function Base.:(==)(c1::Indicators, c2::Indicators)
    keys_c1 = collect(keys(c1))
    keys_c2 = collect(keys(c2))

    if length(setdiff(keys_c1, keys_c2)) != 0
      throw("Unequal entities")
    end

    output = Conditions()
    for key in keys_c1
      output[key] = rename(c1[key] .== c2[key], [Symbol(key)])
    end

    return output
end

function Base.:>(c1::Indicators, c2::Indicators) 
    keys_c1 = collect(keys(c1))
    keys_c2 = collect(keys(c2))

    # println("Greater than")
    # println(keys_c1)

    if length(setdiff(keys_c1, keys_c2)) != 0
      throw("Unequal entities")
    end

    output = Conditions()
    for key in keys_c1
      output[key] = rename(c1[key] .> c2[key], [Symbol(key)])
    end

    # println("Conditions")
    # println(output)

    return output
end

function Base.:<(c1::Indicators, c2::Indicators) 
    keys_c1 = collect(keys(c1))
    keys_c2 = collect(keys(c2))

    if length(setdiff(keys_c1, keys_c2)) != 0
      throw("Unequal entities")
    end

    output = Conditions()
    for key in keys_c1
      output[key] = rename(c1[key] .< c2[key], [Symbol(key)])
    end

    return output
end

function Base.:>=(c1::Indicators, c2::Indicators)
    keys_c1 = collect(keys(c1))
    keys_c2 = collect(keys(c2))

    if length(setdiff(keys_c1, keys_c2)) != 0
      throw("Unequal entities")
    end

    output = Conditions()
    for key in keys_c1
      output[key] = rename(c1[key] .>= c2[key], [Symbol(key)])
    end

    return output
end

function Base.:<=(c1::Indicators, c2::Indicators)
    keys_c1 = collect(keys(c1))
    keys_c2 = collect(keys(c2))

    if length(setdiff(keys_c1, keys_c2)) != 0
      throw("Unequal entities")
    end

    output = Conditions()
    for key in keys_c1
      output[key] = rename(c1[key] .<= c2[key], [Symbol(key)])
    end

    return output
end

function Base.:&(c1::Conditions, c2::Conditions)
    keys_c1 = collect(keys(c1))
    keys_c2 = collect(keys(c2))

    if length(setdiff(keys_c1, keys_c2)) != 0
      throw("Unequal entities")
    end

    output = Conditions()
    for key in keys_c1
      output[key] = rename(c1[key] .& c2[key], [Symbol(key)])
    end

    return output
end

function Base.:|(c1::Conditions, c2::Conditions)
    keys_c1 = collect(keys(c1))
    keys_c2 = collect(keys(c2))

    if length(setdiff(keys_c1, keys_c2)) != 0
      throw("Unequal entities")
    end

    output = Conditions()
    for key in keys_c1
      output[key] = rename(c1[key] .| c2[key], [Symbol(key)])
    end

    return output
end

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

function _getTA(;price::String="Close", frequency::String="1m", horizon = 10)
    ta = nothing
    
    if frequency == "1m" 
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
    elseif frequency == "Day"
        HistoryAPI.history(getuniverse(), price, :Day, horizon)
    end
end

"""
Simple Moving Average
"""
function SMA(;horizon = 1000, frequency="1m", price="Close")
  
    names = [security.symbol.ticker for security in getuniverse()]
    ta = _getTA(price = price, horizon = horizon, frequency = frequency)

    output = Indicators()
    
    if ta != nothing
  	
      _sma = sma(ta, horizon)

      # println("Colnames: $(TimeSeries.colnames(_sma))")
      # println(_sma)
        
      for name in names
        # println("name: $(name)")
        
        output[name] = rename(_sma[Symbol("$(name)_sma_$(horizon)")], [Symbol(name)])
      end
    end

    # println("Final SMA")
    # println(output)

    return output
end

export SMA

"""
Exponential Moving Average
"""
function EMA(;horizon = 1000, frequency="1m", price="Close", wilder = false)
    
    names = [security.symbol.ticker for security in getuniverse()]
    ta = _getTA(price)

    output = Indicators()
    
    if ta != nothing

      ema = ema(ta, horizon, wilder = wilder)
      
      for name in names
        output[name] = rename(ema[Symbol("$(name)_ema_$(horizon)")], [Symbol(name)])
      end
    end

    return output
end

export EMA

"""
Rate of change
"""
function ROC(;horizon = 1000, frequency="1m", price="Close")
    
    names = [security.symbol.ticker for security in getuniverse()]

    ta = _getTA(price)

    output = Indicators()
    
    if ta != nothing

      roc = roc(ta, horizon)
      
      for name in names
        output[name] = rename(roc[Symbol("roc_$(name)")], [Symbol(name)])
      end
    end

    return output
end

export ROC

"""
Kaufman Adaptive Moving Average
"""
function KAMA(;horizon = 1000, frequency="1m", price="Close", fast = 200, slow = 3000)
    
    names = [security.symbol.ticker for security in getuniverse()]

    ta = _getTA(price)

    output = Indicators()
    
    if ta != nothing
      kama = kama(ta, horizon, fast, slow)
      
      for name in names
        output[name] = rename(kama[Symbol("kama_$(name)")], [Symbol(name)])
      end
    end

    return output
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


##########MODIFY REST AFTER TESTING THE ABOVE

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
