#type represents a set of statistics calculated from equity and benchmark samples
type PortfolioStats
        
        annualreturn::Float64
        totalreturn::Float64
        annualstandarddeviation::Float64
        annualvariance::Float64
        sharperatio::Float64
        informationratio::Float64
        drawdown::Float64
        
        #alpha::Float64
        #beta:Float64
        #calmarratio:::Float64
        #sortinoratio::Float64
        #trackingerror::Float64
        #treynorratio::Float64
end
