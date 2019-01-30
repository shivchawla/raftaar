
# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.
using Raftaar
function initialize(state)	
	setcash(1000000.0)
	setresolution("Day")
	setcancelpolicy(CancelPolicy(EOD))
	setrebalance("Monthly")
	setuniverse([82773, 
67498,
 23423,
 95160,
 77902,
 51025,
 14789,
 45712,
 46015,
 94893,
 75794,
 56145,
 72889,
 86176,
 27959,
 38180,
 80363,
 64570,
 75579,
 55002,
 49896,
  3414,
 86105,
 21901,
  6881,
 58260,
 34567,
 25518,
 81061,
 49672,
 21357,
 52644,
 60412,
  5975,
 15857,
 52986,
 37815,
 85804,
 22097,
 22492,
 69096,
 73077,
  9297,
 19194,
 71677,
 28764,
 68167,
 52590,
 24609])
end

function ondata(data, state)

	universe = getuniverse()
	numsecurities = length(universe)
	
	for security in universe
		setholdingpct(security, 1.0/numsecurities)
	end	
	
	track("Net Value", state.account.netvalue)

end
        