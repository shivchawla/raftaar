# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

function handleexception(err::Any)

    msg = errormessage(err)
    
    st = catch_stacktrace()
    errorlist = Vector{String}()

    line = ""
    
    for err in st
        
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

    if line !=""
        msg = msg*" "*line  
    end

    API.error(msg)

end

function errormessage(err::Any)

    if isa(err, UndefVarError)
        return "UndefVarError: "*string(err.var)*" is not defined"
    
    elseif isa(err, MethodError)
        
        tpl = err.args

        str = length(tpl) > 1 ? string(err.f)*"(" : ""
        
        if(length(tpl) > 0)
            for i = 1:length(tpl)

                str = str*"::$(typeof(tpl[i]))"
                
                if(i<length(tpl))
                    str=str*", "
                end
            end
            
            str = str*")" 
        end
        return "MethodError: no method matching " *str
    elseif isa(err, LoadError)
        return "LoadError: "*string(err.error)*" at line "*string(err.line - 3)
    else
        return string(err)
    end 
end

