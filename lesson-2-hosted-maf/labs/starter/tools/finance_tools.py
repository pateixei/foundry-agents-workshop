"""
Lab 2 - Task 1: Implement Custom Financial Tools

Complete the TODO functions below. Each function should:
- Accept typed parameters with Annotated descriptions
- Return a formatted string with financial data
- Include error handling for invalid inputs

For the workshop, simulate data (in production, call real APIs).
"""

from typing import Annotated
from random import uniform, choice


def get_stock_quote(
    ticker: Annotated[str, "Stock ticker code, e.g., PETR4, VALE3, AAPL"],
) -> str:
    """Returns the current stock price for a ticker."""
    # TODO: Implement stock price lookup
    # 1. Define a dictionary of known tickers with simulated prices
    # 2. Normalize the ticker (uppercase, strip whitespace)
    # 3. Look up the ticker in the dictionary
    # 4. Return formatted string with: ticker, name, price, currency, change %
    # 5. Return error message for unknown tickers
    pass


def get_exchange_rate(
    pair: Annotated[str, "Currency pair, e.g., USD/BRL, EUR/BRL, GBP/BRL"],
) -> str:
    """Returns the current exchange rate for a currency pair."""
    # TODO: Implement exchange rate lookup
    # 1. Define known currency pairs with simulated rates
    # 2. Normalize the pair (uppercase, strip, no spaces)
    # 3. Return formatted string with: pair, rate, change %
    # 4. Return error message for unknown pairs
    pass


def get_market_summary(
    market: Annotated[str, "Market: brasil, eua, europa or global"],
) -> str:
    """Returns a summary of the selected financial market."""
    # TODO: Implement market summary
    # 1. Normalize market name (lowercase, strip)
    # 2. Return different summaries for: brasil, eua, europa, global
    # 3. Include: main index, change %, key rate, sentiment
    # 4. Return error for unknown markets
    pass
