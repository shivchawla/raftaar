__precompile__(true)
module UtilityAPI

using API
using Utilities
import Utilities: price_returns, stddev, beta

function price_returns(tickers, series::String, frequency::Symbol; window::Int=22, total::Bool=false, rettype::Symbol=:log)
    
    Utilities.price_returns(tickers, series, frequency, window, getcurrentdatetime(), total=total, rettype=rettype)
     
end

function stddev(tickers, series::String, frequency::Symbol; window::Int = 22, 
                 returns=true, rettype::Symbol=:log)
    
    Utilities.stddev(ticker, series, frequency, window, getcurrentdatetime(), returns=returns, rettype=rettype)
    
end

function beta(tickers, frequency::Symbol; window::Int = 252, 
                benchmark="CNX_NIFTY", rettype::Symbol=:log, series::String = "Close")
    
    Utilities.beta(tickers, frequency, window, getcurrentdatetime(), 
            benchmark=benchmark, rettype=rettype, series=series)    
end

end

