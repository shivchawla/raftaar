using API
using Raftaar
using YRead
using Mongo

client = MongoClient()

YRead.configure(client)


setcancelpolicy(CancelPolicy(EOD))
setcancelpolicy("GTC")


setcommission(Commission(CommissionModel(PerTrade), 0.5))
setcommission(Commission(CommissionModel(PerShare), 0.5))
setcommission(("PerShare", 0.6))
setcommission(("PerTrade", 10.0))


setslippage(Slippage(SlippageModel(Fixed), 30))
setslippage(Slippage(SlippageModel(Variable), 0.5))
