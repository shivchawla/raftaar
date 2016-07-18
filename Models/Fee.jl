
@enum FeeType
  PerTrade = 1
  PerShare = 2

type FeeModel
  feetype::FeeType
  feevalue::Float64
  function FeeModel(feetype::FeeType, feevalue::Float64)
    new(feetype, feevalue)
end

Fees() = Fees(FeeType.PerTrade, 1.0)

function getorderfee(order::Order, feemodel::FeeModel)
  if FeeModel.feetype == FeeType.PerShare
    return abs(order.quantity) * fee.feevalue
  if FeeModel.feetype == FeeType.PerTrade
    return fee.feevalue
end

function setfeemodel(feetype::FeeType, feevalue::Float64)
  Fee(feemodel, feevalue)
end
