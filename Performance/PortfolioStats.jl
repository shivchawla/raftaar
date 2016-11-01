# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

"""
Set of statistics calculated from 
equity and benchmark samples
"""
type PortfolioStats
        
        annualreturn::Vector{Float64}
        totalreturn::Vector{Float64}
        annualstandarddeviation::Vector{Float64}
        annualvariance::Vector{Float64}
        sharperatio::Vector{Float64}
        informationratio::Vector{Float64}
        drawdown::Vector{Float64}
        maxdrawdown::Vector{Float64}

        #alpha::Float64
        #beta:Float64
        #calmarratio:::Float64
        #sortinoratio::Float64
        #trackingerror::Float64
        #treynorratio::Float64
end

"""
Empty Constructor
"""
PortfolioStats() = PortfolioStats(Vector{Float64}(), Vector{Float64}(), Vector{Float64}(), Vector{Float64}(),
                                Vector{Float64}(), Vector{Float64}(), Vector{Float64}(), Vector{Float64}())

