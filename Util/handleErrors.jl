# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

using BufferedStreams

function showerr(io::IO, exception::Exception, st::StackTrace)
    Base.showerror(io, exception)
    println(io)
    for sf in st 
        println(io, sf)
    end
end

function handleexception(error::Exception)
    
    out = BufferedOutputStream()
    showerr(out, error, catch_stacktrace())
    str = takebuf_string(out) 
  
    errorlist = Vector{String}()

    ss = split(str,'\n')
    line = ""
    
    for err in ss

        err = string(err)
        push!(errorlist, err)
             
        if fname!=""
            if searchindex(err, fname) > 0 
                lines = split(err,",")
                
                if(length(lines) > 1)
                    line = string(lines[2])    
                end
                
            end
        end
    end

    if length(errorlist) > 1
        API.error(errorlist[1]*" "*line)
    elseif length(errorlist) == 1 
        API.error(errorlist[1])
    else
        API.error(string(ss[1]))
    end

    exit(0)

end

