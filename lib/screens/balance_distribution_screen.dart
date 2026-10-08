import 'package:flutter/material.dart';
import '../data/crypto_data.dart';
import '../data/mock_data.dart';
import '../data/portfolio_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/payment_planner.dart';
import '../widgets/donut_chart.dart';
import '../widgets/finn_header.dart';
import '../widgets/finn_page.dart';
import '../widgets/transaction_tile.dart';
import 'portfolio_screen.dart' show StatCard;

class BalanceDistributionScreen extends StatelessWidget {
  const BalanceDistributionScreen({super.key});

  /// Entradas e saídas de um banco nos últimos 30 dias.
  (double, double) _monthFlow(String bank, List<Transaction> all) {
    final since = DateTime.now().subtract(const Duration(days: 30));
    var inc = 0.0, out = 0.0;
    for (final t in all.where((t) => t.date.isAfter(since))) {
      final v = t.flows.where((f) => f.bank == bank).fold<double>(0, (s, f) => s + f.amount);
      if (t.isIncome) {
        inc += v;
      } else {
        out += v;
      }
    }
    return (inc, out);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BankAccount>>(
      valueListenable: accounts,
      builder: (context, list, _) {
        return ValueListenableBuilder<List<Transaction>>(
          valueListenable: transactions,
          builder: (context, txs, _) {
            final total = sumBalances(list);
            double pct(BankAccount a) => total > 0 ? a.balance / total * 100 : 0;

            // Ordem dos segmentos no gráfico grande (sentido horário a partir do topo).
            final order = [
              for (final i in const [3, 2, 0, 1])
                if (i < list.length) i,
            ];
            final sorted = [...list]..sort((a, b) => b.balance.compareTo(a.balance));
            final biggest = sorted.first;
            final smallest = sorted.last;
            final stocks = portfolioValue;
            final crypto = cryptoValue;
            final wealth = total + stocks + crypto;

            return Scaffold(
              backgroundColor: FinnTheme.white,
              body: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: FinnTheme.mainBlue,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(
                          children: [
                            const FinnBackHeader(title: 'Distribuição de saldo:'),
                            const SizedBox(height: 24),
                            DonutChart(
                              size: 230,
                              strokeWidth: 30,
                              trackColor: total > 0 ? null : FinnTheme.lightGray,
                              segments: [
                                for (final i in order)
                                  if (list[i].balance > 0)
                                    DonutSegment(list[i].balance, list[i].color),
                              ],
                              center: Container(
                                width: 170,
                                height: 170,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: FinnTheme.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Saldo total',
                                        style: TextStyle(
                                            fontSize: 12, color: FinnTheme.secondaryBlue)),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatBRL(total),
                                      style: const TextStyle(
                                        color: FinnTheme.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      children: [
                        // Destaques
                        Row(
                          children: [
                            Expanded(
                              child: StatCard('Maior saldo', biggest.name,
                                  sub: '${formatBRL(biggest.balance)} • ${formatPct(pct(biggest))}',
                                  color: FinnTheme.secondaryBlue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard('Menor saldo', smallest.name,
                                  sub: '${formatBRL(smallest.balance)} • ${formatPct(pct(smallest))}'),
                            ),
                          ],
                        ),

                        // Contas (toque para ver detalhes)
                        const SizedBox(height: 28),
                        const SectionTitle('Minhas contas'),
                        const SizedBox(height: 8),
                        for (final a in sorted)
                          _AccountRow(
                            account: a,
                            percent: pct(a),
                            onTap: () => _showAccount(context, a, pct(a), txs),
                          ),

                        // Participação de cada conta
                        const SizedBox(height: 24),
                        const SectionTitle('Participação de cada conta'),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (_, i) =>
                              _BankDonut(account: list[i], percent: pct(list[i])),
                        ),

                        // Movimentação do mês por conta
                        const SizedBox(height: 28),
                        const SectionTitle('Movimentação nos últimos 30 dias'),
                        const SizedBox(height: 8),
                        for (final a in list)
                          Builder(builder: (_) {
                            final (inc, out) = _monthFlow(a.name, txs);
                            return _FlowRow(account: a, income: inc, expense: out);
                          }),

                        // Patrimônio total
                        const SizedBox(height: 28),
                        const SectionTitle('Patrimônio total'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xfff5f5f5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatBRL(wealth),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: FinnTheme.secondaryBlue,
                                  fontFamilyFallback: FinnTheme.serifFallback,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _WealthBar(parts: [
                                ('Contas', total, FinnTheme.secondaryBlue),
                                ('Ações', stocks, FinnTheme.blue),
                                ('Criptomoedas', crypto, FinnTheme.yellow),
                              ], whole: wealth),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccount(BuildContext context, BankAccount a, double percent, List<Transaction> txs) {
    final related = txs
        .where((t) => t.flows.any((f) => f.bank == a.name))
        .take(5)
        .toList();
    final (inc, out) = _monthFlow(a.name, txs);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FinnTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FinnTheme.lightGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: a.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(a.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formatBRL(a.balance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: FinnTheme.secondaryBlue,
                    fontFamilyFallback: FinnTheme.serifFallback,
                  ),
                ),
                Text('${formatPct(percent)} do saldo total',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: StatCard('Entradas (30 dias)', formatBRL(inc), color: FinnTheme.gain)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard('Saídas (30 dias)', formatBRL(out), color: FinnTheme.red)),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionTitle('Últimas movimentações'),
                const SizedBox(height: 4),
                if (related.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Nenhuma movimentação nesta conta.',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                  )
                else
                  for (final t in related) TransactionTile(transaction: t),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha da conta: cor, nome, saldo, % e barra de participação.
class _AccountRow extends StatelessWidget {
  final BankAccount account;
  final double percent;
  final VoidCallback onTap;
  const _AccountRow({required this.account, required this.percent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: account.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(account.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Text(formatBRL(account.balance),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xffe6e6e6),
                      valueColor: AlwaysStoppedAnimation(account.color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text(formatPct(percent),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowRow extends StatelessWidget {
  final BankAccount account;
  final double income;
  final double expense;
  const _FlowRow({required this.account, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: account.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '+ ${formatBRL(income)}  •  - ${formatBRL(expense)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            formatSigned(net),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: net >= 0 ? FinnTheme.gain : FinnTheme.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _WealthBar extends StatelessWidget {
  final List<(String, double, Color)> parts;
  final double whole;
  const _WealthBar({required this.parts, required this.whole});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final p in parts)
                  if (p.$2 > 0)
                    Expanded(
                      flex: (p.$2 / whole * 1000).round().clamp(1, 1000),
                      child: Container(color: p.$3),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final p in parts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: p.$3, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(p.$1, style: const TextStyle(fontSize: 13))),
                Text(formatBRL(p.$2),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: Text(formatPct(whole > 0 ? p.$2 / whole * 100 : 0),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BankDonut extends StatelessWidget {
  final BankAccount account;
  final double percent;
  const _BankDonut({required this.account, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DonutChart(
          size: 130,
          strokeWidth: 16,
          trackColor: const Color(0xffe6e6e6),
          maxValue: 100,
          segments: [DonutSegment(percent, account.color)],
          center: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${formatBRL(account.balance)}\n${formatPct(percent)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FinnTheme.black,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          account.name,
          style: const TextStyle(
            color: FinnTheme.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
