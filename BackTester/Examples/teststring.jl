# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#include(\"../Engine/API.jl\")
#using API

using BackTester

function initialize(state::AlgorithmState)  
    
    setuniverse(["CNX_BANK","CNX_NIFTY"])
    
    setcancelpolicy("EOD")
    setresolution("Day")

    setcash(1000000.0)    
end

function beforeopen(state)
end

function ondata(data, state)
    setholdingpct("CNX_BANK", 0.2)  
    
    setholdingshares("CNX_BANK", 20)  

    setholdingvalue("CNX_BANK", 500000.0)

    track("Net Value", state.account.netvalue)
    
end

function beforeclose(state)
    cancelallorders()
end


