# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

__precompile__()
module Raftaar

import Base: ==, getindex, setindex!
include("API.jl")

export Algorithm, Universe, Security, SecuritySymbol,
       Commission, Slippage, Order, TradeBar

export Resolution, CancelPolicy, SecurityType, MessageType

for s in instances(Resolution)
    @eval export $(symbol(s))
end

for s in instances(CancelPolicy)
    @eval export $(symbol(s))
end

for s in instances(SecurityType)
    @eval export $(symbol(s))
end

for s in instances(MessageType)
    @eval export $(symbol(s))
end


#=export  setstartdate!, 
        setenddate!,
        setresolution!,
        setenddate!,
        setcurrentdatetime!,
        getstartdate,
        getenddate,
        getcurrentdatetime,
        adduniverse1!,
        adduniverse2!,
        adduniverse3!,
        adduniverse4!,
        setuniverse1!,
        setuniverse2!,
        setuniverse3!,
        setuniverse4!,
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
        addvariable!;=#

#const algorithm = Algorithm()
export  setresolution,
        setstartdate,
        setenddate,
        setcurrentdatetime,
        getstartdate,
        getenddate,
        getcurrentdatetime,
        adduniverse,
        setuniverse,
        getuniverse,
        cantrade,
        setcash,
        addcash,
        getposition,
        getportfolio,
        getportfoliovalue,
        setcancelpolicy,
        setcommission,
        setslippage,
        setparticipationrate,
        liquidate,
        placeorder,
        setholdingpct,
        setholdingvalue,
        setholdingshares,
        hedgeportfolio,
        getopenorders,
        cancelallorders,
        _updatependingorders,
        _updateaccountforprice,
        _updateprices,
        _updateaccounttracker,
        _calculateperformance,
        logg,
        track,
        createsymbol,
        getalgorithm,
        _initialize;


end #end of Module





