# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

function initialize(state)

	setuniverse(["TCS", "INFY"]) 
	setcancelpolicy("EOD")
	setcash(100000.0)
	setbenchmark("TCS")
end

function longEntryCondition()
	return (SMA(horizon=10) > SMA(horizon=50)) #& (SMA(horizon=20) > SMA(horizon=100))
end

function longExitCondition()
	return (SMA(horizon=10) < SMA(horizon=50)) #| (SMA(horizon=20) < SMA(horizon=100))
end

shortEntryCondition() = nothing
shortExitCondition() = nothing

function ondata(data, state)
	track("Net Value", state.account.netvalue)
end
