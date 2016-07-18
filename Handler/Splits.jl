"A lot of things are taken from quant connect"
"Make sure we need it and define al relevant functions"
function handlesplit!(split::Split, universe::Universe, portfolio::Portfolio)
    
    "we need to modify our holdings in lght of the split factor"
    position = getposition(split.symbol, portfolio) 

    if !isempty(position)

        quantity = position.quantity/split.splitFactor
        avgprice = position.averagePrice*split.splitFactor

        "we'll model this as a cash adjustment"
        leftOver = quantity - (int) quantity
        extraCash = leftOver*split.ReferencePrice
        addcash(portfolio, extraCash);
        setposition(security, avgprice, (int)quantity)
    end        
        
    "build a 'next' value to update the market prices in light of the split factor"
    nextPrice = GetLastPrice(security)
    if isempty(next)
        return
    end    
        
    nextprice *= split.splitfactor
    nexttradebar = getlasttradebar(security)
    if(!isempty(nextTradeBar))
    nexttradebar.open *= split.splitFactor
    nexttradebar.high *= split.splitFactor
    nexttradebar.low *= split.splitFactor
         
    nextTick = getlasttick(security)
    if isempty(nextTick)
        nexttick.ask *= split.splitfactor
        nexttick.bid *= split.splitfactor

        
    setmarketprice(security, nextprice)
end