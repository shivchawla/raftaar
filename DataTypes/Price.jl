
@enum BarType
	OneMinute = 1
	TwoMinute = 2
	FiveMinute = 5
	TenMinutee  = 10
	OneHour = 60
	Day = 1440


@enum TickType
	Trade = 1
	Quote = 2


type TradeBar
	symbol::SecuritySymbol
	open::Float64
	high::Float64
	low::Float64
	close::Float64
	volume::Int32
	time::DateTime
	bartype::BarType
	isfillforward::Bool
end


type Tick
	time::DateTime
	symbol::SecuritySymbol
	ticktype::TickType
	quantity::Int32
	exchange::Exchange
	bidsize::Int32
	asksize::Int32
	bidprice::Float64
	askprice::Float64
	tradeprice::Float64
end

