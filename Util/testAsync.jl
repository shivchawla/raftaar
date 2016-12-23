

try
    t = Timer(5)
    
    done = false;
    @async begin
        try
       
            wait(t)
            
            if(!done)
                throw(DomainError())
            end
        catch e
            println(e)
            println("now caught here")
            exit(0)
            #rethrow()
        end
    end
    i=0
    while i < 10000000000 
        i = i+1
        println(4)
    end

    done = true
    
catch e
    println(e)
    println("Caught Error as well")
end

println("Out of main program")
