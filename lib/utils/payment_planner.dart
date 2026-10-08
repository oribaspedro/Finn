import '../data/mock_data.dart';

/// Como dividir um pagamento entre as contas escolhidas.
enum SplitStrategy { largestFirst, proportional }

extension SplitStrategyLabel on SplitStrategy {
  String get label => switch (this) {
        SplitStrategy.largestFirst => 'Maior saldo primeiro',
        SplitStrategy.proportional => 'Proporcional ao saldo',
      };
}

int _cents(double v) => (v * 100).round();

int availableCents(Iterable<BankAccount> sources) =>
    sources.fold<int>(0, (s, a) => s + _cents(a.balance));

double sumBalances(Iterable<BankAccount> sources) => availableCents(sources) / 100;

/// Contas que podem pagar: as selecionadas, menos as excluídas (ex.: destino).
List<BankAccount> sourcesFor(
  List<BankAccount> all,
  Set<String> selected,
  Set<String> excluded,
) =>
    [
      for (final a in all)
        if (selected.contains(a.name) && !excluded.contains(a.name)) a,
    ];

bool canCover(double amount, List<BankAccount> sources) =>
    _cents(amount) <= availableCents(sources);

/// Divide [amount] entre [sources] (em centavos, sem erro de arredondamento).
/// Retorna null se o valor for inválido ou o saldo somado não for suficiente.
List<BankFlow>? planPayment({
  required double amount,
  required List<BankAccount> sources,
  required SplitStrategy strategy,
}) {
  final cents = _cents(amount);
  final total = availableCents(sources);
  if (cents <= 0 || cents > total) return null;

  if (strategy == SplitStrategy.largestFirst) {
    final sorted = [...sources]..sort((a, b) => b.balance.compareTo(a.balance));
    var remaining = cents;
    final result = <BankFlow>[];
    for (final a in sorted) {
      if (remaining == 0) break;
      final take = _cents(a.balance) < remaining ? _cents(a.balance) : remaining;
      if (take > 0) {
        result.add(BankFlow(a.name, take / 100));
        remaining -= take;
      }
    }
    return result;
  }

  // Proporcional ao saldo de cada conta; centavos que sobram vão para as
  // contas de maior saldo.
  final parts = <int>[
    for (final a in sources) cents * _cents(a.balance) ~/ total,
  ];
  var remaining = cents - parts.fold<int>(0, (s, p) => s + p);
  final order = [for (var i = 0; i < sources.length; i++) i]
    ..sort((x, y) => sources[y].balance.compareTo(sources[x].balance));
  var guard = 0;
  while (remaining > 0 && guard < 10000) {
    for (final i in order) {
      if (remaining == 0) break;
      if (parts[i] < _cents(sources[i].balance)) {
        parts[i]++;
        remaining--;
      }
    }
    guard++;
  }
  return [
    for (var i = 0; i < sources.length; i++)
      if (parts[i] > 0) BankFlow(sources[i].name, parts[i] / 100),
  ];
}
