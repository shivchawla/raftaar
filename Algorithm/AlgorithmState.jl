type AlgorithmState
    account::Account
    performance::Performance
    params::Dict{String, Any}
end

AlgorithmState() = AlgorithmState(Account(), Performance(), Dict{String,Any}())

AlgorithmState(data::Dict{String, Any}) = AlgorithmState(haskey(data, "account") ? Account(data["account"]) : Account(),
                                                  haskey(data, "performance") ? Performance(data["performance"]) : Performance(),
                                                  haskey(data, "params") ? Dict(data["params"]) : Dict())

getindex(algorithmstate::AlgorithmState, key::String) = get(algorithmstate.params, key, "")
setindex!(algorithmstate::AlgorithmState, value::Any, key::String) = setindex!(algorithmstate.params, value, key)

function serialize(as::AlgorithmState)
  return Dict{String, Any}("account"     => serialize(as.account),
                            #"portfolio"   => serialize(as.portfolio),
                            "performance" => serialize(as.performance),
                            "params"      => as.params)
end

==(as1::AlgorithmState, as2::AlgorithmState) = as1.account == as2.account &&
                                                #as1.portfolio == as2.portfolio &&
                                                as1.performance == as2.performance &&
                                                as1.params == as2.params
