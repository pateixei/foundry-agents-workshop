"""
Funcoes-ferramenta de mercado financeiro para o agente.
Estas funcoes sao expostas como tools do Microsoft Agent Framework.
Em producao, conectariam a APIs reais (ex.: B3, Yahoo Finance).
"""

from typing import Annotated
from random import uniform, choice


def get_stock_quote(
    ticker: Annotated[str, "Codigo da acao, ex: PETR4, VALE3, ITUB4, AAPL, MSFT"],
) -> str:
    """Retorna a cotacao atual de uma acao da B3 ou mercado internacional."""
    # Simulacao - em producao, conectar a uma API real
    prices = {
        "PETR4": ("Petrobras PN", uniform(28.0, 42.0), "BRL"),
        "VALE3": ("Vale ON", uniform(55.0, 80.0), "BRL"),
        "ITUB4": ("Itau Unibanco PN", uniform(25.0, 38.0), "BRL"),
        "BBDC4": ("Bradesco PN", uniform(12.0, 18.0), "BRL"),
        "WEGE3": ("WEG ON", uniform(35.0, 55.0), "BRL"),
        "AAPL": ("Apple Inc", uniform(150.0, 220.0), "USD"),
        "MSFT": ("Microsoft Corp", uniform(350.0, 450.0), "USD"),
        "GOOGL": ("Alphabet Inc", uniform(130.0, 180.0), "USD"),
    }

    ticker_upper = ticker.upper().strip()
    if ticker_upper in prices:
        name, price, currency = prices[ticker_upper]
        change = uniform(-3.0, 3.0)
        symbol = "R$" if currency == "BRL" else "$"
        direction = "alta" if change > 0 else "queda"
        return (
            f"{ticker_upper} ({name}): {symbol} {price:.2f} | "
            f"Variacao: {change:+.2f}% ({direction})"
        )

    return f"Ticker '{ticker_upper}' nao encontrado. Tente PETR4, VALE3, ITUB4, AAPL, MSFT, etc."


def get_exchange_rate(
    pair: Annotated[str, "Par de moedas, ex: USD/BRL, EUR/BRL, GBP/BRL"],
) -> str:
    """Retorna a taxa de cambio atual para um par de moedas."""
    rates = {
        "USD/BRL": uniform(4.80, 5.50),
        "EUR/BRL": uniform(5.20, 6.10),
        "GBP/BRL": uniform(6.00, 7.00),
        "USD/EUR": uniform(0.85, 0.95),
        "BTC/USD": uniform(40000.0, 70000.0),
    }

    pair_upper = pair.upper().strip().replace(" ", "")
    if pair_upper in rates:
        rate = rates[pair_upper]
        change = uniform(-1.5, 1.5)
        direction = "valorizacao" if change > 0 else "desvalorizacao"
        return (
            f"{pair_upper}: {rate:.4f} | "
            f"Variacao: {change:+.2f}% ({direction})"
        )

    return f"Par '{pair_upper}' nao encontrado. Pares disponiveis: USD/BRL, EUR/BRL, GBP/BRL, USD/EUR, BTC/USD."


def get_market_summary(
    market: Annotated[str, "Mercado: brasil, eua, europa ou global"],
) -> str:
    """Retorna um resumo do mercado financeiro selecionado."""
    market_lower = market.lower().strip()

    if market_lower in ("brasil", "br", "b3"):
        ibov = uniform(115000, 135000)
        ibov_change = uniform(-2.0, 2.0)
        selic = 13.75
        sentiment = choice(["otimista", "cauteloso", "neutro"])
        return (
            f"Mercado Brasileiro:\n"
            f"  Ibovespa: {ibov:,.0f} pts ({ibov_change:+.2f}%)\n"
            f"  Taxa Selic: {selic}% a.a.\n"
            f"  Sentimento: {sentiment}\n"
            f"  Destaques: Commodities e bancos lideram o pregao."
        )

    if market_lower in ("eua", "us", "usa", "estados unidos"):
        sp500 = uniform(4800, 5500)
        sp_change = uniform(-1.5, 1.5)
        nasdaq = uniform(15000, 18000)
        nas_change = uniform(-2.0, 2.0)
        return (
            f"Mercado Norte-Americano:\n"
            f"  S&P 500: {sp500:,.0f} pts ({sp_change:+.2f}%)\n"
            f"  NASDAQ: {nasdaq:,.0f} pts ({nas_change:+.2f}%)\n"
            f"  Destaques: Big techs e AI lideram as movimentacoes."
        )

    if market_lower in ("europa", "eu", "european"):
        stoxx = uniform(4200, 4800)
        stoxx_change = uniform(-1.0, 1.0)
        return (
            f"Mercado Europeu:\n"
            f"  Euro Stoxx 50: {stoxx:,.0f} pts ({stoxx_change:+.2f}%)\n"
            f"  Destaques: Setor bancario e energia em foco."
        )

    if market_lower == "global":
        sentiment = choice(["risk-on", "risk-off", "neutro"])
        return (
            f"Resumo Global:\n"
            f"  Sentimento: {sentiment}\n"
            f"  Destaque: Decisoes de bancos centrais impactam mercados globalmente."
        )

    return f"Mercado '{market}' nao reconhecido. Use: brasil, eua, europa ou global."
