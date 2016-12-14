type AlgorithmState
    account::Account
    portfolio::Portfolio
    performance::Performance
    params::Dict{String, Any}
end

AlgorithmState() = AlgorithmState(Account(), Portfolio(), Performance(), Dict{String,Any}())

getindex(algorithmstate::AlgorithmState, key::String) = get(algorithmstate.params, key)
setindex!(algorithmstate::AlgorithmState, value::Any, key::String) = setindex!(algorithmstate.params, value, key)
