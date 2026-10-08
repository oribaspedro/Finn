import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../utils/currency_input.dart';
import '../utils/format.dart';
import '../utils/payment_planner.dart';
import '../widgets/confirm_sheet.dart';
import '../widgets/finn_page.dart';
import '../widgets/payment_source.dart';
import 'receipt_screen.dart';

class PixSendScreen extends StatefulWidget {
  final PixContact? contact;
  const PixSendScreen({super.key, this.contact});

  @override
  State<PixSendScreen> createState() => _PixSendScreenState();
}

class _PixSendScreenState extends State<PixSendScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _key;
  final _amount = TextEditingController();
  final _note = TextEditingController();

  Set<String> _selected = accounts.value.map((a) => a.name).toSet();
  SplitStrategy _strategy = SplitStrategy.largestFirst;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController(text: widget.contact?.key ?? '');
  }

  @override
  void dispose() {
    _key.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final value = parseBRL(_amount.text);
    final sources = sourcesFor(accounts.value, _selected, const {});
    final flows = planPayment(amount: value, sources: sources, strategy: _strategy);
    if (flows == null) return;

    final name = widget.contact?.name ?? 'Chave ${_key.text.trim()}';
    final sections = [('Saiu de', flows)];

    final ok = await showConfirmSheet(
      context,
      title: 'Confirmar Pix',
      amount: value,
      rows: [
        ('Para', name),
        ('Chave', _key.text.trim()),
        if (_note.text.trim().isNotEmpty) ('Mensagem', _note.text.trim()),
      ],
      flowSections: sections,
    );
    if (!ok || !mounted) return;

    final now = DateTime.now();
    applyDebits(flows);
    addTransactions([
      Transaction(
        title: 'Pix para ${widget.contact?.name ?? _key.text.trim()}',
        subtitle: 'Pix enviado',
        amount: -value,
        date: now,
        icon: Icons.north_east,
        flows: flows,
      ),
    ]);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          title: 'Pix enviado',
          amount: value,
          flowSections: sections,
          rows: [
            ('Para', name),
            ('Chave', _key.text.trim()),
            ('Data', formatDateTime(now)),
            ('ID da transação', 'E${now.millisecondsSinceEpoch}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FinnPage(
      title: 'Enviar Pix',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            TextFormField(
              controller: _key,
              decoration: finnInput(
                'Chave Pix',
                hint: 'CPF, e-mail, celular ou chave aleatória',
                icon: Icons.vpn_key_outlined,
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 5) ? 'Informe uma chave válida' : null,
            ),
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
                final sources = sourcesFor(accounts.value, _selected, const {});
                if (sources.isEmpty) return 'Selecione ao menos uma conta';
                if (!canCover(value, sources)) {
                  return 'Saldo insuficiente (disponível ${formatBRL(sumBalances(sources))})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLength: 140,
              decoration: finnInput('Mensagem (opcional)', icon: Icons.chat_bubble_outline),
            ),
            const SizedBox(height: 8),
            PaymentSourcePicker(
              selected: _selected,
              onSelectionChanged: (s) => setState(() => _selected = s),
              strategy: _strategy,
              onStrategyChanged: (s) => setState(() => _strategy = s),
              amount: parseBRL(_amount.text),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Continuar', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
