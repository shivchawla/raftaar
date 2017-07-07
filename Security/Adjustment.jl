type Adjustment
    close::Float64
    adjustmenttype::String
    adjustmentfactor::Float64
end

Adjustment() = Adjustment(0.0, "", 0.0)

Adjustment(data::BSONObject) = Adjustment(data["close"], data["adjustmenttype"], data["adjustmentfactor"])
