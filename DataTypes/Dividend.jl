

function ApplyDividend(portfolio::Portfolio, dividend::Dividend)
    security = GetSecurity(dividend.symbol)



end

"""
public void ApplyDividend(Dividend dividend)
        {
            var security = Securities[dividend.Symbol];

            // only apply dividends when we're in raw mode or split adjusted mode
            var mode = security.SubscriptionDataConfig.DataNormalizationMode;
            if (mode == DataNormalizationMode.Raw || mode == DataNormalizationMode.SplitAdjusted)
            {
                // longs get benefits, shorts get clubbed on dividends
                var total = security.Holdings.Quantity*dividend.Distribution;

                // assuming USD, we still need to add Currency to the security object
                _baseCurrencyCash.AddAmount(total);
            }
        }
