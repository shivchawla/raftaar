# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using BufferedStreams

function showerror(io::IO, exception::Exception, st::StackTrace)
    Base.showerror(io, exception)
    println(io)
    for sf in st 
        println(io, sf)
    end
end

function handleexception(error::Exception)
    
    out = BufferedOutputStream()
    showerror(out, error, catch_stacktrace())
    str = takebuf_string(out) 
  
    errorlist = Vector{String}()

    ss = split(str,'\n')
    for err in ss      
        if(pattern!="")
            if searchindex(err, pattern) > 0 
                push!(errorlist, String(err))
            end
        else 
            println(err)    
        end
    end

    if length(errorlist) > 1
        Logger.error(errorlist[1]*" "*errorlist[2])
    elseif length(errorlist) == 1 
        Logger.error(errorlist[1])
    else
        Logger.error(String(ss[1]))
    end

    exit(0)

end


#=atexit(function ()

    close(errorWrite)
    #redirect_stderr(STDOUT)

    errorlist = Vector{String}()
    
    i = 1

    for err in eachline(errorRead)
        if(pattern!="")
            if searchindex(err, pattern) > 0 
                push!(errorlist, err)
            end
        else 
            println(err)    
        end
    end

    if length(errorlist) > 1
        Logger.error(errorlist[1]*" "*errorlist[2])
    elseif length(errorlist) == 1 
        Logger.error(errorlist[1])
    else
        Logger.error("Internal Exception")
    end
    
    close(errorRead)

end)=#
