
#Reset the base function definitions 
#If the user creates a file without initialize or ondata
#It will throw an error
function initialize(state)
	throw(UndefVarError(:initialize))
end

function ondata(data, state)
	throw(UndefVarError(:ondata))
end

function buycondition(state)
	return nothing
end

function sellcondition(state)
	return nothing
end
