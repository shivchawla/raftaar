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

function Base.:(==)(c1::Indicator, val::Float64)
    return Condition(rename(c1._ta .== val, names_c1))
end

function Base.:>(c1::Indicator, c2::Indicator) 
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .> c2._ta[names_c1], names_c1))
end

function Base.:>(c1::Indicator, val::Float64)
    return Condition(rename(c1._ta .> val, names_c1))
end

function Base.:<(c1::Indicator, c2::Indicator) 
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .< c2._ta[names_c1], names_c1))
end

function Base.:<(c1::Indicator, val::Float64)
    return Condition(rename(c1._ta .< val, names_c1))
end

function Base.:>=(c1::Indicator, c2::Indicator)
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .>= c2._ta[names_c1], names_c1))
end

function Base.:>=(c1::Indicator, val::Float64)
    return Condition(rename(c1._ta .>= val, names_c1))
end

function Base.:<=(c1::Indicator, c2::Indicator)
    names_c1 = colnames(c1._ta)
    names_c2 = colnames(c2._ta)

    if length(setdiff(names_c1, names_c2)) != 0
      throw("Unequal entities")
    end

    return Condition(rename(c1._ta .<= c2._ta[names_c1], names_c1))
end

function Base.:<=(c1::Indicator, val::Float64)
    return Condition(rename(c1._ta .<= val, names_c1))
end

#Logic to compute cross above/below
#           d       ld      d-ld
# 1  3     -2        NaN      NaN
# 2  4     -2        -2       0
# 5  4.5    1 (CA)   -2        3
# 7  6      1         1        0
# 8  10    -2 (CB)    1        -3
# 10 9      1  (CA)   -2        3
function crossBelow(ind1::Indicator, ind2::Indicator)
    names_ind1 = colnames(ind1._ta)
    names_ind2 = colnames(ind2._ta)

    if length(setdiff(names_ind1, names_ind2)) != 0
      throw("Unequal entities")
    end
    x = ind1._ta .- ind2._ta[names_ind1]
    y = x ./ abs.(x)
    z = y .- lag(y)
    return Condition(rename(z .< 0, names_ind1))
end

function crossBelow(ind::Indicator, val)
    names_ind = colnames(ind._ta)
    x = ind._ta .- val
    y = x ./ abs.(x)
    z = y .- lag(y)
    return Condition(rename(z .< 0, names_ind))
end

function crossAbove(ind1::Indicator, ind2::Indicator)
    names_ind1 = colnames(ind1._ta)
    names_ind2 = colnames(ind2._ta)

    if length(setdiff(names_ind1, names_ind2)) != 0
      throw("Unequal entities")
    end
    x = ind1._ta .- ind2._ta[names_ind1]
    y = x ./ abs.(x)
    z = y .- lag(y)
    return Condition(rename(z .> 0, names_ind1))
end

function crossAbove(ind::Indicator, val)
    names_ind = colnames(ind._ta)

    x = ind1._ta .- val
    y = x ./ abs.(x)
    z = y .- lag(y)

    return Condition(rename(z .> 0, names_ind))
end

export crossAbove, crossBelow

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

# function getresolution()
#   return Resolution_Day
# end

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
        # YRead.history(["TCS", "WIPRO", "INFY"], price, :Day, DateTime(Date("2017-12-31") - Dates.Day(2*horizon)), DateTime(Date("2018-12-31")), displaylogs = false)
        YRead.history([sec.symbol.ticker for sec in getuniverse()], price, :Day, DateTime(getstartdate() - Dates.Day(2*horizon)), DateTime(getenddate()), displaylogs = false)
    end
end

"""
Constant Indicator
"""
function CONSTANT(val)
    ta = _getTA(price = "Close")

    if ta != nothing
      _ind = TimeArray(timestamp(ta), Float64(val)*ones(size(ta)), colnames(ta))

      return Indicator(_ind)
    end
end

export CONSTANT

horizonDefault() = 22

"""
Simple Moving Average
"""
function SMA(;horizon = horizonDefault(), price="Close")
  
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
    
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing
      return Indicator(rename(ema(ta, horizon, wilder = wilder), colnames(ta)))
    end
end

export EMA


fastKAMADefault() = 10
slowKAMADefault() = 30

"""
Kaufman Adaptive Moving Average
"""
function KAMA(;horizon = horizonDefault(), price="Close", fast = fastKAMADefault(), slow = slowKAMADefault())
    
    ta = _getTA(price = price, horizon = max(horizon, slow))

    if ta != nothing
      return Indicator(rename(kama(ta, horizon, fast, slow), colnames(ta)))
    end
