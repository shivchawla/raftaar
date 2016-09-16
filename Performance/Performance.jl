
include("PortfolioStats.jl")
#include("TradeStats.jl")
#include("../DataTypes/Trade.jl")

typealias AccountTracker Dict{DateTime, Account}
typealias CashTracker Dict{DateTime, Float64}
  
type Performance
    portfoliostats::PortfolioStats
    rollingportfoliostats::Dict{ASCIIString, PortfolioStats}
end  

function calculateperformance(accounttracker::AccountTracker, cashtracker::CashTracker)
    
    sortedkeys = sort(collect(keys(accounttracker)))
    returns = Vector{Float64}()

    if !isempty(sortedkeys)
        firstdate = sortedkeys[1]
        startingcaptital = accounttracker[firstdate].cash
        netvalue = startingcaptital

        for date in sortedkeys[2:end]
            oldnetvalue = netvalue

            netvalue = accounttracker[date].netvalue
            newfunds = haskey(cashtracker, date) ? cashtracker[date] : 0.0
            adjustednetvalue = netvalue - newfunds

            rt = oldnetvalue > 0.0 ? (netvalue - newfunds - oldnetvalue)/ oldnetvalue : 0.0

            push!(returns, rt)
            println(netvalue)
        end
    end
end    