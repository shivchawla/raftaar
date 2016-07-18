typealias Universe @compat Dict{SecuritySymbol, Security}


function addSecurity(security::Security, universe::Universe)
	universe[security.symbol] = security
	return
end

function getsecurity(symbol::SecuritySymbol, universe::Universe)
	get!(universe, symbol, default)
end

function removesecurity(symbol::SecuritySymbol, universe::Universe)
	delete(universe, symbol)
end

function removesecurity(security::Security, universe::Universe)
	delete(universe, security.symbol)
end

function contains(security::Security, universe)
	haskey(universe, security.symbol)
end 

function contains(symbol::SecuritySymbol, universe)
	haskey(universe, symbol)
end 