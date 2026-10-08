import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/payment_planner.dart';
import 'flow_list.dart';

/// Escolha das contas que vão pagar + prévia de quanto sai de cada banco.
/// O Finn soma o saldo das contas selecionadas e faz um pagamento só.
class PaymentSourcePicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onSelectionChanged;
  final SplitStrategy strategy;
  final ValueChanged<SplitStrategy> onStrategyChanged;
  final double amount;
  final Set<String> excluded;

  const PaymentSourcePicker({
    super.key,
    required this.selected,
    required this.onSelectionChanged,
    required this.strategy,
    required this.onStrategyChanged,
    required this.amount,
    this.excluded = const {},
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BankAccount>>(
      valueListenable: accounts,
      builder: (context, list, _) {
        final sources = sourcesFor(list, selected, excluded);
        final available = sumBalances(sources);
        final plan = amount > 0
            ? planPayment(amount: amount, sources: sources, strategy: strategy)
            : null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xfff5f5f5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Pagar com o saldo das contas',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Disponível nas contas escolhidas: ${formatBRL(available)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in list)
                    _AccountChip(
                      account: a,
                      selected: selected.contains(a.name) && !excluded.contains(a.name),
                      enabled: !excluded.contains(a.name),
                      onChanged: (on) {
                        final next = {...selected};
                        on ? next.add(a.name) : next.remove(a.name);
                        onSelectionChanged(next);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Como dividir',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in SplitStrategy.values)
                    ChoiceChip(
                      label: Text(s.label, style: const TextStyle(fontSize: 12)),
                      selected: strategy == s,
                      showCheckmark: false,
                      selectedColor: FinnTheme.secondaryBlue,
                      labelStyle: TextStyle(
                        color: strategy == s ? FinnTheme.white : FinnTheme.black,
                      ),
                      onSelected: (_) => onStrategyChanged(s),
                    ),
                ],
              ),
              if (amount > 0) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (sources.isEmpty)
                  const Text('Selecione ao menos uma conta.',
                      style: TextStyle(color: FinnTheme.red, fontSize: 13))
                else if (plan == null)
                  const Text('Saldo insuficiente nas contas selecionadas.',
                      style: TextStyle(color: FinnTheme.red, fontSize: 13))
                else ...[
                  Text(
                    plan.length == 1
                        ? 'Sai de 1 conta'
                        : 'Sai de ${plan.length} contas, em um pagamento só',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  FlowRows(flows: plan),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AccountChip extends StatelessWidget {
  final BankAccount account;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _AccountChip({
    required this.account,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? FinnTheme.white : FinnTheme.black;
    return FilterChip(
      showCheckmark: false,
      selected: selected,
      selectedColor: FinnTheme.secondaryBlue,
      avatar: CircleAvatar(radius: 6, backgroundColor: account.color),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(account.name, style: TextStyle(fontSize: 12, color: fg)),
          Text(formatBRL(account.balance),
              style: TextStyle(fontSize: 11, color: fg.withOpacity(0.8))),
        ],
      ),
      onSelected: enabled ? onChanged : null,
    );
  }
}
