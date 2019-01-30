# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

#Backtesting module: BackTester

__precompile__(true)
module BackTester

import Base: ==, getindex, setindex!, empty

using Dates

include("./Enums/enums.jl")
include("./DataTypes/Split.jl")
include("./Security/Security.jl")
include("./Security/Adjustment.jl")
include("./Execution/Order.jl")
include("./Execution/OrderFill.jl")
include("./Algorithm/Universe.jl")
include("./Execution/Trade.jl")
include("./Account/Position.jl")
include("./Account/DollarPosition.jl")
include("./Account/Portfolio.jl")
include("./Account/DollarPortfolio.jl")
include("./Account/Account.jl")
include("./Execution/Commission.jl")
include("./Execution/Slippage.jl")
include("./Execution/Blotter.jl")
include("./Execution/Tracker.jl")
include("./Execution/TradeBook.jl")
include("./Execution/Margin.jl")
include("./Execution/Brokerage.jl")
include("./Performance/TradeStats.jl")
include("./Performance/Performance.jl")
include("./Performance/RollingPerformance.jl")
include("./Performance/Statistics.jl")
include("./Algorithm/TradingEnvironment.jl")
include("./Algorithm/AlgorithmState.jl")
include("./Algorithm/Algorithm.jl")

#export Universe, Security, SecuritySymbol,
#       Commission, Slippage, Order, TradeBar


export Security, SecuritySymbol, Adjustment,
       Commission, Slippage, Order, TradeBar,
       Performance, Portfolio, DollarPortfolio, Account, AlgorithmState

export Resolution, CancelPolicy, SecurityType,
         CommissionModel, SlippageModel,
         InvestmentPlan, Rebalance

for s in instances(Resolution)
    @eval export $(Symbol(s))
end

for s in instances(CancelPolicy)
    @eval export $(Symbol(s))
end

for s in instances(SecurityType)
    @eval export $(Symbol(s))
end

for s in instances(CommissionModel)
    @eval export $(Symbol(s))
end

for s in instances(SlippageModel)
    @eval export $(Symbol(s))
end

for s in instances(InvestmentPlan)
    @eval export $(Symbol(s))
end

for s in instances(Rebalance)
    @eval export $(Symbol(s))
end

export  setstartdate!,
        setenddate!,
        setresolution!,
        setenddate!,
        setcurrentdate!,
        setbenchmark!,
        getbenchmark,
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
        setexecutionpolicy!,
        liquidate,
        placeorder!,
        liquidateportfolio,
        setholdingpct!,
        setholdingvalue!,
        setholdingshares!,
        hedgeportfolio,
        getopenorders,
        cancelallorders!,
        updatependingorders!,
        updatependingorders_splits!,
        getlatesttradebar,
        updateaccount_fills!,
        updateaccount_price!,
        updateaccount_splits_dividends!,
        updateprices!,
        updateadjustments!,
        updateaccounttracker!,
        updatedatastores!,
        updatependingorders_price!,
        calculateperformance,
        outputperformance,
        createsymbol,
        log!,
        addvariable!,
        checkforparent,
        reset;

end #end of Module
