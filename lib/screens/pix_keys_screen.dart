import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/finn_page.dart';

class PixKeysScreen extends StatelessWidget {
  const PixKeysScreen({super.key});

  IconData _icon(String type) {
    switch (type) {
      case 'CPF':
        return Icons.badge_outlined;
      case 'E-mail':
        return Icons.email_outlined;
      case 'Celular':
        return Icons.phone_iphone;
      default:
        return Icons.shuffle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FinnPage(
      title: 'Minhas chaves',
      child: ValueListenableBuilder<List<PixKey>>(
        valueListenable: pixKeys,
        builder: (context, keys, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              for (final k in keys)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: FinnTheme.mainBlue.withOpacity(0.15),
                    child: Icon(_icon(k.type), color: FinnTheme.secondaryBlue),
                  ),
                  title: Text(k.value,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('${k.type} • recebe no ${k.bank}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Copiar',
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: k.value));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chave copiada')),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => pixKeys.value =
                            keys.where((e) => e != k).toList(),
                      ),
                    ],
                  ),
                ),
              if (keys.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Você ainda não tem chaves cadastradas.',
                      style: TextStyle(color: Colors.black54)),
                ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Registrar nova chave',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: FinnTheme.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  builder: (_) => const _RegisterKeySheet(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RegisterKeySheet extends StatefulWidget {
  const _RegisterKeySheet();

  @override
  State<_RegisterKeySheet> createState() => _RegisterKeySheetState();
}

class _RegisterKeySheetState extends State<_RegisterKeySheet> {
  static const _types = ['CPF', 'E-mail', 'Celular', 'Aleatória'];
  int _type = 1;
  String _bank = accounts.value.first.name;
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _randomKey() {
    final r = Random.secure();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
  }

  void _save() {
    final type = _types[_type];
    final value = type == 'Aleatória' ? _randomKey() : _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Informe o valor da chave');
      return;
    }
    if (pixKeys.value.any((k) => k.value == value)) {
      setState(() => _error = 'Essa chave já está cadastrada');
      return;
    }
    pixKeys.value = [...pixKeys.value, PixKey(type, value, _bank)];
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isRandom = _types[_type] == 'Aleatória';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registrar chave Pix',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < _types.length; i++)
                    ChoiceChip(
                      label: Text(_types[i]),
                      selected: _type == i,
                      showCheckmark: false,
                      selectedColor: FinnTheme.secondaryBlue,
                      labelStyle: TextStyle(
                        color: _type == i ? FinnTheme.white : FinnTheme.black,
                      ),
                      onSelected: (_) => setState(() {
                        _type = i;
                        _error = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isRandom)
                const Text(
                  'Vamos gerar uma chave aleatória para você.',
                  style: TextStyle(color: Colors.black54),
                )
              else
                TextField(
                  controller: _controller,
                  keyboardType: _types[_type] == 'E-mail'
                      ? TextInputType.emailAddress
                      : TextInputType.number,
                  decoration: finnInput(_types[_type]).copyWith(errorText: _error),
                ),
              if (isRandom && _error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: FinnTheme.red)),
                ),
              const SizedBox(height: 16),
              const Text('Receber no banco',
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
                      selected: _bank == a.name,
                      showCheckmark: false,
                      selectedColor: FinnTheme.secondaryBlue,
                      labelStyle: TextStyle(
                        color: _bank == a.name ? FinnTheme.white : FinnTheme.black,
                      ),
                      onSelected: (_) => setState(() => _bank = a.name),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Registrar', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
