import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/currency_input.dart';
import '../utils/format.dart';
import '../utils/payment_planner.dart';
import '../widgets/confirm_sheet.dart';
import '../widgets/finn_page.dart';
import '../widgets/payment_source.dart';
import 'receipt_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _agency = TextEditingController();
  final _account = TextEditingController();
  final _holder = TextEditingController();
  final _doc = TextEditingController();
  final _amount = TextEditingController();

  int _mode = 0; // 0 = outro banco (TED), 1 = entre minhas contas
  String _to = accounts.value.first.name; // destino (modo entre contas)
  Set<String> _selected = accounts.value.map((a) => a.name).toSet();
  SplitStrategy _strategy = SplitStrategy.largestFirst;

  Set<String> get _excluded => _mode == 1 ? {_to} : const {};

  @override
  void dispose() {
    for (final c in [_bank, _agency, _account, _holder, _doc, _amount]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final value = parseBRL(_amount.text);
    final sources = sourcesFor(accounts.value, _selected, _excluded);
    final flows = planPayment(amount: value, sources: sources, strategy: _strategy);
    if (flows == null) return;

    final between = _mode == 1;
    final destination = between
        ? _to
        : '${_holder.text.trim()} • ${_bank.text.trim()}';

    final rows = <(String, String)>[
      ('Tipo', between ? 'Entre minhas contas' : 'TED'),
      ('Destino', destination),
      if (!between) ('Agência / Conta', '${_agency.text.trim()} / ${_account.text.trim()}'),
      if (!between) ('CPF/CNPJ', _doc.text.trim()),
    ];
    final sections = <(String, List<BankFlow>)>[
      ('Saiu de', flows),
      if (between) ('Entrou em', [BankFlow(_to, value)]),
    ];

    final ok = await showConfirmSheet(
      context,
      title: 'Confirmar transferência',
      amount: value,
      rows: rows,
      flowSections: sections,
    );
    if (!ok || !mounted) return;

    final now = DateTime.now();
    applyDebits(flows);
    if (between) {
      applyCredit(BankFlow(_to, value));
      addTransactions([
        Transaction(
          title: 'Transferência para $_to',
          subtitle: 'Entre contas',
          amount: -value,
          date: now,
          icon: Icons.swap_horiz,
          flows: flows,
        ),
        Transaction(
          title: 'Transferência de ${flows.map((f) => f.bank).join(', ')}',
          subtitle: 'Entre contas',
          amount: value,
          date: now,
          icon: Icons.swap_horiz,
          flows: [BankFlow(_to, value)],
        ),
      ]);
    } else {
      addTransactions([
        Transaction(
          title: 'TED para ${_holder.text.trim()}',
          subtitle: 'TED',
          amount: -value,
          date: now,
          icon: Icons.redo,
          flows: flows,
        ),
      ]);
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          title: 'Transferência realizada',
          amount: value,
          flowSections: sections,
          rows: [
            ...rows,
            ('Data', formatDateTime(now)),
            ('Autenticação', 'T${now.millisecondsSinceEpoch}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FinnPage(
      title: 'Transferências',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Row(
              children: [
                for (final (i, label) in ['Outro banco (TED)', 'Entre minhas contas'].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _ModeButton(
                      label: label,
                      selected: _mode == i,
                      onTap: () => setState(() => _mode = i),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            if (_mode == 1) ...[
              const Text('Conta de destino',
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in accounts.value)
                    ChoiceChip(
                      avatar: CircleAvatar(radius: 6, backgroundColor: a.color),
                      label: Text(a.name),
                      selected: _to == a.name,
                      showCheckmark: false,
                      selectedColor: FinnTheme.secondaryBlue,
                      labelStyle: TextStyle(
                        color: _to == a.name ? FinnTheme.white : FinnTheme.black,
                      ),
                      onSelected: (_) => setState(() => _to = a.name),
                    ),
                ],
              ),
            ] else ...[
              TextFormField(
                controller: _bank,
                textCapitalization: TextCapitalization.words,
                decoration: finnInput('Banco de destino', icon: Icons.account_balance_outlined),
                validator: (v) => _required(v, 'Informe o banco'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _agency,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: finnInput('Agência'),
                      validator: (v) =>
                          (v == null || v.length != 4) ? '4 dígitos' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _account,
                      keyboardType: TextInputType.number,
                      decoration: finnInput('Conta com dígito', hint: '12345-6'),
                      validator: (v) => _required(v, 'Informe a conta'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _holder,
                textCapitalization: TextCapitalization.words,
                decoration: finnInput('Nome do titular', icon: Icons.person_outline),
                validator: (v) => _required(v, 'Informe o titular'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doc,
                keyboardType: TextInputType.number,
                decoration: finnInput('CPF ou CNPJ', icon: Icons.badge_outlined),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  return (digits.length == 11 || digits.length == 14)
                      ? null
                      : 'Informe um CPF (11) ou CNPJ (14 dígitos)';
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              onChanged: (_) => setState(() {}),
              decoration: finnInput('Valor', hint: 'R\$0,00', icon: Icons.attach_money),
              validator: (v) {
                final value = parseBRL(v ?? '');
                if (value <= 0) return 'Informe um valor maior que zero';
                final sources = sourcesFor(accounts.value, _selected, _excluded);
                if (sources.isEmpty) return 'Selecione ao menos uma conta';
                if (!canCover(value, sources)) {
                  return 'Saldo insuficiente (disponível ${formatBRL(sumBalances(sources))})';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            PaymentSourcePicker(
              selected: _selected,
              onSelectionChanged: (s) => setState(() => _selected = s),
              strategy: _strategy,
              onStrategyChanged: (s) => setState(() => _strategy = s),
              amount: parseBRL(_amount.text),
              excluded: _excluded,
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Continuar', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Botão de modo (ocupa metade da linha; o texto encolhe se faltar espaço).
class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FinnTheme.secondaryBlue : FinnTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? FinnTheme.secondaryBlue : FinnTheme.lightGray),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? FinnTheme.white : FinnTheme.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
