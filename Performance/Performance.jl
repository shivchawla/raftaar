
include("PortfolioStats.jl")
include("TradeStats.jl")
include("../DataTypes/Trade.jl")

type Performance
	portfoliostats::PortfolioStats
	tradestats::TradeStats
	trades::Vector{Trade}
end	

