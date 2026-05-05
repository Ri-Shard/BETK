# BETK

Global EV Scanner and Value Betting app built with Flutter, Clean Architecture, and GetX.

## Mathematical Model

The core engine of BETK is designed to identify true market inefficiencies using a highly precise mathematical approach, completely ignoring the traditional "consensus average" which is heavily flawed in the sports betting industry.

### 1. The Benchmark (Source of Truth)
Not all bookmakers are equal. Recreational bookmakers (soft bookies) have high margins and slow reaction times, while professional bookmakers (sharp bookies like Pinnacle or Betfair Exchange) use sophisticated models and market liquidity to offer the most accurate odds.
BETK completely ignores soft bookies for probability calculation. Instead, it isolates the odds from the sharpest bookmaker available for a given event and uses them as the sole "Source of Truth".

### 2. Margin Removal: The Power Method
Bookmakers do not offer fair odds; they include a profit margin (overround). However, this margin is not distributed equally. Due to the "Favorite-Longshot Bias," bookmakers apply a significantly higher margin to the underdog (less likely outcome) than to the favorite.
Using a simple proportional margin removal mathematically overvalues the underdog, leading to false positive "value bets" on highly improbable outcomes.
To solve this, BETK uses the **Power Method**. It runs an iterative bisection algorithm to find an exponent `k` such that the sum of `(1 / odd) ^ (1 / k)` across all outcomes equals exactly 1.0. This mathematical adjustment heavily penalizes the underdog and rewards the favorite, stripping the bookmaker's commission in a way that accurately reflects real-world probabilities.

### 3. Expected Value (EV) & Market Crossing
Once the true, unbiased probabilities are calculated using the Power Method on the sharp bookmaker's odds, BETK sweeps the rest of the market (the soft bookies).
For every odd offered by a soft bookie, it calculates the Expected Value (EV):
`EV = (True Probability * Soft Bookie Odd) - 1`

If a soft bookie is slow to update or misprices an outcome, the EV becomes positive. BETK strictly filters opportunities:
- **Minimum True Probability >= 35%**: To avoid extremely high variance bets (miracles).
- **Maximum Odd <= 3.0**: Enforcing the bot to only suggest highly viable outcomes.
- **EV Bounds (2% to 20%)**: Discarding massive EVs which are usually API glitches or closed markets.

### 4. Bankroll Management: Fractional Kelly Criterion
For every identified value bet, BETK calculates the optimal investment size using the Kelly Criterion:
`f* = (p * b - q) / b`
Where `p` is the true probability, `b` is the decimal odds minus 1, and `q` is the probability of losing.
To minimize ruin risk and handle variance, BETK applies a **Fractional Kelly (50%)**, providing a safe, conservative investment amount (in COP) that mathematically guarantees long-term bankroll growth.
