import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'finn_page.dart';
import 'flow_list.dart';

/// Resumo da operação com botão de confirmar. Retorna true se confirmado.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required double amount,
  required List<(String, String)> rows,
  List<(String, List<BankFlow>)> flowSections = const [],
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: FinnTheme.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              formatBRL(amount),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: FinnTheme.secondaryBlue,
                fontFamilyFallback: FinnTheme.serifFallback,
              ),
            ),
            const SizedBox(height: 12),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
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
            if (flowSections.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
              FlowSections(sections: flowSections),
            ],
            const SizedBox(height: 8),
            PrimaryButton(label: 'Confirmar', onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: FinnTheme.secondaryBlue)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
