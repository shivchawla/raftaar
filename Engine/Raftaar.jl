
__precompile__()
module Raftaar

import Base: ==, getindex, setindex!
include("../Algorithm/Algorithm.jl")
include("../Data/History.jl")
include("../Execution/Commission.jl")
include("../Execution/Slippage.jl")

#using Base.Cartesian, Compat, Reexport

export Algorithm, Universe, Security, SecuritySymbol,
       Commission, Slippage, Order, TradeBar

export Resolution, CancelPolicy, SecurityType

for s in instances(Resolution)
    @eval export $(symbol(s))
end

for s in instances(CancelPolicy)
    @eval export $(symbol(s))
end

for s in instances(SecurityType)
    @eval export $(symbol(s))
end


export  setstartdate!, 
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
        createsymbol;

end #end of Module