end

export KAMA


#DEMA = ( 2 * EMA(n)) - (EMA(EMA(n)) ), where n= period
"""
Double Exponential Moving Average
"""
function DEMA(;horizon = horizonDefault(), price="Close", wilder = false)
    
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing
      _ea = ema(ta, horizon, wilder = wilder)
      _eea = ema(_ea, horizon, wilder = wilder)

      _dema = 2 .* _ea  .-  _eea
      
      return Indicator(rename(_dema, colnames(ta)))
    end
end

export DEMA

#TEMA = 3 * EMA - 3 * EMA(EMA) + EMA(EMA(EMA))
"""
Triple Exponential Moving Average
"""
function TEMA(;horizon = horizonDefault(), price="Close", wilder = false)
    
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing
      _ea = ema(ta, horizon, wilder = wilder)
      _eea = ema(_ea, horizon, wilder = wilder)
      _eeea = ema(_eea, horizon, wilder = wilder)

      # 3 additions in single computation threw array mismatch (bodcast error)  
      _bt = 3 .* _ea  .- 3 .* _eea
      _tema = _bt .+ _eeea 
      
      return Indicator(rename(_tema, colnames(ta)))
    end
end

export TEMA

"""
Rate of change
"""
function ROC(;horizon = horizonDefault(), price="Close")
    
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing
      return Indicator(rename(roc(ta, horizon), colnames(ta)))
    end
end

export ROC

"""
Bollinger Band (Upper/mean/Lower)
"""
function _bollinger(ta, horizon, width, type)
  
  _fubb = nothing

  for name in colnames(ta)
    _tubb = rename(bollingerbands(ta[name], horizon, width)[type], [name])

    if _fubb == nothing
      _fubb = _tubb
    else
      _fubb = merge(_fubb, _tubb, :outer)
    end
  end

  return _fubb
end

"""
Upper Bollinger Band
"""
function UBB(;horizon = horizonDefault(), price="Close", width = 2.0)
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing  
      return Indicator(_bollinger(ta, horizon, Float64(width), :up))
    end
end

"""
Middle Bollinger Band 
"""
function MBB(;horizon = horizonDefault(), price="Close", width = 2.0)
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing  
      return Indicator(_bollinger(ta, horizon, Float64(width), :mean))
    end
end

"""
Lower Bollinger Band 
"""
function LBB(;horizon = horizonDefault(), price="Close", width = 2.0)
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing  
      return Indicator(_bollinger(ta, horizon, Float64(width), :down))
    end
end

export UBB, MBB, LBB


"""
Average Directional Movement Index
"""
function _adx(high, low, close, horizon, type)

    if !(colnames(high) == colnames(low) == colnames(close))
      return nothing
    end

   _fadx = nothing
   all_names = Symbol[]
    for name in colnames(high)
        h = rename(high[name], :High)
        l = rename(low[name], :Low)
        c = rename(close[name], :Close)

        hlc = merge(merge(h, l, :outer), c, :outer)

        # println(hlc)
        
        _tadx = hlc != nothing ? rename(adx(hlc,horizon)[type], [name]) : nothing

        # println(_tadx)

        if _tadx != nothing
          push!(all_names, name)
          _fadx = _fadx == nothing ?  _tadx :  merge(_fadx, _tadx, :outer)
        end

    end

    if _fadx != nothing
      return rename(_fadx, all_names)
    end
end

function ADX(;horizon = horizonDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon) 
    low = _getTA(price = "Low", horizon = horizon) 

    return Indicator(_adx(high, low, close, horizon, :adx))
end

function PlusDI(;horizon = horizonDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon) 
    low = _getTA(price = "Low", horizon = horizon) 

    return Indicator(_adx(high, low, close, horizon, :di_plus))
end

function MinusDI(;horizon = horizonDefault())
    
   close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon) 
    low = _getTA(price = "Low", horizon = horizon) 

    return Indicator(_adx(high, low, close, horizon, :di_minus))
end

export ADX, PlusDI, MinusDI


"""
Relative Strength Indicator
"""
function RSI(;horizon = horizonDefault(), price = "Close", wilder = false)
    
    ta = _getTA(price = price, horizon = horizon)

    if ta != nothing
      return Indicator(rename(rsi(ta, horizon, wilder = wilder), colnames(ta)))
    end
end

export RSI


