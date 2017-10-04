# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.
import Base: exit, quit

#overwriting Base.exit
function exit(code=0)
    warn_static("Illegal Action at exit()")
end

function quit()
    warn_static("Illegal Action at quit()")
end

function handleexception(err::Any, forward=false)

    msg = errormessage(err)

    st = catch_stacktrace()

    # logic to get line and function number from user algo
    try
        lines = []
        for err in st 
            err = string(err)
            #push!(errorlist, err)
                 
            if fname!=""
                if searchindex(err, fname) > 0 
                    lines = split(err, fname*":")
                    #special logic to get function and line number
                    msg = length(lines) == 2 ? msg*" in "*string(lines[1])*" line:"*string(parse(lines[2]) - 20) : msg    
                end
            end
        end
    end

    #replace "Raftaar."
    msg = replace(msg, "Raftaar.", "")
    
    API.error(msg)

    if !forward
        _outputbacktestlogs()
    end
end

function errormessage(err::Any)

    if isa(err, UndefVarError)
        return "UndefVarError: "*string(err.var)*" is not defined"
    
    elseif isa(err, MethodError)
        
        tpl = err.args

        str = length(tpl) > 0 ? string(err.f)*"(" : ""
        
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

