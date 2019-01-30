# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include(\"../Engine/API.jl\")
#using API

using BackTester

function initialize(state::AlgorithmState)  
    
    setuniverse(["CNX_BANK"])
    
    setcancelpolicy("EOD")
    setresolution("Day")

    setcash(1000000.0)    
end

function beforeopen(state)
end

function ondata(data, state)
    

    setholdingpct(56145, 0.2)  
    
    setholdingshares(56145, 20)  

    setholdingvalue(56145, 500000.0)

    track("Net Value", state.account.netvalue)
    
end

function beforeclose(state)
    cancelallorders()
end


