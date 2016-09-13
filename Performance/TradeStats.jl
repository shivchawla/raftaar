type TradeStats
    startdatetime::DateTime
    enddatetime::DateTime
    totalnumberoftrades::Int64
    numberwinningtrades::Int64  
    numberlosingtrades::Int64    
    totalproftloss::Float64
    totalprofit::Float64
    totalloss::Float64
    largestprofit::Float64
    largestloss::Float64
    averageprofitloss::Float64   
    averageprofit::Float64
    averageloss::Float64    
    averagetradeduration::TimeSpan
    averagewinningtradeduration::TimeSpan
    maxconsecutivewinningtrades::Int64
    maxconsecutivelosingtrades::Int64
    profitlossratio::Float64
    winlossratio::Float64
    winrate::Float64
    lossrate::Float64    
    averagemae::Float64 #The average Maximum Adverse Excursion for all trades
    averagemfe::Float64 #The average Maximum Favorable Excursion for all trades  
    largestmae::Float64 #The largest Maximum Adverse Excursion in a single trade (as symbol currency)
    largestmfe::Float64 #The largest Maximum Favorable Excursion in a single trade (as symbol currency)
    maximumclosedtradeduration::Float64 #The maximum closed-trade drawdown for all trades (as symbol currency) 
    maximumintratradedrawown::Float64 #he maximum intra-trade drawdown for all trades (as symbol currency)   
    profitlossstandardeviation::Float64 #The standard deviation of the profits/losses for all trades (as symbol currency)
    profitlossdownsidedeviation::Float64 #The downside deviation of the profits/losses for all trades (as symbol currency)
    profitfactor::Float64 #The ratio of the total profit to the total loss
    sharperatio::Float64 #The ratio of the average profit/loss to the standard deviation
    sortinoratio::Float64 #The ratio of the average profit/loss to the downside deviation
    profittomaxdrawdownratio::Float64 #The ratio of the total profit/loss to the maximum closed trade drawdown
    maximumendtradedrawdown::Float64 #The maximum amount of profit given back by a single trade before exit (as symbol currency)
    averageendtradedrawdown::Float64 #The average amount of profit given back by all trades before exit (as symbol currency)
    maximumdrawdownduration::TimeSpan #The maximum amount of time to recover from a drawdown (longest time between new equity highs or peaks)
    totalfees::Float64 #The sum of fees for all trades  
end