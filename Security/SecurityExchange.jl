# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.


@enum DayOfWeek Monday Tuesday Wednesday Thursday Friday Saturday Sunday 

@enum MarketState PreMarket Market PostMarket Closed

type MarketHourSegment
	starttime::DateTime
	endtime::DateTime
	#marketstate::MarketState
end

type LocalMarketHours
	haspremarket::Bool
	haspostmarket::Bool
	isopenallday::Bool
	isclosedallday::Bool
	dayofweek::DayOfWeek
	hoursegments::Array{MarketHourSegment}
end

type SecurityExchangeHours
    openhoursbyday::Dict{DayOfWeek, MarketHours}
end

type SecurityExchange
  id::String
  name::String	
  #localfrontier::DateTime
  #hours::SecurityExchangeHours  
end


