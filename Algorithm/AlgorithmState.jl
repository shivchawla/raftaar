type AlgorithmState
    account::Account
    portfolio::Portfolio
    performance::Performance
    params::Dict{String, Any}
end

AlgorithmState() = AlgorithmState(Account(), Portfolio(), Performance(), Dict{String,Any}())

AlgorithmState(data::BSONObject) = AlgorithmState(Account(data["account"]),
                                                  Portfolio(data["portfolio"]),
                                                  Performance(data["performance"]),
                                                  Dict(data["params"]))

getindex(algorithmstate::AlgorithmState, key::String) = get(algorithmstate.params, key, "")
setindex!(algorithmstate::AlgorithmState, value::Any, key::String) = setindex!(algorithmstate.params, value, key)

function serialize(as::AlgorithmState)
  return Dict{String, Any}("account"     => serialize(as.account),
                            "portfolio"   => serialize(as.portfolio),
                            "performance" => serialize(as.performance),
                            "params"      => as.params)
end
