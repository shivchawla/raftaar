using JSON

function getindexconstituents(index::String)
    if index == ""
        index = "Nifty 50"
    end

    universe = Vector{String}()
    try
        universemap = JSON.parsefile(Base.source_dir()*"/../Benchmark/Files/universemap.json")
        indexfilename = universemap[index]

        #println(Base.source_dir()*"../Benchmark/Files/universemap.json");
        (column_data, header_data) = readdlm(Base.source_dir()*"/../Benchmark/Files/$(indexfilename)", ',', String, header=true)
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
