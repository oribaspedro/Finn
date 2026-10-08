import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../utils/format.dart';

/// Linhas "● Banco ........ R$ valor".
class FlowRows extends StatelessWidget {
  final List<BankFlow> flows;
  const FlowRows({super.key, required this.flows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in flows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(f.bank, style: const TextStyle(fontSize: 14))),
                Text(
                  formatBRL(f.amount),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Blocos com título: "Saiu de" / "Entrou em" + linhas por banco.
class FlowSections extends StatelessWidget {
  final List<(String, List<BankFlow>)> sections;
  const FlowSections({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in sections) ...[
          Text(
            s.$1,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          FlowRows(flows: s.$2),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
