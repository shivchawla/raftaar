using YRead
using Mongo

client = MongoClient()
YRead.configure(client)
YRead.configure(priority=2)

#YRead._history(YRead.securitycollection(), YRead.datacollection(), [56502],"Close",:Day, 500, DateTime("2012-01-01"),"EQ","NSE", "IN")
#YRead.getadjustmens([818],DateTime("2010-01-01"), DateTime("2012-01-01"))
YRead.history([818], "Close",:Day, DateTime("2010-01-01"), DateTime("2012-01-01"))
