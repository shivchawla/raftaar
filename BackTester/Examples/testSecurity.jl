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
    
    setholdingpct(getsecurity(56145).symbol, 0.2)  
    setholdingshares(getsecurity(56145).symbol, 20)  
    setholdingvalue(getsecurity(56145).symbol, 500000.0)
    cancelopenorders("CNX_BANK")
    
    track("Net Value", state.account.netvalue)
    
end

function beforeclose(state)
    cancelallorders()
end


