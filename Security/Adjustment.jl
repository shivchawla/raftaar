type Adjustment
    close::Float64
    adjustmenttype::String
    adjustmentfactor::Float64
end

Adjustment() = Adjustment(0.0, "", 0.0)

Adjustment(data::Dict{String, Any}) = Adjustment(data["close"], data["adjustmenttype"], data["adjustmentfactor"])

function serialize(adj::Adjustment)
  return Dict{String, Any}("close"              => adj.close,
                            "adjustmenttype"    => adj.adjustmenttype,
                            "adjustmentfactor"  => adj.adjustmentfactor)
end

==(adj1::Adjustment, adj2::Adjustment) = adj1.close == adj2.close &&
                                          adj1.adjustmenttype == adj2.adjustmenttype &&
                                          adj1.adjustmentfactor == adj2.adjustmentfactor
