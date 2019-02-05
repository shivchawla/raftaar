# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

function initialize(state)

	setuniverse(["TCS", "INFY"]) 
	setcancelpolicy("EOD")
	setresolution("Minute")
	setcash(100000.0)
	setbenchmark("TCS")
end

function longEntryCondition()
	return (SMA(horizon=100) > SMA(horizon=500)) & (SMA(horizon=200) > SMA(horizon=1000))
end

function longExitCondition()
	return (SMA(horizon=100) < SMA(horizon=500)) | (SMA(horizon=200) < SMA(horizon=1000))
end

shortEntryCondition() = nothing
shortExitCondition() = nothing

function ondata(data, state)
	track("Net Value", state.account.netvalue)
end
