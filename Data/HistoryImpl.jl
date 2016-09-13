
using Quandl
using DataFrames

include("../DataTypes/Price.jl")

#=function historyfromquandl(security::ASCIIString, startdate, enddate, resolution::Resolution, field::FieldType)
    quandlget(security, order="des", rows=0, frequency="daily", transformation="none",
                   from=startdate, to=enddate, format="DataFrame", api_key="")#["Close"]
end

function historyfromquandl(securities::Array{ASCIIString}, startdate, enddate, resolution::Resolution, field::FieldType)
    
    bigdf = DataFrame()
    for security in securities
        #df =  historyfromquandl(security, startdate, enddate, resolution, field)     
        if bigdf == DataFrame()
            bigdf = df
        else     
            bigdf = join(bigdf, df, on = :Date, kind = :outer)
        end
    end
end=#

function historyfromquandl(security::ASCIIString, period::Int64, resolution::Resolution, field::FieldType)
    if field == FieldType(Close)
        quandlget(security, order="des", rows=period, frequency="daily", transformation="none",
                    from="", to="", format="DataFrame", api_key="")[[:Date, :Close]]
    end
end


function historyfromquandl(securities::Array{ASCIIString}, period::Int64, resolution::Resolution, field::FieldType)
    
    bigdf = DataFrame()
    for security in securities    
        df = historyfromquandl(security, period, resolution, field)[[:Date, :Close]]
        rename!(df, :Close, Symbol(security))
     
        if bigdf == DataFrame()
            bigdf = df
        else     
            bigdf = join(bigdf, df, on = :Date, kind=:outer)
        end
        
    end
    return bigdf
end

function current(symbol::ASCIIString, field::FieldType)
end

function current(symbol::ASCIIString, field::FieldType)
end

function last(symbol::ASCIIString)
end

function last(symbol::ASCIIString)
end


