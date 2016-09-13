
include("HistoryImpl.jl")

#add functions to read from database
#add functions to read from quandl json format 


#=function historyz(security::ASCIIString, startdate, enddate, 
				  resolution::Resolution=Resolution(Daily), field::FieldType=FieldType(4))
	historyfromquandl(security, startdate, enddate, resolution, field)
end

function historyz(securities::Array{ASCIIString}, startDate, endDate, 
			      resolution::Resolution=Resolution(Daily), field::FieldType=FieldType(4))
	historyfromquandl(securities, startdate, enddate, resolution, field)
end
=#

function history(security::ASCIIString, period::Int64, resolution::Resolution = Resolution(Daily), field::FieldType = FieldType(Close))
	historyfromquandl(security, period, resolution, field)
end

function history(securities::Array{ASCIIString}, period::Int64, 
				 resolution::Resolution=Resolution(Daily), field::FieldType = FieldType(Close))
	historyfromquandl(securities, period, resolution, field)
end




#end

