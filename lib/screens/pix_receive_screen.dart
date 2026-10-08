import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/finn_page.dart';

class PixReceiveScreen extends StatefulWidget {
  const PixReceiveScreen({super.key});

  @override
  State<PixReceiveScreen> createState() => _PixReceiveScreenState();
}

class _PixReceiveScreenState extends State<PixReceiveScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return FinnPage(
      title: 'Receber Pix',
      child: ValueListenableBuilder<List<PixKey>>(
        valueListenable: pixKeys,
        builder: (context, keys, _) {
          if (keys.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Cadastre uma chave Pix em "Minhas chaves" para receber.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          final int idx = _selected < keys.length ? _selected : 0;
          final key = keys[idx];
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            children: [
              const SectionTitle('Escolha a chave'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < keys.length; i++)
                    ChoiceChip(
                      label: Text(keys[i].type),
                      selected: idx == i,
                      showCheckmark: false,
                      selectedColor: FinnTheme.secondaryBlue,
                      labelStyle: TextStyle(
                        color: idx == i ? FinnTheme.white : FinnTheme.black,
                      ),
                      onSelected: (_) => setState(() => _selected = i),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FinnTheme.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: FinnTheme.lightGray),
                  ),
                  child: const Icon(Icons.qr_code_2, size: 200, color: FinnTheme.black),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  key.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(key.type,
                    style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xfff5f5f5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accountByName(key.bank).color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Os valores recebidos por esta chave entram no ${key.bank}.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Copiar chave',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: key.value));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chave copiada')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
