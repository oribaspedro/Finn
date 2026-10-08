import 'dart:math' as math;

enum PortfolioPeriod { day, week, month, year }

extension PortfolioPeriodX on PortfolioPeriod {
  String get label => switch (this) {
        PortfolioPeriod.day => 'Último dia',
        PortfolioPeriod.week => 'Última semana',
        PortfolioPeriod.month => 'Último mês',
        PortfolioPeriod.year => 'Último ano',
      };

  /// Quantidade de pontos do gráfico.
  int get points => switch (this) {
        PortfolioPeriod.day => 48,
        PortfolioPeriod.week => 35,
        PortfolioPeriod.month => 30,
        PortfolioPeriod.year => 52,
      };

  /// Oscilação típica entre um ponto e outro.
  double get volatility => switch (this) {
        PortfolioPeriod.day => 0.004,
        PortfolioPeriod.week => 0.006,
        PortfolioPeriod.month => 0.012,
        PortfolioPeriod.year => 0.03,
      };
}

class Holding {
  final String ticker;
  final String name;
  final String sector;
  final int quantity;
  final double avgPrice; // preço médio pago
  final double currentPrice;
  final double volatilityFactor;
  final double bias; // tendência (-1..1) usada para gerar o histórico fictício

  const Holding({
    required this.ticker,
    required this.name,
    required this.sector,
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

/// Início e fim de um valor em um período.
class Perf {
  final double start;
  final double end;
  const Perf(this.start, this.end);

  double get change => end - start;
  double get pct => start == 0 ? 0 : (end / start - 1) * 100;
  bool get isUp => change >= 0;
}

const List<Holding> holdings = [
  Holding(ticker: 'PETR4', name: 'Petrobras', sector: 'Energia', quantity: 120, avgPrice: 31.10, currentPrice: 38.42, volatilityFactor: 1.2, bias: 0.8),
  Holding(ticker: 'VALE3', name: 'Vale', sector: 'Mineração', quantity: 80, avgPrice: 66.40, currentPrice: 61.15, volatilityFactor: 1.1, bias: -0.7),
  Holding(ticker: 'ITUB4', name: 'Itaú Unibanco', sector: 'Financeiro', quantity: 150, avgPrice: 28.90, currentPrice: 33.80, bias: 0.5),
  Holding(ticker: 'BBAS3', name: 'Banco do Brasil', sector: 'Financeiro', quantity: 90, avgPrice: 25.10, currentPrice: 27.40, bias: 0.3),
  Holding(ticker: 'WEGE3', name: 'WEG', sector: 'Industrial', quantity: 100, avgPrice: 39.50, currentPrice: 46.20, volatilityFactor: 0.9, bias: 1.0),
  Holding(ticker: 'MGLU3', name: 'Magazine Luiza', sector: 'Varejo', quantity: 300, avgPrice: 12.30, currentPrice: 9.85, volatilityFactor: 1.8, bias: -1.0),
  Holding(ticker: 'ABEV3', name: 'Ambev', sector: 'Bebidas', quantity: 200, avgPrice: 13.80, currentPrice: 12.95, volatilityFactor: 0.7, bias: -0.3),
  Holding(ticker: 'RENT3', name: 'Localiza', sector: 'Serviços', quantity: 40, avgPrice: 51.00, currentPrice: 43.10, volatilityFactor: 1.3, bias: -0.6),
];

// ---------------------------------------------------------------------------
// Históricos fictícios (determinísticos: mesmo resultado a cada abertura)
// ---------------------------------------------------------------------------

final Map<String, List<double>> _priceCache = {};
final Map<PortfolioPeriod, List<double>> _portfolioCache = {};

/// Gera uma série fictícia determinística que termina em [current].
/// Usada por ações e criptomoedas.
List<double> syntheticSeries({
  required String key,
  required PortfolioPeriod period,
  required double current,
  double volatilityFactor = 1,
  double bias = 0,
}) {
  final seed = key.codeUnits.fold<int>(17, (s, c) => (s * 31 + c) & 0x7fffffff) +
      period.index * 7919;
  final rnd = math.Random(seed);
  final vol = period.volatility * volatilityFactor;
  final raw = <double>[1.0];
  for (var i = 1; i < period.points; i++) {
    final r = bias * vol * 0.25 + (rnd.nextDouble() * 2 - 1) * vol;
    raw.add(raw.last * (1 + r));
  }
  final scale = current / raw.last;
  return [for (final v in raw) v * scale];
}

/// Momento de cada ponto da série (o último ponto é "agora").
DateTime pointTime(PortfolioPeriod p, int i) {
  final n = p.points;
  final span = switch (p) {
    PortfolioPeriod.day => const Duration(hours: 24),
    PortfolioPeriod.week => const Duration(days: 7),
    PortfolioPeriod.month => const Duration(days: 29),
    PortfolioPeriod.year => const Duration(days: 365),
  };
  final stepMs = span.inMilliseconds / (n - 1);
  return DateTime.now().subtract(Duration(milliseconds: ((n - 1 - i) * stepMs).round()));
}

/// Série de preços da ação no período; sempre termina no preço atual.
List<double> priceSeries(Holding h, PortfolioPeriod p) {
  return _priceCache.putIfAbsent('${h.ticker}-${p.index}', () {
    final seed = h.ticker.codeUnits.fold<int>(17, (s, c) => (s * 31 + c) & 0x7fffffff) +
        p.index * 7919;
    final rnd = math.Random(seed);
    final vol = p.volatility * h.volatilityFactor;
    final raw = <double>[1.0];
    for (var i = 1; i < p.points; i++) {
      final r = h.bias * vol * 0.25 + (rnd.nextDouble() * 2 - 1) * vol;
      raw.add(raw.last * (1 + r));
    }
    final scale = h.currentPrice / raw.last;
    return [for (final v in raw) v * scale];
  });
}

/// Valor total da carteira ao longo do período.
List<double> portfolioSeries(PortfolioPeriod p) {
  return _portfolioCache.putIfAbsent(p, () {
    return List<double>.generate(p.points, (i) {
      var sum = 0.0;
      for (final h in holdings) {
        sum += h.quantity * priceSeries(h, p)[i];
      }
      return sum;
    });
  });
}

Perf portfolioPerf(PortfolioPeriod p) {
  final s = portfolioSeries(p);
  return Perf(s.first, s.last);
}

/// Desempenho da posição (quantidade × preço) no período.
Perf holdingPerf(Holding h, PortfolioPeriod p) {
  final s = priceSeries(h, p);
  return Perf(h.quantity * s.first, h.quantity * s.last);
}

double get portfolioValue => holdings.fold<double>(0, (s, h) => s + h.value);
double get portfolioInvested => holdings.fold<double>(0, (s, h) => s + h.invested);

/// Valor por setor, do maior para o menor.
List<(String, double)> sectorTotals() {
  final map = <String, double>{};
  for (final h in holdings) {
    map[h.sector] = (map[h.sector] ?? 0) + h.value;
  }
  return map.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
}