"""
Commodity Channel Index
"""
function CCI(;horizon=horizonDefault())
    
    close = _getTA(price = "Close")
    high = _getTA(price = "High")
    low = _getTA(price = "Low")

    _fcci = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)   
      _tcci = nothing
    
      if hlc != nothing
        _tcci = cci(hlc, horizon)
      end 

      if _tcci != nothing
        push!(all_names, name)
        _fcci = _fcci == nothing ? _tcci : merge(_fcci, _tcci)
      end
    end

    if _fcci != nothing
      return Indicator(rename(_fcci, all_names))
    end
end

export CCI


fastMACDDefault() = 10
slowMACDDefault() = 60
signalMACDDefault() = 30

function _macd(ta, fast, slow, signal, wilder, type)
  _fmacd = nothing

  for name in colnames(ta)
    _tmacd = rename(macd(ta[name], fast, slow, signal, wilder = wilder)[type], [name])

    if _fmacd == nothing
      _fmacd = _tmacd
    else
      _fmacd = merge(_fmacd, _tmacd, :outer)
    end
  end

  return _fmacd
end

"""
Moving Average Convergence Divergence (MACD)
"""
function MACD(;price = "Close", wilder = false, fast = fastMACDDefault(), slow = slowMACDDefault(), signal = signalMACDDefault())
    
    ta = _getTA(price = price)

    if ta != nothing
      return Indicator(_macd(ta, fast, slow, signal,wilder, :macd))
    end
end


"""
Moving Average Convergence Divergence (MACD)
"""
function MACDSignal(;price = "Close", wilder = false, fast = fastMACDDefault(), slow = slowMACDDefault(), signal = signalMACDDefault())
    
    ta = _getTA(price = price)

    if ta != nothing
      return Indicator(_macd(ta, fast, slow, signal, wilder, :signal))
    end
end

export MACD, MACDSignal


# Lag based price and Volume
"""
Previous Close
"""
function PrevCLOSE()
    ta = _getTA(price = "Close")

    if ta != nothing
      return Indicator(lag(ta, 1, padding=true))
    end
end

"""
Previous Open
"""
function PrevOPEN()
    ta = _getTA(price = "Open")

    if ta != nothing
      return Indicator(lag(ta, 1, padding=true))
    end
end

"""
Previous High
"""
function PrevHIGH()
    ta = _getTA(price = "High")

    if ta != nothing
      return Indicator(lag(ta, 1, padding=true))
    end
end

"""
Previous Low
"""
function PrevLOW()
    ta = _getTA(price = "Low")

    if ta != nothing
      return Indicator(lag(ta, 1, padding=true))
    end
end

"""
Previous Volume
"""
function PrevVOL()
    ta = _getTA(price = "Volume")

    if ta != nothing
      return Indicator(lag(ta, 1, padding=true))
    end
end

"""
Lagged Close
"""
function LagCLOSE(;period = 1)
    if period < 0
      return nothing
    end

    ta = _getTA(price = "Close", horizon = period + 1)

    if ta != nothing
      return Indicator(lag(ta, period, padding=true))
    end
end

"""
Lagged Open
"""
function LagOPEN(;period = 1)
    if period < 0
      return nothing
    end

    ta = _getTA(price = "Open", horizon = period + 1)

    if ta != nothing
      return Indicator(lag(ta, period, padding=true))
    end
end

"""
Lagged High
"""
function LagHIGH(;period = 1)
    if period < 0
      return nothing
    end

    ta = _getTA(price = "High", horizon = period + 1)

    if ta != nothing
      return Indicator(lag(ta, period, padding=true))
    end
end

"""
Lagged Low
"""
function LagLOW(;period = 1)
    if period < 0
      return nothing
    end

    ta = _getTA(price = "Low", horizon = period + 1)

    if ta != nothing
      return Indicator(lag(ta, period, padding=true))
    end
end

"""
Lagged Volume
"""
function LagVOL(;period = 1)
    if period < 0
      return nothing
    end

    ta = _getTA(price = "Volume", horizon = period + 1)

    if ta != nothing
      return Indicator(lag(ta, period, padding=true))
    end
end

export PrevOPEN, PrevHIGH, PrevLOW, PrevCLOSE, PrevVOL, LagOPEN, LagHIGH, LagLOW, LagCLOSE, LagVOL


"""
Typical Price (H+L+C/3)
"""
function TYPICAL()
    
    close = _getTA(price = "Close")
    high = _getTA(price = "High")
    low = _getTA(price = "Low")

    _ftyp = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)   
      _ttyp = nothing
    
      if hlc != nothing
        _ttyp = typical(hlc)
      end 

      if _ttyp != nothing
        push!(all_names, name)
        _ftyp = _ftyp == nothing ? _ttyp : merge(_ftyp, _ttyp)
      end
    end

    if _ftyp != nothing
      return Indicator(rename(_ftyp, all_names))
    end
