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

#Helper function to find min/max 
function nanmax(x) 
  x[isnan.(x)] .= -Inf
  maximum(x)
end

function nanmin(x) 
  x[isnan.(x)] .= Inf
  minimum(x)
end


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

    x = ind._ta .- val
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
Keltner Band (Upper/Lower)
"""
function _keltner(high, low, close, horizon, width, type)
  
  _fubb = nothing

  for name in colnames(close)

    h = rename(high[name], :High)
    l = rename(low[name], :Low)
    c = rename(close[name], :Close)

    hlc = merge(merge(h, l, :outer), c, :outer)

    _tubb = rename(keltnerbands(hlc, horizon, width)[type], [name])

    if _fubb == nothing
      _fubb = _tubb
    else
      _fubb = merge(_fubb, _tubb, :outer)
    end
  end

  return _fubb
end

"""
Upper Keltner Band
"""
function UKB(;horizon = horizonDefault(), width = 2.0)
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return Indicator(_keltner(high, low, close, horizon, Float64(width), :kup))
end


"""
Lower Keltner Band 
"""
function LKB(;horizon = horizonDefault(), width = 2.0)
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    return Indicator(_keltner(high, low, close, horizon, Float64(width), :kdn))
end

export UKB, LKB


"""
Average Directional Movement Index
"""
function _adx(high, low, close, horizon, type)

    # Removing this check
    # Assuming all names are available
    # Check should be added on sorted array (and not as it is)
    # if !(colnames(high) == colnames(low) == colnames(close))
    #   return nothing
    # end

   _fadx = nothing
   all_names = Symbol[]
    for name in colnames(high)
        h = rename(high[name], :High)
        l = rename(low[name], :Low)
        c = rename(close[name], :Close)

        hlc = merge(merge(h, l, :outer), c, :outer)
        
        _tadx = hlc != nothing ? rename(adx(hlc,horizon)[type], [name]) : nothing

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


fastTSIDefault() = 10
slowTSIDefault() = 25

"""
True Strength Index
"""
function TSI(;slow = slowTSIDefault(), fast = fastTSIDefault())

  close = _getTA(price = "Close", horizon = max(slow, fast))

  _ftsi = nothing
  all_names = Symbol[]
  for name in colnames(close)

     c = rename(close[name], [:Close])
    _ttsi = nothing
  
    if c != nothing
      _ttsi = rename(tsi(c, slow, fast), [name]) 
    end 

    if _ttsi != nothing
      push!(all_names, name)
      _ftsi = _ftsi == nothing ? _ttsi : merge(_ftsi, _ttsi)
    end
  end

  if _ftsi != nothing
    return Indicator(rename(_ftsi, all_names))
  end
end

export TSI


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

function _vortex(high, low, close, horizon, type)
    _fvrtx = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)   
      _tvrtx = nothing
      
      if hlc != nothing
        _tvrtx = rename(vortex(hlc, horizon)[type], [name]) 
      end 

      if _tvrtx != nothing
        push!(all_names, name)
        _fvrtx = _fvrtx == nothing ? _tvrtx : merge(_fvrtx, _tvrtx)
      end
    end

    if _fvrtx != nothing
      return Indicator(rename(_fvrtx, all_names))
    end
end


"""
Plus Vortex
"""
function PlusVORTEX(;horizon = horizonDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

   _vortex(high, low, close, horizon, :v_plus)

end


"""
Minus Vortex
"""
function MinusVORTEX(;horizon = horizonDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _vortex(high, low, close, horizon, :v_minus)

end


export PlusVORTEX, MinusVORTEX


"""
TRIX
"""
function TRIX(;horizon = horizonDefault())

  close = _getTA(price = "Close", horizon = horizon)

  _ftrx = nothing
  all_names = Symbol[]
  for name in colnames(close)

     c = rename(close[name], [:Close])
    _ttrx = nothing
  
    if c != nothing
      _ttrx = trix(c, horizon) 
    end 

    if _ttrx != nothing
      push!(all_names, name)
      _ftrx = _ftrx == nothing ? _ttrx : merge(_ftrx, _ttrx)
    end
  end

  if _ftrx != nothing
    return Indicator(rename(_ftrx, all_names))
  end
end

export TRIX


"""
MASS INDEX
"""
function MASSINDEX(;fast = fastStochasticDefault(), slow = slowStochasticDefault())
    
    high = _getTA(price = "High", horizon = max(fast, slow))
    low = _getTA(price = "Low", horizon = max(fast, slow))

    _fmi = nothing
    all_names = Symbol[]
    for name in colnames(high)

       hl = merge(rename(low[name], [:Low]), rename(high[name], [:High]), :outer)
      
      _tmi = nothing
    
      if hl != nothing
        _tmi = massindex(hl, fast, slow) 
      end 

      if _tmi != nothing
        push!(all_names, name)
        _fmi = _fmi == nothing ? _tmi : merge(_fmi, _tmi)
      end
    end

    if _fmi != nothing
      return Indicator(rename(_fmi, all_names))
    end
end


export MASSINDEX


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
function MACD(;price = "Close", fast = fastMACDDefault(), slow = slowMACDDefault(), signal = signalMACDDefault(), wilder = false)
    
    ta = _getTA(price = price)

    if ta != nothing
      return Indicator(_macd(ta, fast, slow, signal, wilder, :macd))
    end
end


"""
Moving Average Convergence Divergence (MACD)
"""
function MACDSignal(;price = "Close", fast = fastMACDDefault(), slow = slowMACDDefault(), signal = signalMACDDefault(), wilder = false)
    
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


"""
N Day High (Period High)
"""
function PeriodHIGH(;period = 1)
    if period < 0
      return nothing
    end

    ta = _getTA(price = "High", horizon = period + 1)

    if ta != nothing
      return Indicator(moving(nanmax, ta, period, padding=true))
    end
end

"""
N Day Low (Period Low)
"""
function PeriodLOW(;period = 1)
    if period < 0
      return nothing
    end

    ta = _getTA(price = "Low", horizon = period + 1)

    if ta != nothing
      return Indicator(moving(nanmin, ta, period, padding=true))
    end

end

export PrevOPEN, PrevHIGH, PrevLOW, PrevCLOSE, PrevVOL, LagOPEN, LagHIGH, LagLOW, LagCLOSE, LagVOL, PeriodHIGH, PeriodLOW


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


"""
Chaikin Money Flow
"""
function CHAIKINMONEYFLOW(;horizon = horizonDefault())
    
    volume = _getTA(price = "Volume", horizon = horizon)
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _fcmf = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlcv = merge(merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer), rename(volume[name], [:Volume]), :outer)      
      _tcmf = nothing
    
      if hlcv != nothing
        _tcmf = chaikinmoneyflow(hlcv, horizon)
      end 

      if _tcmf != nothing
        push!(all_names, name)
        _fcmf = _fcmf == nothing ? _tcmf : merge(_fcmf, _tcmf)
      end
    end

    if _fcmf != nothing
      return Indicator(rename(_fcmf, all_names))
    end
end

export CHAIKINMONEYFLOW


"""
Force Index
"""
function FORCEINDEX(;horizon = horizonDefault())
    
    volume = _getTA(price = "Volume", horizon = horizon)
    close = _getTA(price = "Close", horizon = horizon)
    
    _ffi = nothing
    all_names = Symbol[]
    for name in colnames(close)

       cv = merge(rename(close[name], [:Close]), rename(volume[name], [:Volume]), :outer)
      _tfi = nothing
    
      if cv != nothing
        _tfi = forceindex(cv, horizon)
      end 

      if _tfi != nothing
        push!(all_names, name)
        _ffi = _ffi == nothing ? _tfi : merge(_ffi, _tfi)
      end
    end

    if _ffi != nothing
      return Indicator(rename(_ffi, all_names))
    end
end

export FORCEINDEX


"""
Ease of Movement
"""
function EASEOFMOVEMENT(;horizon = horizonDefault())
    
    volume = _getTA(price = "Volume", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _feom = nothing
    all_names = Symbol[]
    for name in colnames(high)

       hlv = merge(merge(rename(low[name], [:Low]), rename(high[name], [:High]), :outer), rename(volume[name], [:Volume]), :outer)      
      _teom = nothing
    
      if hlv != nothing
        _teom = easeofmovement(hlv, horizon)
      end 

      if _teom != nothing
        push!(all_names, name)
        _feom = _feom == nothing ? _teom : merge(_feom, _teom)
      end
    end

    if _feom != nothing
      return Indicator(rename(_feom, all_names))
    end
end

export EASEOFMOVEMENT



"""
Volume Price Trend
"""
function VOLUMEPRICETREND(;horizon = horizonDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    volume = _getTA(price = "Volume", horizon = horizon)

    _fvpt = nothing
    all_names = Symbol[]

    for name in colnames(close)
      
      _tvpt = nothing
      v = volume[name]
      c = close[name]

      cv = merge(rename(c, [:Close]), rename(v, [:Volume]), :inner)

      if cv != nothing
        _tvpt = volumepricetrend(cv, horizon)    
      end

      if _tvpt != nothing
          push!(all_names, name)
          _fvpt =  _fvpt == nothing ? _tvpt : merge(_fvpt, _tvpt, :outer)
      end
    end

    if _fvpt != nothing 
        return Indicator(rename(_fvpt, all_names))
    end
end

export VOLUMEPRICETREND


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

function _stochastic(high, low, close, horizon, fast, slow, type)
    _fstosc = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)   
      _tstosc = nothing
    
      if hlc != nothing
        _tstosc = stochasticoscillator(hlc, horizon, fast, slow)[type] ##? Three outputs...which one to use
      end 

      if _tstosc != nothing
        push!(all_names, name)
        _fstosc = _fstosc == nothing ? _tstosc : merge(_fstosc, _tstosc)
      end
    end

    if _fstosc != nothing
      return Indicator(rename(_fstosc, all_names))
    end
end


"""
Stochastic Oscillator (Fast K)
"""
function STOCHASTIC_OSC_FASTK(;horizon = horizonDefault(), fast = fastStochasticDefault(), slow = slowStochasticDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _stochastic(high, low, close, horizon, fast, slow, :fast_k)
end


"""
Stochastic Oscillator (Fast D)
"""
function STOCHASTIC_OSC_FASTD(;horizon = horizonDefault(), fast = fastStochasticDefault(), slow = slowStochasticDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _stochastic(high, low, close, horizon, fast, slow, :fast_d)
end


"""
Stochastic Oscillator (Slow D)
"""
function STOCHASTIC_OSC_SLOWD(;horizon = horizonDefault(), fast = fastStochasticDefault(), slow = slowStochasticDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _stochastic(high, low, close, horizon, fast, slow, :slow_d)
end

export STOCHASTIC_OSC_FASTK, STOCHASTIC_OSC_FASTD, STOCHASTIC_OSC_SLOWD 


#Adding new indicators (on 15/04/2019)

"""
Awesome Oscillator
"""
function AWESOME_OSC(;fast = fastStochasticDefault(), slow = slowStochasticDefault())
    
    high = _getTA(price = "High", horizon = max(fast, slow))
    low = _getTA(price = "Low", horizon = max(fast, slow))

    _fawosc = nothing
    all_names = Symbol[]
    for name in colnames(high)

       hl = merge(rename(low[name], [:Low]), rename(high[name], [:High]), :outer) 
      
      _tawosc = nothing
      if hl != nothing
        _tawosc = awesomeoscillator(hl, fast, slow) 
      end 

      if _tawosc != nothing
        push!(all_names, name)
        _fawosc = _fawosc == nothing ? _tawosc : merge(_fawosc, _tawosc)
      end
    end

    if _fawosc != nothing
      return Indicator(rename(_fawosc, all_names))
    end
end

export AWESOME_OSC


"""
Williams R
"""
function WILLIAMSR(;horizon = horizonDefault())
    
    close = _getTA(price = "Close", horizon = horizon)
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)

    _fwlm = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlc = merge(merge(rename(low[name], [:Low]), rename(close[name], [:Close]), :outer), rename(high[name], [:High]), :outer)   
      _twlm = nothing
    
      if hlc != nothing
        _twlm = williamsr(hlc, horizon) 
      end 

      if _twlm != nothing
        push!(all_names, name)
        _fwlm = _fwlm == nothing ? _twlm : merge(_fwlm, _twlm)
      end
    end

    if _fwlm != nothing
      return Indicator(rename(_fwlm, all_names))
    end
end

export WILLIAMSR


"""
Detrending Price Oscillator
"""
function DPO_OSC(;horizon = horizonDefault())

  close = _getTA(price = "Close", horizon = horizon)

  _fdpo = nothing
  all_names = Symbol[]
  for name in colnames(close)

     c = rename(close[name], [:Close])
    _tdpo = nothing
  
    if c != nothing
      _tdpo = dpo(c, horizon) 
    end 

    if _tdpo != nothing
      push!(all_names, name)
      _fdpo = _fdpo == nothing ? _tdpo : merge(_fdpo, _tdpo)
    end
  end

  if _fdpo != nothing
    return Indicator(rename(_fdpo, all_names))
  end
end

export DPO_OSC


"""
Money Flow Index
"""
function MONEYFLOWINDEX(;horizon = horizonDefault())
    
    high = _getTA(price = "High", horizon = horizon)
    low = _getTA(price = "Low", horizon = horizon)
    close = _getTA(price = "Close", horizon = horizon)
    volume = _getTA(price = "Volume", horizon = horizon)

    _fmfi = nothing
    all_names = Symbol[]
    for name in colnames(close)

       hlcv = merge(
              merge(
                merge(rename(low[name], [:Low]), rename(high[name], [:High]), :outer),
                  rename(close[name], [:Close]), :outer),
                    rename(volume[name], [:Volume]), :outer)

      _tmfi = nothing
    
      if hlcv != nothing
        _tmfi = moneyflowindex(hlcv, horizon) 
      end 

      if _tmfi != nothing
        push!(all_names, name)
        _fmfi = _fmfi == nothing ? _tmfi : merge(_fmfi, _tmfi)
      end
    end

    if _fmfi != nothing
      return Indicator(rename(_fmfi, all_names))
    end
end

export MONEYFLOWINDEX


end #end module
