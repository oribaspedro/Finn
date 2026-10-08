import 'portfolio_data.dart';

/// Criptomoeda do usuário (valores em reais).
class CryptoHolding {
  final String symbol;
  final String name;
  final double quantity;
  final double avgPrice; // preço médio pago por unidade
  final double currentPrice;
  final double volatilityFactor;
  final double bias;

  const CryptoHolding({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    this.volatilityFactor = 1,
    this.bias = 0,
  });

  double get value => quantity * currentPrice;
  double get invested => quantity * avgPrice;
  double get totalReturn => value - invested;
  double get totalReturnPct => invested == 0 ? 0 : totalReturn / invested * 100;
}

const List<CryptoHolding> cryptoHoldings = [
  CryptoHolding(symbol: 'BTC', name: 'Bitcoin', quantity: 0.0420, avgPrice: 298000, currentPrice: 352400, volatilityFactor: 1.6, bias: 0.9),
  CryptoHolding(symbol: 'ETH', name: 'Ethereum', quantity: 0.85, avgPrice: 14200, currentPrice: 13150, volatilityFactor: 1.9, bias: -0.5),
  CryptoHolding(symbol: 'SOL', name: 'Solana', quantity: 11.5, avgPrice: 720, currentPrice: 905, volatilityFactor: 2.4, bias: 0.8),
  CryptoHolding(symbol: 'XRP', name: 'XRP', quantity: 640, avgPrice: 11.8, currentPrice: 13.4, volatilityFactor: 2.0, bias: 0.4),
  CryptoHolding(symbol: 'ADA', name: 'Cardano', quantity: 1800, avgPrice: 4.35, currentPrice: 3.62, volatilityFactor: 2.2, bias: -0.9),
  CryptoHolding(symbol: 'DOGE', name: 'Dogecoin', quantity: 3500, avgPrice: 0.82, currentPrice: 1.04, volatilityFactor: 2.8, bias: 0.2),
];

final Map<String, List<double>> _cryptoPriceCache = {};
final Map<PortfolioPeriod, List<double>> _cryptoPortfolioCache = {};

List<double> cryptoPriceSeries(CryptoHolding c, PortfolioPeriod p) {
  return _cryptoPriceCache.putIfAbsent(
    '${c.symbol}-${p.index}',
    () => syntheticSeries(
      key: c.symbol,
      period: p,
      current: c.currentPrice,
      volatilityFactor: c.volatilityFactor,
      bias: c.bias,
    ),
  );
}

List<double> cryptoPortfolioSeries(PortfolioPeriod p) {
  return _cryptoPortfolioCache.putIfAbsent(p, () {
    return List<double>.generate(p.points, (i) {
      var sum = 0.0;
      for (final c in cryptoHoldings) {
        sum += c.quantity * cryptoPriceSeries(c, p)[i];
      }
      return sum;
    });
  });
}

Perf cryptoHoldingPerf(CryptoHolding c, PortfolioPeriod p) {
  final s = cryptoPriceSeries(c, p);
  return Perf(c.quantity * s.first, c.quantity * s.last);
}

double get cryptoValue => cryptoHoldings.fold<double>(0, (s, c) => s + c.value);
double get cryptoInvested => cryptoHoldings.fold<double>(0, (s, c) => s + c.invested);
