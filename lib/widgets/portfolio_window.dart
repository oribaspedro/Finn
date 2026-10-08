import 'package:flutter/material.dart';
import '../data/crypto_data.dart';
import '../data/portfolio_data.dart';
import '../screens/crypto_screen.dart';
import '../screens/portfolio_screen.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'performance_chart.dart';

/// Lista suspensa para escolher o período (último dia/semana/mês/ano).
class PeriodDropdown extends StatelessWidget {
  final PortfolioPeriod value;
  final ValueChanged<PortfolioPeriod> onChanged;
  const PeriodDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PortfolioPeriod>(
      tooltip: 'Período',
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final p in PortfolioPeriod.values)
          PopupMenuItem(
            value: p,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: p == value
                      ? const Icon(Icons.check, size: 18, color: FinnTheme.secondaryBlue)
                      : null,
                ),
                Text(p.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
        decoration: BoxDecoration(
          color: FinnTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FinnTheme.lightGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FinnTheme.secondaryBlue,
              ),
            ),
            const Icon(Icons.expand_more, size: 18, color: FinnTheme.secondaryBlue),
          ],
        ),
      ),
    );
  }
}

/// "▲ + R$ 120,00 (+1,25%)" em verde ou vermelho.
class VariationText extends StatelessWidget {
  final Perf perf;
  final double fontSize;
  const VariationText({super.key, required this.perf, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final color = perf.isUp ? FinnTheme.gain : FinnTheme.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(perf.isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: color, size: fontSize + 8),
        Flexible(
          child: Text(
            '${formatSigned(perf.change)} (${formatPctSigned(perf.pct)})',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}

/// Janelinha da home com o desempenho de uma carteira (ações ou criptomoedas).
class AssetWindow extends StatefulWidget {
  final String title;
  final List<double> Function(PortfolioPeriod) seriesFor;
  final Widget Function(PortfolioPeriod) detailsBuilder;

  const AssetWindow({
    super.key,
    required this.title,
    required this.seriesFor,
    required this.detailsBuilder,
  });

  @override
  State<AssetWindow> createState() => _AssetWindowState();
}

class _AssetWindowState extends State<AssetWindow> {
  PortfolioPeriod _period = PortfolioPeriod.day;

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    final series = widget.seriesFor(_period);
    final perf = Perf(series.first, series.last);

    return Container(
      decoration: BoxDecoration(
        color: FinnTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinnTheme.lightGray),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Barra de título da "janela"
            Container(
              color: const Color(0xfff2f2f2),
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  _dot(FinnTheme.red),
                  _dot(FinnTheme.yellow),
                  _dot(FinnTheme.mainBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  PeriodDropdown(
                    value: _period,
                    onChanged: (p) => setState(() => _period = p),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Corpo: toque abre os detalhes
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => widget.detailsBuilder(_period)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Valor da carteira',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text(
                      formatBRL(series.last),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: FinnTheme.secondaryBlue,
                        fontFamilyFallback: FinnTheme.serifFallback,
                      ),
                    ),
                    VariationText(perf: perf),
                    const SizedBox(height: 10),
                    PerformanceChart(values: series, height: 130, period: _period),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Ver detalhes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FinnTheme.secondaryBlue,
                            )),
                        Icon(Icons.chevron_right, size: 18, color: FinnTheme.secondaryBlue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carteira de ações.
class PortfolioWindow extends StatelessWidget {
  const PortfolioWindow({super.key});

  @override
  Widget build(BuildContext context) => AssetWindow(
        title: 'Carteira de ações',
        seriesFor: portfolioSeries,
        detailsBuilder: (p) => PortfolioScreen(initialPeriod: p),
      );
}

/// Carteira de criptomoedas.
class CryptoWindow extends StatelessWidget {
  const CryptoWindow({super.key});

  @override
  Widget build(BuildContext context) => AssetWindow(
        title: 'Carteira de criptomoedas',
        seriesFor: cryptoPortfolioSeries,
        detailsBuilder: (p) => CryptoScreen(initialPeriod: p),
      );
}
