import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'flow_list.dart';

/// Linha de movimentação (Pix e Extrato). Toque abre o detalhe por banco.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool showDate;
  const TransactionTile({super.key, required this.transaction, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showTransactionDetail(context, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: FinnTheme.mainBlue.withOpacity(0.15),
              child: Icon(t.icon, color: FinnTheme.secondaryBlue, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(t.subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      for (final f in t.flows)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration:
                                BoxDecoration(color: f.color, shape: BoxShape.circle),
                          ),
                        ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          t.flowSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatSigned(t.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: t.isIncome ? FinnTheme.gain : FinnTheme.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showDate ? formatDateHeader(t.date) : formatTime(t.date),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showTransactionDetail(BuildContext context, Transaction t) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: FinnTheme.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${t.subtitle} • ${formatDateTime(t.date)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 10),
            Text(
              formatSigned(t.amount),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: t.isIncome ? FinnTheme.gain : FinnTheme.red,
                fontFamilyFallback: FinnTheme.serifFallback,
              ),
            ),
            const SizedBox(height: 16),
            if (!t.isIncome && t.flows.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Pagamento único feito juntando o saldo de ${t.flows.length} contas.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            FlowSections(sections: [(t.isIncome ? 'Entrou em' : 'Saiu de', t.flows)]),
          ],
        ),
      ),
    ),
  );
}
