import 'package:flutter/material.dart';
import '../data/portfolio_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/donut_chart.dart';
import '../widgets/finn_page.dart';
import '../widgets/performance_chart.dart';
import '../widgets/portfolio_window.dart';

class PortfolioScreen extends StatefulWidget {
  final PortfolioPeriod initialPeriod;
  const PortfolioScreen({super.key, this.initialPeriod = PortfolioPeriod.day});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late PortfolioPeriod _period = widget.initialPeriod;
  int? _hover;

  static const _sectorPalette = [
    FinnTheme.blue,
    FinnTheme.red,
    FinnTheme.yellow,
    FinnTheme.pink,
    FinnTheme.secondaryBlue,
    FinnTheme.mainBlue,
    FinnTheme.lightGray,
  ];

  Color _sectorColor(int i) => _sectorPalette[i % _sectorPalette.length];

  @override
  Widget build(BuildContext context) {
    final series = portfolioSeries(_period);
    final idx = _hover ?? series.length - 1;
    final value = series[idx];
    final perf = Perf(series.first, value);

    final ranked = [for (final h in holdings) (h, holdingPerf(h, _period))]
      ..sort((a, b) => b.$2.pct.compareTo(a.$2.pct));
    final gainers = ranked.where((r) => r.$2.pct > 0).take(3).toList();
    final losers = ranked.reversed.where((r) => r.$2.pct < 0).take(3).toList();

    final invested = portfolioInvested;
    final current = portfolioValue;
    final totalReturn = current - invested;
    final totalReturnPct = invested == 0 ? 0.0 : totalReturn / invested * 100;
    final sectors = sectorTotals();

    return FinnPage(
      title: 'Carteira de ações',
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
            height: 180,
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

          // Resumo
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
              Expanded(child: StatCard('Ativos na carteira', '${holdings.length}')),
            ],
          ),

          // Altas e baixas do período
          const SizedBox(height: 28),
          SectionTitle('Maiores altas • ${_period.label.toLowerCase()}'),
          const SizedBox(height: 6),
          if (gainers.isEmpty)
            const EmptyNote('Nenhuma ação em alta no período.')
          else
            for (final r in gainers) StockTile(holding: r.$1, perf: r.$2, mode: StockTileMode.price),
          const SizedBox(height: 20),
          SectionTitle('Maiores baixas • ${_period.label.toLowerCase()}'),
          const SizedBox(height: 6),
          if (losers.isEmpty)
            const EmptyNote('Nenhuma ação em baixa no período.')
          else
            for (final r in losers) StockTile(holding: r.$1, perf: r.$2, mode: StockTileMode.price),

          // Alocação por setor
          const SizedBox(height: 28),
          const SectionTitle('Distribuição por setor'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DonutChart(
                size: 130,
                strokeWidth: 22,
                segments: [
                  for (var i = 0; i < sectors.length; i++)
                    DonutSegment(sectors[i].$2, _sectorColor(i)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < sectors.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _sectorColor(i),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(sectors[i].$1,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Text(
                              formatPct(sectors[i].$2 / current * 100),
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

          // Todos os ativos
          const SizedBox(height: 28),
          const SectionTitle('Minhas ações'),
          const SizedBox(height: 6),
          for (final r in ranked)
            StockTile(holding: r.$1, perf: r.$2, mode: StockTileMode.position),
        ],
      ),
    );
  }
}

enum StockTileMode { price, position }

/// Linha de uma ação. [price]: cotação atual; [position]: valor da posição e quantidade.
class StockTile extends StatelessWidget {
  final Holding holding;
  final Perf perf; // desempenho da posição no período
  final StockTileMode mode;
  const StockTile({
    super.key,
    required this.holding,
    required this.perf,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final h = holding;
    final color = perf.isUp ? FinnTheme.gain : FinnTheme.red;
    final isPrice = mode == StockTileMode.price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: FinnTheme.mainBlue.withOpacity(0.15),
            child: Text(
              h.ticker.substring(0, 2),
              style: const TextStyle(
                fontSize: 13,
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
                Text(h.ticker,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  isPrice ? h.name : '${h.name} • ${h.quantity} ações',
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
                isPrice ? formatBRL(h.currentPrice) : formatBRL(h.value),
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

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? color;
  const StatCard(this.label, this.value, {this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff5f5f5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color ?? FinnTheme.black,
              ),
            ),
          ),
          if (sub != null)
            Text(sub!,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color ?? FinnTheme.black)),
        ],
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  final String text;
  const EmptyNote(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      );
}
