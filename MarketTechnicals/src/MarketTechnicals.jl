__precompile__()

module MarketTechnicals

using Reexport
using StatsBase
using Statistics

@reexport using TimeSeries

export sma, ema, kama, env,
       bollingerbands, truerange, atr, keltnerbands, chaikinvolatility, donchianchannels,
       obv, vwap, adl,
       doji,
       rsi, macd, cci, roc, adx, stochasticoscillator, chaikinoscillator, aroon,
       floorpivots, woodiespivots,
       typical

_nanmean(x) = mean(filter(!isnan, x))
nanmean(x; dims = 1) = ndims(x) > 1 ? mapslices(_nanmean, x, dims = dims) : _nanmean(x)

_nansum(x) = sum(filter(!isnan,x))
nansum(x; dims = 1) = ndims(x) > 1 ? mapslices(_nansum, x, dims = dims) : _nansum(x)

_nanstd(x) = std(filter(!isnan,x))
nanstd(x; dims = 1) = ndims(x) > 1 ? mapslices(_nanstd, x, dims = dims) : _nanstd(x)

nancumsum(x) = cumsum(filter(!isnan,x))

include("candlesticks.jl")
include("levels.jl")
include("movingaverages.jl")
include("momentum.jl")
include("utilities.jl")
include("volatility.jl")
include("volume.jl")

# for user customization
# FIXME: using @__DIR__ while we upgrade to julia 0.6+
RC_FILE = joinpath(dirname(@__FILE__), ".rc.jl")
if !ispath(RC_FILE)
    touch(RC_FILE)
end

include(RC_FILE)

end
