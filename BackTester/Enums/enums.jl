"""
Definition of Security Type 
"""
@enum SecurityType Equity Futur Option Commodity Forex Cfd InValid

"""
Definition of CancelPolicy
"""
@enum CancelPolicy EOD GTC 

"""
Definition of ExecutionPolicy
"""
@enum ExecutionPolicy EP_Close EP_Open EP_High EP_Low EP_AverageHighLow EP_AverageAll

"""
OrderType
"""
@enum OrderType Limit StopLimit StopMarket MarketOnOpen MarketOnClose Market
 
"""
OrderStatus
""" 
@enum OrderStatus New Submitted PartiallyFilled Filled Canceled Pending None 

"""
TradeStatus
""" 
@enum TradeStatus Trade_Open Trade_Close


"""
Commission Model
"""
@enum CommissionModel PerTrade PerShare PerValue

"""
Slippage Model
"""
@enum SlippageModel Variable Fixed

"""
Resolution
"""
@enum Resolution Resolution_Tick Resolution_Second Resolution_Minute Resolution_Hour Resolution_Day

"""
FieldType
"""
@enum FieldType Open High Low Close Last Volume 


"""
Rebalance Frequency
"""
@enum Rebalance Rebalance_Daily Rebalance_Weekly Rebalance_Monthly Rebalance_Yearly 

"""
Investment Plan Frequency
"""
@enum InvestmentPlan IP_AllIn IP_Weekly IP_Monthly IP_Yearly 

"""
AlgorithmStatus
"""
@enum AlgorithmStatus DeployError InQueue Running Stopped Liquidated Deleted Completed RuntimeError LoggingIn Initializing

