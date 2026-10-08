import 'package:flutter/material.dart';
import '../data/crypto_data.dart';
import '../data/portfolio_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/donut_chart.dart';
import '../widgets/finn_page.dart';
import '../widgets/performance_chart.dart';
import '../widgets/portfolio_window.dart';
import 'portfolio_screen.dart' show StatCard, EmptyNote;

/// Detalhes da carteira de criptomoedas (mesmo estilo da carteira de ações).
class CryptoScreen extends StatefulWidget {
  final PortfolioPeriod initialPeriod;
  const CryptoScreen({super.key, this.initialPeriod = PortfolioPeriod.day});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  late PortfolioPeriod _period = widget.initialPeriod;
  int? _hover;

  static const _palette = [
    FinnTheme.blue,
    FinnTheme.yellow,
    FinnTheme.pink,
    FinnTheme.red,
    FinnTheme.secondaryBlue,
    FinnTheme.mainBlue,
  ];

  Color _color(int i) => _palette[i % _palette.length];

  @override
  Widget build(BuildContext context) {
    final series = cryptoPortfolioSeries(_period);
    final idx = _hover ?? series.length - 1;
    final value = series[idx];
    final perf = Perf(series.first, value);

    final ranked = [for (final c in cryptoHoldings) (c, cryptoHoldingPerf(c, _period))]
      ..sort((a, b) => b.$2.pct.compareTo(a.$2.pct));
    final gainers = ranked.where((r) => r.$2.pct > 0).take(3).toList();
    final losers = ranked.reversed.where((r) => r.$2.pct < 0).take(3).toList();

    final invested = cryptoInvested;
    final current = cryptoValue;
    final totalReturn = current - invested;
    final totalReturnPct = invested == 0 ? 0.0 : totalReturn / invested * 100;
    final byValue = [...cryptoHoldings]..sort((a, b) => b.value.compareTo(a.value));

    return FinnPage(
      title: 'Carteira de criptomoedas',
      headerExtra: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FinnTheme.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _hover == null
                        ? 'Valor da carteira'
                        : 'Valor em ${chartTimeLabelFull(_period, _hover!)}',
                    style: const TextStyle(fontSize: 12, color: FinnTheme.secondaryBlue),
                  ),
                ),
                PeriodDropdown(
                  value: _period,
                  onChanged: (p) => setState(() {
                    _period = p;
                    _hover = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formatBRL(value),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: FinnTheme.secondaryBlue,
                fontFamilyFallback: FinnTheme.serifFallback,
              ),
            ),
            VariationText(perf: perf),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          PerformanceChart(
            values: series,
            height: 200,
            highlight: _hover,
            period: _period,
            onScrub: (i) => setState(() => _hover = i),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Arraste sobre o gráfico para ver cada ponto • ${_period.label.toLowerCase()}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: StatCard('Valor atual', formatBRL(current))),
              const SizedBox(width: 12),
              Expanded(child: StatCard('Valor investido', formatBRL(invested))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  'Resultado total',
                  formatSigned(totalReturn),
                  sub: formatPctSigned(totalReturnPct),
                  color: totalReturn >= 0 ? FinnTheme.gain : FinnTheme.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: StatCard('Criptomoedas', '${cryptoHoldings.length}')),
            ],
          ),
          const SizedBox(height: 28),
          SectionTitle('Maiores altas • ${_period.label.toLowerCase()}'),
          const SizedBox(height: 6),
          if (gainers.isEmpty)
            const EmptyNote('Nenhuma criptomoeda em alta no período.')
          else
            for (final r in gainers)
              CryptoTile(holding: r.$1, perf: r.$2, showPosition: false),
          const SizedBox(height: 20),
          SectionTitle('Maiores baixas • ${_period.label.toLowerCase()}'),
          const SizedBox(height: 6),
          if (losers.isEmpty)
            const EmptyNote('Nenhuma criptomoeda em baixa no período.')
          else
            for (final r in losers)
              CryptoTile(holding: r.$1, perf: r.$2, showPosition: false),
          const SizedBox(height: 28),
          const SectionTitle('Distribuição por moeda'),
          const SizedBox(height: 16),
          Row(
            children: [
              DonutChart(
                size: 130,
                strokeWidth: 22,
                segments: [
                  for (var i = 0; i < byValue.length; i++)
                    DonutSegment(byValue[i].value, _color(i)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < byValue.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _color(i),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(byValue[i].name,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Text(
                              formatPct(byValue[i].value / current * 100),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionTitle('Minhas criptomoedas'),
          const SizedBox(height: 6),
          for (final r in ranked)
            CryptoTile(holding: r.$1, perf: r.$2, showPosition: true),
        ],
      ),
    );
  }
}

/// Linha de uma criptomoeda. [showPosition]: valor da posição e quantidade;
/// caso contrário, cotação atual.
class CryptoTile extends StatelessWidget {
  final CryptoHolding holding;
  final Perf perf;
  final bool showPosition;
  const CryptoTile({
    super.key,
    required this.holding,
    required this.perf,
    required this.showPosition,
  });

  @override
  Widget build(BuildContext context) {
    final h = holding;
    final color = perf.isUp ? FinnTheme.gain : FinnTheme.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: FinnTheme.mainBlue.withOpacity(0.15),
            child: Text(
              h.symbol,
              style: TextStyle(
                fontSize: h.symbol.length > 3 ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: FinnTheme.secondaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  showPosition
                      ? '${formatQty(h.quantity)} ${h.symbol}'
                      : '${h.symbol} • ${formatBRL(h.currentPrice)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                showPosition ? formatBRL(h.value) : formatBRL(h.quantity * h.currentPrice),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(perf.isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 18, color: color),
                  Text(
                    formatPctSigned(perf.pct),
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
