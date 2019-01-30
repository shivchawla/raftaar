# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


@enum DayOfWeek Monday Tuesday Wednesday Thursday Friday Saturday Sunday 

@enum MarketState PreMarket Market PostMarket Closed

mutable struct MarketHourSegment
	starttime::DateTime
	endtime::DateTime
	#marketstate::MarketState
end

mutable struct LocalMarketHours
	haspremarket::Bool
	haspostmarket::Bool
	isopenallday::Bool
	isclosedallday::Bool
	dayofweek::DayOfWeek
	hoursegments::Array{MarketHourSegment}
end

mutable struct SecurityExchangeHours
    openhoursbyday::Dict{DayOfWeek, MarketHours}
end

mutable struct SecurityExchange
  id::String
  name::String	
  #localfrontier::DateTime
  #hours::SecurityExchangeHours  
end


