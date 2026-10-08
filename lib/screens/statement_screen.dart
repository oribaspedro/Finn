import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/finn_page.dart';
import '../widgets/transaction_tile.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  int _filter = 0; // 0 tudo, 1 entradas, 2 saídas
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Transaction>>(
      valueListenable: transactions,
      builder: (context, all, _) {
        final since = DateTime.now().subtract(Duration(days: _days));
        final inPeriod = all.where((t) => t.date.isAfter(since)).toList();
        final income = inPeriod.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
        final expense = inPeriod.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount.abs());

        final shown = inPeriod
            .where((t) =>
                _filter == 0 || (_filter == 1 && t.isIncome) || (_filter == 2 && !t.isIncome))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return FinnPage(
          title: 'Extrato',
          headerExtra: _Summary(income: income, expense: expense),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  children: [
                    // Os três filtros ficam sempre na mesma linha do seletor de
                    // dias: se faltar espaço, o grupo encolhe em vez de quebrar.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final (i, label) in ['Tudo', 'Entradas', 'Saídas'].indexed)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _chip(label, _filter == i, () => setState(() => _filter = i)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<int>(
                      tooltip: 'Período',
                      initialValue: _days,
                      onSelected: (v) => setState(() => _days = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 7, child: Text('Últimos 7 dias')),
                        PopupMenuItem(value: 15, child: Text('Últimos 15 dias')),
                        PopupMenuItem(value: 30, child: Text('Últimos 30 dias')),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_days dias',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: FinnTheme.secondaryBlue,
                                  fontWeight: FontWeight.w600)),
                          const Icon(Icons.expand_more, size: 20, color: FinnTheme.secondaryBlue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Text('Nenhuma movimentação no período.',
                            style: TextStyle(color: Colors.black54)),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        children: _buildGroups(shown),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: FinnTheme.secondaryBlue,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelStyle: TextStyle(
          fontSize: 13,
          color: selected ? FinnTheme.white : FinnTheme.black,
        ),
        onSelected: (_) => onTap(),
      );

  List<Widget> _buildGroups(List<Transaction> items) {
    final widgets = <Widget>[];
    DateTime? lastDay;
    for (final t in items) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (lastDay != day) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(
            formatDateHeader(t.date),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ));
        lastDay = day;
      }
      widgets.add(TransactionTile(transaction: t, showDate: false));
    }
    return widgets;
  }
}

class _Summary extends StatelessWidget {
  final double income;
  final double expense;
  const _Summary({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    Widget block(String label, double value, Color color, IconData icon) => Expanded(
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatBRL(value),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontFamilyFallback: FinnTheme.serifFallback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: FinnTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          block('Entradas', income, FinnTheme.gain, Icons.south_west),
          const SizedBox(width: 12),
          block('Saídas', expense, FinnTheme.red, Icons.north_east),
        ],
      ),
    );
  }
}
