
__precompile__(true)
module Utilities

using YRead
using TimeSeries
using DataFrames
using GLM
import Base: beta
using MultivariateStats

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
    
    if(length(tickers) == 0) 
        return nothing
    end
    
    #Fetch prices for horizon    
    prices = YRead.history(tickers, series, :Day, horizon, enddate)
    _compute_returns(prices, rettype, total) 
end
export price_returns

function stddev(tickers, series::String, frequency::Symbol, horizon::Int, enddate::DateTime; 
                returns=true, rettype::Symbol=:log)
    
    if(length(tickers) == 0) 
        return nothing
    end

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

function beta_old(tickers, frequency::Symbol, horizon::Int, enddate::DateTime; 
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

    #@sync @parallel 
    for i in 1:nNames
        name = names[i]
        ta = TimeSeries.dropnan(m_ta[benchmark, name], :any)
        df = DataFrame(X = values(ta[benchmark]), Y = values(ta[name]))

        b = 1.0
        a = 0.0
        s = 1.0

        if(size(df, 1) > 22)
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

    #convert to normal array
    bta = Vector{Float64}(bta)
    alpha = Vector{Float64}(alpha)
    stability = Vector{Float64}(stability)

    nrow = size(bta)[1]
    ts = timestamp(rets_ts)[end]
    (TimeArray(ts, reshape(bta, (1, nrow)), names), TimeArray(ts, reshape(alpha, (1, nrow)), names), TimeArray(ts, reshape(stability, (1, nrow)), names))
end

function beta(tickers, frequency::Symbol, horizon::Int, enddate::DateTime; 
                benchmark="CNX_NIFTY", rettype::Symbol=:log, series::String = "Close")
    
    if(length(tickers) == 0) 
        return nothing
    end

    rets_ts = price_returns(tickers, series, frequency, horizon, enddate, rettype = rettype)
   
    YRead.setstrict(false)
    rets_benchmark = price_returns([benchmark], series, frequency, horizon, enddate, rettype = rettype)
    YRead.setstrict(true)
 
    names = colnames(rets_ts)
    nNames = length(names)
  
    m_ta = merge(rets_benchmark, rets_ts, :outer)

    ret = values(m_ta)
    ret[isnan.(ret)] = 0.0
    cv_mat = cov(ret)
    variance = diag(cv_mat)  
    cv = cv_mat[1, 2:end]  
   
    #beta = Cov(ra,rb)/var(rb)
    bta = (1.0/variance[1]) * cv 
    bta[bta.==0]=1.0

    # Comvert to time-series
    nrow = size(bta)[1]
    ts = timestamp(rets_ts)[end]
    tas = TimeArray(ts, reshape(bta, (1, nrow)), names)
end

export beta

end #end of module
