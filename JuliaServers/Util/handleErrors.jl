# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

import Base: exit, quit, run
using BufferedStreams

#overwriting Base.exit
# function exit(code=0)
#     warn_static("Illegal Action at exit()")
# end

# function quit()
#     warn_static("Illegal Action at quit()")
# end

# function _run(command::Any)
#     warn_static("Illegal Action at run()")
# end

function handleexception(err::Any, forward=false)

    out = BufferedOutputStream()
    showerror(out, err)
    msg = String(take!(out))
    close(out)
    
    st = stacktrace(catch_backtrace())

    stack_msg = ""
    found_in_stack=false
    
    # logic to get line and function number from user algo
    try
        lines = []
        for err in reverse(st) 
            err = string(err)
            
            if fname!="" && !found_in_stack
                if first(something(findfirst(fname, err), 0:-1)) > 0 
                    
                    lines = split(err, fname*":")
                    
                    #special logic to get function and line number
                    stack_msg *="\n\n" * (length(lines) == 2 ? msg*" in "*string(lines[1])*" line:"*string(parse(lines[2]) - 20) : msg)
                    found_in_stack=true
                    continue    
                end
            end

            #=if found_in_stack
                stack_msg*="\n\n$err"
            end=#
        end
    catch err
                
    end

    if found_in_stack 
        msg=stack_msg
    end 

    msg = replace(msg, "/home/admin/raftaar/" => "..")
    msg = replace(msg, "/home/jp/raftaar/" => "..")
    msg = replace(msg, "/home/jp/local/" => "..")
    msg = replace(msg, "BackTester." => "")
    
    Logger.error(msg)

    # This prevents the final stats to be trasmitted to the backend as FINAL OUTPUT
    # THIS BECAME FINAL OUTPUT (HENCE COMMENTED)
    # if !forward
    #     _outputbacktestlogs()
    # end
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
