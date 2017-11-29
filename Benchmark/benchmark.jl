using JSON

function getindexconstituents(index::String)
    if index == ""
        index = "Nifty 50"
    end

    universe = Vector{String}()
    try
        universemap = JSON.parsefile(source_dir*"/../Benchmark/Constituents/universemap.json")
        indexfilename = universemap[index]

        (column_data, header_data) = readdlm(source_dir*"/../Benchmark/Constituents/$(indexfilename)", ',', String, header=true)
        (nrows,ncols) = size(column_data)
        if nrows > 0
            #SYMBOL corresponds to 3rd column    
            universe = column_data[:,3]
            #universe = [replace(ticker, r"[^a-zA-Z0-9]", "_") for ticker in universe] 
        end
    catch err
        println(err)    
    end

    return universe
end
