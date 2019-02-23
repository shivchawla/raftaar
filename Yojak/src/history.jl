
today() = strftime("%F",time()) 

function toTimeArray(data::Array{Any,2}, name::String; frequency::Symbol = :Day)

    #Fix the unique problem in the database (there are many duplicates) 
    dates = [frequency == :Day ? Date(d) : DateTime(d) for d in data[:,1]]

    nrows = length(dates)
    vals = zeros(nrows, 1)

    for r=1:nrows
        vals[r,1] = data[r,2]
    end

    ta = nothing
    
    try
        ta = TimeArray(dates, vals, Symbol.([name]))
    catch err
        println(err)
    end

    return ta  

end 

function adjustdata(data::Array{Any, 2}, name::String)

    z = data[:, 2:4] 
    
    nrows = size(z)[1]
    ncols = size(z)[2]

    vals = zeros(nrows, ncols)
    for i = 1:nrows
        for j=1:ncols

            #values can be nothing or EMPTY strings (need to be handled correctlt)
            if ((z[i,j] == nothing || z[i,j] == "") && j==2)
                vals[i,j] = 1.0
            elseif ((z[i,j] == nothing || z[i,j] == "") && j==3)
                vals[i,j] = 0.0
            elseif ((z[i,j] == nothing) || z[i,j] == "")
                vals[i,j] = NaN
            else
                #SOME ERROR HERE
                #Related to mutable struct conversion
                m = typeof(z[i,j]) == String ? Meta.parse(z[i,j]) : z[i,j]
                vals[i,j] =  m == nothing ? NaN : m       
            end
        end 
    end

    vals = [[Date(d) for d in data[:,1]] vals]

    sortrows(vals, by=x->(x[1]), rev=true)
    
    nrows = size(vals)[1]
    vals[2:end, 2] = round.(vals[2:end, 2] .* cumprod(vals[1:nrows-1, 3]), digits = 2)
    
    fvals = zeros(nrows,1) 
    dates = Vector{Date}(nrows)
    for i = 1:nrows
        fvals[i,1] = vals[i,2]
        dates[i] = vals[i,1]
    end

    adj_ta = TimeArray(dates, fvals, Symbol.([name]))
    
end

function curatedatatype(datatype::String)
    datatype = lowercase(datatype)
    datatype = string(uppercase(datatype[1]))*datatype[2:end]
end

include("history_horizon.jl")
include("history_period.jl")

