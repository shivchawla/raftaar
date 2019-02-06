
#Reset the base function definitions 
#If the user creates a file without initialize or ondata
#It will throw an error
function initialize(state)
	throw(UndefVarError(:initialize))
end

function ondata(data, state)
	throw(UndefVarError(:ondata))
end

function longEntryCondition(state)
	return nothing
end

function longExitCondition(state)
	return nothing
end

function shortEntryCondition(state)
	return nothing
end

function shortExitCondition(state)
	return nothing
end
