using Raftaar
# Sample Strategy to create 100 share position in all stocks in the universe
# Every strategy requires two manadatory functions
# 1. initialize(): Function to initialize the initial settings and 
#    user defined parameters
# 2. ondata(): Function to define strategy logic 

# Intialize the strategy with various settings and/or parameters
function initialize(state)
    # Set intiial cash
    setcash(1000000.0)
    # Set Cancel policy to GTC (good till canceled)
    setcancelpolicy(CancelPolicy(GTC))
    # Set universe (mandatory before placing any orders)
    setuniverse(["CNX_BANK"])
end

# Define strategy logic here
# This function is called EVERY DAY
# However, the rebalance frequency can be 
function ondata(data, state)
    # Get Universe
    universe = getuniverse()
    # Set the holding in all stock in universe to 100 shares
    for stock in universe
        # Function is called every Day/Week/Month based on rebalance frequency
        setholdingshares(stock, 100)
    end
    # Track the portfolio value
    track("portfoliovalue", state.account.netvalue)
    # User Logger to output information to console
    Logger.info("Portofolio value = $(state.account.netvalue)")
end
        
        