#type represents a set of statistics calculated from equity and benchmark samples
type PortfolioStats
        #The average rate of return for winning trades
        averagewinrate::Float64
        #The average rate of return for losing trades
        averagelossrate::Float64
        #The ratio of the average win rate to the average loss rate
        #<remarks>If the average loss rate is zero, ProfitLossRatio is set to 0</remarks>
        profitlossratio::Float64
        #The ratio of the number of winning trades to the total number of trades
        #<remarks>If the total number of trades is zero, WinRate is set to zero</remarks>
        winRate::Float64
        #The ratio of the number of losing trades to the total number of trades
        #<remarks>If the total number of trades is zero, LossRate is set to zero</remarks>
        lossRate::Float64
        #The expected value of the rate of return
        expectancy::Float64
        #Annual compounded returns statistic based on the final-starting capital and years.
        #<remarks>Also known as Compound Annual Growth Rate (CAGR)</remarks>
        compoundingannualreturn::Float64
        #Drawdown maximum percentage.
        drawdown::Float64
        #The total net profit percentage.
        totalnetprofit::Float64
        #Sharpe ratio with respect to risk free rate: measures excess of return per unit of risk.
        #<remarks>With risk defined as the algorithm's volatility</remarks>
        sharperatio::Float64
        #Algorithm "Alpha" statistic - abnormal returns over the risk free rate and the relationshio (beta) with the benchmark returns.
        alpha::Float64
        #Algorithm "beta" statistic - the covariance between the algorithm and benchmark performance, divided by benchmark's variance
        beta::Float64
        #Annualized standard deviation
        annualstandarddeviation::Float64
        #Annualized variance statistic calculation using the daily performance variance and trading days per year.
        annualvariance::Float64 
        #Information ratio - risk adjusted return
        #<remarks>(risk = tracking error volatility, a volatility measures that considers the volatility of both algo and benchmark)</remarks>
        informationratio::Float64
        #Tracking error volatility (TEV) statistic - a measure of how closely a portfolio follows the index to which it is benchmarked
        #<remarks>If algo = benchmark, TEV = 0</remarks>
        trackingerror::Float64
        #Treynor ratio statistic is a measurement of the returns earned in excess of that which could have been earned on an investment that has no diversifiable risk
        treynorratio::Float64
end
