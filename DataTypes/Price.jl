
@enum Resolution Tick Second Minute Hour Daily
    
#=@enum BarType  OneMinute = 1 TwoMinute = 2 FiveMinute = 5 TenMinutee  = 10 OneHour = 60 Day = 1440

@enum TickType Trade = 1 Quote = 2
=#
@enum FieldType Open  High  Low  Close  Last  Volume 

#Enums must be defined in one line...Seems weird but thats how it is
#The way to access enum is EnumName(EnumValue). For ex: FieldType(Close)