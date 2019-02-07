
#Reset the base function definitions 
#If the user creates a file without initialize or ondata
#It will throw an error
function initialize(state)
	throw(UndefVarError(:initialize))
end

function ondata(data, state)
	throw(UndefVarError(:ondata))
end

function longEntryCondition()
	return nothing
end

function longExitCondition()
	return nothing
end

function shortEntryCondition()
	return nothing
end

function shortExitCondition()
	return nothingr
end
