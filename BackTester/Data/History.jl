# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("HistoryImpl.jl")

#add functions to read from database
#add functions to read from quandl json format 


#=function historyz(security::String, startdate, enddate, 
				  resolution::Resolution=Resolution(Daily), field::FieldType=FieldType(4))
	historyfromquandl(security, startdate, enddate, resolution, field)
end

function historyz(securities::Array{String}, startDate, endDate, 
			      resolution::Resolution=Resolution(Daily), field::FieldType=FieldType(4))
	historyfromquandl(securities, startdate, enddate, resolution, field)
end
=#

function history(security::String, period::Int64, resolution::Resolution = Resolution(Daily), field::FieldType = FieldType(Close))
	historyfromquandl(security, period, resolution, field)
end

function history(securities::Array{String}, period::Int64, 
				 resolution::Resolution=Resolution(Daily), field::FieldType = FieldType(Close))
	historyfromquandl(securities, period, resolution, field)
end




#end

