# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

(errorRead, errorWrite) = redirect_stderr()

atexit(function ()
    close(errorWrite)
    redirect_stderr(STDOUT)
    
    errorlist = Vector{String}()
    
    i = 1
    for err in eachline(errorRead)
        if searchindex(err, pattern) > 0 || i == 1
            push!(errorlist, err)
        end
        i = i + 1 
    end

    if length(errorlist) > 1
        Logger.error(errorlist[1]*" "*errorlist[2])
    elseif length(errorlist) == 1 
        Logger.error(errorlist[1])
    end

    close(errorRead)
    
end)