end

export TYPICAL

"""
Volume Weighted Adjusted Price
"""
function VWAP(;price = "Close", horizon = horizonDefault())
    
    ta = _getTA(price = price, horizon = horizon)
    volume = _getTA(price = "Volume", horizon = horizon)

    _fvwap = nothing
    all_names = Symbol[]

    for name in colnames(ta)
      
      _tvwap = nothing
      v = volume[name]
      p = ta[name]

      pv = merge(rename(p, [:Close]), rename(v, [:Volume]), :inner)

      if pv != nothing
        _tvwap = vwap(pv, horizon)    
      end

      if _tvwap != nothing
          push!(all_names, name)
          _fvwap =  _fvwap == nothing ? _tvwap : merge(_fvwap, _tvwap, :outer)
      end
    end

    if _fvwap != nothing 
        return Indicator(rename(_fvwap, all_names))
    end
end


"""
On Balance Volume
"""
function OBV()
    ta = _getTA(price = "Close")
    volume = _getTA(price = "Volume")

    _fobv = nothing
    all_names = Symbol[]

    for name in colnames(ta)
      
      _tobv = nothing
      v = volume[name]
      p = ta[name]

      pv = merge(rename(p, [:Close]), rename(v, [:Volume]), :inner)

      if pv != nothing
        _tobv = obv(pv)    
      end

      if _tobv != nothing
          push!(all_names, name)
          _fobv =  _fobv == nothing ? _tobv : merge(_fobv, _tobv, :outer)
      end
    end

    if _fobv != nothing 
        return Indicator(rename(_fobv, all_names))
    end
end

export VWAP, OBV


"""
True Range
"""
function TRUERANGE()
    
    close = _getTA(price = "Close")
    high = _getTA(price = "High")
    low = _getTA(price = "Low")

    _ftr = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)      
      _ttr = nothing
    
      if hlc != nothing
        _ttr = truerange(hlc)
      end 

      if _ttr != nothing
        push!(all_names, name)
        _ftr = _ftr == nothing ? _ttr : merge(_ftr, _ttr)
      end
    end

    if _ftr != nothing
      return Indicator(rename(_ftr, all_names))
    end
end

"""
Average True Range
"""
function AVGTRUERANGE(;horizon = horizonDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _fatr = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)      
      _tatr = nothing
    
      if hlc != nothing
        _tatr = atr(hlc, horizon)
      end 

      if _tatr != nothing
        push!(all_names, name)
        _fatr = _fatr == nothing ? _tatr : merge(_fatr, _tatr)
      end
    end

    if _fatr != nothing
      return Indicator(rename(_fatr, all_names))
    end
end

export TRUERANGE, AVGTRUERANGE


"""
Accumulation/Distribution Line
"""
function ADL()
    
    volume = _getTA(price = "Volume")
    close = _getTA(price = "Close")
    high = _getTA(price = "High")
    low = _getTA(price = "Low")

    _fadl = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlcv = merge(merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer), rename(volume[name], [:Volume]), :outer)      
      _tadl = nothing
    
      if hlcv != nothing
        _tadl = adl(hlcv)
      end 

      if _tadl != nothing
        push!(all_names, name)
        _fadl = _fadl == nothing ? _tadl : merge(_fadl, _tadl)
      end
    end

    if _fadl != nothing
      return Indicator(rename(_fadl, all_names))
    end
end

export ADL

function _aroon(high, low, horizon, type)
   _farn = nothing
    all_names = Symbol[]
    for name in colnames(high)

       hl = merge(rename(low[name], [:Low]), rename(high[name], [:High]), :outer)
      _tarn = nothing
    
      if hl != nothing
        _tarn = aroon(hl, horizon)[type]
      end 

      if _tarn != nothing
        push!(all_names, name)
        _farn = _farn == nothing ? _tarn : merge(_farn, _tarn)
      end
    end

    if _farn != nothing
      return Indicator(rename(_farn, all_names))
    end
end

"""
Aroon Oscillator (UP)
"""
function AROON_UP(;horizon = horizonDefault())
    
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return _aroon(high, low, horizon, :up)    
end

"""
Aroon Oscillator (DOWN)
"""
function AROON_DOWN(;horizon = horizonDefault())
    
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return _aroon(high, low, horizon, :down)    
end

