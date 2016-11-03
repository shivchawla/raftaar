# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


#Backtesting module: Raftaar

__precompile__(true)
module Raftaar

import Base: ==, getindex, setindex!

include("../Algorithm/Algorithm.jl")
#include("../Data/History.jl")
include("../Execution/Commission.jl")
include("../Execution/Slippage.jl")

export Universe, Security, SecuritySymbol,
       Commission, Slippage, Order, TradeBar


export Resolution, CancelPolicy, SecurityType

for s in instances(Resolution)
    @eval export $(Symbol(s))
end

for s in instances(CancelPolicy)
    @eval export $(Symbol(s))
end

for s in instances(SecurityType)
    @eval export $(Symbol(s))
end

export  setstartdate!, 
        setenddate!,
        setresolution!,
        setenddate!,
        setcurrentdatetime!,
        getstartdate,
        getenddate,
        getcurrentdatetime,
        adduniverse!,
        setuniverse!,
        getuniverse,
        cantrade,
        setcash!,
        addcash!,
        getposition,    
        getportfolio,
        getportfoliovalue,
        setcancelpolicy!,    
        setcommission!,
        setslippage!,
        setparticipationrate!,
        liquidate,
        placeorder!,
        liquidateportfolio,
        setholdingpct!,
        setholdingvalue!,
        setholdingshares!,
        hedgeportfolio,
        getopenorders,
        cancelallorders,
        updatependingorders!,
        updateaccountforfills!,
        updateaccountforprice!,
        updateprices!,
        updateaccounttracker!,
        calculateperformance,
        createsymbol,
        log!,
        addvariable!,
        checkforparent,
        reset;

end #end of Module





