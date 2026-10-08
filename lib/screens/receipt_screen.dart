import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/finn_page.dart';
import '../widgets/flow_list.dart';

class ReceiptScreen extends StatelessWidget {
  final String title;
  final double amount;
  final List<(String, String)> rows;
  final List<(String, List<BankFlow>)> flowSections;

  const ReceiptScreen({
    super.key,
    required this.title,
    required this.amount,
    required this.rows,
    this.flowSections = const [],
  });

  @override
  Widget build(BuildContext context) {
    return FinnPage(
      title: 'Comprovante',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: FinnTheme.mainBlue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: FinnTheme.mainBlue, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              formatBRL(amount),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: FinnTheme.secondaryBlue,
                fontFamilyFallback: FinnTheme.serifFallback,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (flowSections.isNotEmpty) ...[
            FlowSections(sections: flowSections),
            const Divider(height: 1),
          ],
          for (final r in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.$1, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(r.$2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Concluir',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}