"""
Aroon Oscillator (OSC)
"""
function AROON_OSC(;horizon = horizonDefault())
    
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return _aroon(high, low, horizon, :osc)    
end

export AROON_OSC, AROON_UP, AROON_DOWN


smoothChaikinDefault() = 20

"""
Chaikin Volatility
"""
function CHAIKIN_VOL(;horizon = horizonDefault(), smooth = smoothChaikinDefault())

    high = _getTA(price = "High", horizon = horizon + smooth)
    low = _getTA(price = "Low", horizon = horizon + smooth)

    _fcvl = nothing
    all_names = Symbol[]
    for name in colnames(high)

       hl = merge(rename(low[name], [:Low]), rename(high[name], [:High]), :outer)
      _tcvl = nothing
    
      if hl != nothing
        _tcvl = chaikinvolatility(hl, smooth, horizon)
      end 

      if _tcvl != nothing
        push!(all_names, name)
        _fcvl = _fcvl == nothing ? _tcvl : merge(_fcvl, _tcvl)
      end
    end

    if _fcvl != nothing
      return Indicator(rename(_fcvl, all_names))
    end
end

export CHAIKIN_VOL


function _donchian(high, low, horizon, type)
    _fdnch = nothing
    all_names = Symbol[]
    for name in colnames(high)

       hl = merge(rename(low[name], [:Low]), rename(high[name], [:High]), :outer)
      _tdnch = nothing
    
      if hl != nothing
        _tdnch = donchianchannels(hl, horizon)[type]
      end 

      if _tdnch != nothing
        push!(all_names, name)
        _fdnch = _fdnch == nothing ? _tdnch : merge(_fdnch, _tdnch)
      end
    end

    if _fdnch != nothing
      return Indicator(rename(_fdnch, all_names))
    end
end

"""
Donchian Channel (UP)
"""
function DONCHIAN_UP(;horizon = horizonDefault())

    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return _donchian(high, low, horizon, :up)  
end


"""
Donchian Channel (DOWN)
"""
function DONCHIAN_DOWN(;horizon = horizonDefault())

    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return _donchian(high, low, horizon, :down)  
end

"""
Donchian Channel (MID)
"""
function DONCHIAN_MID(;horizon = horizonDefault())

    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return _donchian(high, low, horizon, :mid)  
end

export DONCHIAN_UP, DONCHIAN_DOWN, DONCHIAN_MID


fastChaikinDefault() = 10
slowChaikinDefault() = 30

"""
Chaikin Oscillator
"""
function CHAIKIN_OSC(;fast = fastChaikinDefault(), slow = slowChaikinDefault())
    
    close = _getTA(price = "Close", horizon = max(fast, slow))
    high = _getTA(price = "High", horizon = max(fast, slow))
    low = _getTA(price = "Low", horizon = max(fast, slow))
    volume = _getTA(price = "Volume", horizon = max(fast, slow))

    _fchosc = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlcv = merge(merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer), rename(volume[name], [:Volume]), :outer)      
      _tchosc = nothing
    
      if hlcv != nothing
        _tchosc = chaikinoscillator(hlcv, fast, slow)
      end 

      if _tchosc != nothing
        push!(all_names, name)
        _fchosc = _fchosc == nothing ? _tchosc : merge(_fchosc, _tchosc)
      end
    end

    if _fchosc != nothing
      return Indicator(rename(_fchosc, all_names))
    end
end

export CHAIKIN_OSC


fastStochasticDefault() = 10
slowStochasticDefault() = 30

"""
Stochastic Oscillator
"""
# function STOCHASTIC_OSC(;horizon = horizonDefault(), fast = fastStochasticDefault(), slow = slowStochasticDefault())
    
#     close = _getTA("Close", horizon = max(fast, slow))
#     high = _getTA("High", horizon = max(fast, slow))
#     low = _getTA("Low", horizon = max(fast, slow))

#     _fstosc = nothing
#     all_names = Symbol[]
#     for name in colnames(close)

#        hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)   
#       _tstosc = nothing
    
#       if hlc != nothing
#         _tchosc = stochasticoscillator(hlc, horizon, fast, slow) ##? Three outputs...which one to use
#       end 

#       if _tchosc != nothing
#         push!(all_names, name)
#         _fchosc = _fchosc == nothing ? _tchosc : merge(_fchosc, _tchosc)
#       end
#     end

#     if _fchosc != nothing
#       return Indicator(rename(_fchosc, all_names))
#     end
# end

# export STOCHASTIC_OSC

end #end module
