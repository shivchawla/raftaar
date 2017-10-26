
__precompile__(true)
module Utilities

using YRead
using TimeSeries
using DataFrames
using GLM
import Base: beta

function _compute_returns(prices::TimeArray, rettype::Symbol, total::Bool)
    
    if total
        first_val = values(TimeSeries.head(prices, 1))
        last_val = values(TimeSeries.tail(prices, 1))

        vs = (rettype == :log) ? log(last_val).-log(first_val) : (last_val .- first_val)./first_val
        rets = TimeArray(timestamp(prices)[end], vs, colnames(prices))
    else
        rets = percentchange(prices, rettype)
    end
end

function price_returns(tickers, series::String, frequency::Symbol, horizon::Int, enddate::DateTime; 
                        total::Bool=false, rettype::Symbol=:log)
    
    #Fetch prices for horizon    
    prices = YRead.history(tickers, series, :Day, horizon, enddate)
    _compute_returns(prices, rettype, total) 
end
export price_returns

function stddev(tickers, series::String, frequency::Symbol, horizon::Int, enddate::DateTime; 
                returns=true, rettype::Symbol=:log)
    
    # Fetch prices for horizon
    if returns
        rets = price_returns(tickers, series, frequency, horizon, enddate, rettype = rettype)
        std(rets)
    else
        prices = YRead.history(tickers, series, :Day, horizon, enddate)
        std(prices)
    end
end
export stddev

function beta(tickers, frequency::Symbol, horizon::Int, enddate::DateTime; 
                benchmark="CNX_NIFTY", rettype::Symbol=:log, series::String = "Close")
    
    rets_ts = price_returns(tickers, series, frequency, horizon, enddate, rettype = rettype)
   
    YRead.setstrict(false)
    rets_benchmark = price_returns([benchmark], series, frequency, horizon, enddate, rettype = rettype)
    YRead.setstrict(true)
 
    names = colnames(rets_ts)
    nNames = length(names)
    bta = SharedArray{Float64}(nNames)
    alpha = SharedArray{Float64}(nNames)
    stability = SharedArray{Float64}(nNames)
    
     
    m_ta = merge(rets_benchmark, rets_ts, :outer)
    @sync @parallel for i in 1:nNames
        name = names[i]
        ta = TimeSeries.dropnan(m_ta[benchmark, name], :any)
        df = DataFrame(X = values(ta[benchmark]), Y = values(ta[name]))
 
        b = 1.0
        a = 0.0
        s = 1.0

        if(size(df, 1) > 2)
            OLS = fit(LinearModel, @formula(Y ~ X), df)
            coefficients = coef(OLS)
            b = coefficients[2]
            a = coefficients[1]
            s = r2(OLS)
        end

        bta[i] = b
        alpha[i] = a
        stability[i] = s

    end

    nrow = size(bta)[1]
    ts = timestamp(rets_ts)[end]
    (TimeArray(ts, reshape(bta, (1, nrow)), names), TimeArray(ts, reshape(alpha, (1, nrow)), names), TimeArray(ts, reshape(stability, (1, nrow)), names))
end
export beta

end #end of module
