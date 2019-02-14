"""
    obv(ohlcv; price="Close", v="Volume")

On Balance Volume

```math
    OBV_t = OBV_{t - 1} +
        'begin{cases}
            volume  & text{if}  close_t > close_{t-1} \\
            0       & text{if}  close_t = close_{t-1} \\
            -volume & text{if}  close_t < close_{t-1}
        end{cases}'
```

"""
function obv(ohlcv::TimeArray{T,N}; price=:Close, v=:Volume) where {T,N}

    ret    = percentchange(ohlcv[price])
    vol     = zeros(length(ohlcv))
    
    _vol_values = values(ohlcv[v])
    _ret_values = values(ret)

    vol[1] = _vol_values[1]

    for i=2:length(ohlcv)
      if _ret_values[i-1] >= 0
        vol[i] += _vol_values[i]
      else _ret_values[i-1] < 0
        vol[i] -= _vol_values[i]
      end
    end

    TimeArray(timestamp(ohlcv), reshape(nancumsum(vol), (length(timestamp(ohlcv)), 1)), [:obv], meta(ohlcv))
end

"""
    vwap(ohlcv, n; price="Close", v="Volume")

Volume Weight-Adjusted Price

```math
    P = 'frac{sum_j P_j Q_j}{sum_j Q_j}  ,text{where Q is the volume}'
```

"""
function vwap(ohlcv::TimeArray{T,N}, n::Int; price=:Close, v=:Volume) where {T,N}
    p   = ohlcv[price]
    q   = ohlcv[v]
    ∑PQ = moving(nansum, p .* q, n)
    ∑Q  = moving(nansum, q, n)
    val = ∑PQ ./ ∑Q

    TimeArray(timestamp(val), values(val), [:vwap], meta(ohlcv))
end

vwap(ohlcv::TimeArray{T,N}) where {T,N} = vwap(ohlcv, 10)

function advance_decline(x)
    #code here
end

function mcclellan_summation(x)
    #code here
end

function williams_ad(x)
    #code here
end

"""
    adl(ohlcv; h="High", l="Low", c="Close", v="Volume")

**Accumulation/Distribution Line**

Developed by Marc Chaikin.

**Formula**

```math
    ADL_t = ADL_{t-1} +
        'frac{(Close_t - Low_t) - (High_t - Close_t)}{High_t - Low_t}'
        'times Volume_t'
```

**Reference**

- [StockCharts]
  (http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:accumulation_distribution_line)
"""
function adl(ohlcv::TimeArray; h=:High, l=:Low, c=:Close, v=:Volume)
    _h = ohlcv[h]
    _l = ohlcv[l]
    _c = ohlcv[c]
    _v = ohlcv[v]

    flow_facor = ((_c .- _l) .- (_h .- _c)) ./ (_h .- _l)
    flow_vol = flow_facor .* _v

    _flowvol_values = values(flow_vol)

    vals = similar(_flowvol_values)
    vals[1] = isnan(_flowvol_values[1]) ? 0.0 : _flowvol_values[1]
    for i ∈ 2:length(_flowvol_values)
        vals[i] = vals[i-1] + (isnan(_flowvol_values[i]) ? 0.0 : _flowvol_values[i])
    end

    TimeArray(timestamp(ohlcv), vals, [:adl], meta(ohlcv))
end
