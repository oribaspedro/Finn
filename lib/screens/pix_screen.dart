import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/finn_page.dart';
import '../widgets/transaction_tile.dart';
import 'pix_keys_screen.dart';
import 'pix_receive_screen.dart';
import 'pix_send_screen.dart';

class PixScreen extends StatelessWidget {
  const PixScreen({super.key});

  void _go(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return FinnPage(
      title: 'Pix',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: _PixAction(
                  icon: Icons.north_east,
                  label: 'Enviar',
                  onTap: () => _go(context, const PixSendScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PixAction(
                  icon: Icons.south_west,
                  label: 'Receber',
                  onTap: () => _go(context, const PixReceiveScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PixAction(
                  icon: Icons.vpn_key_outlined,
                  label: 'Minhas chaves',
                  onTap: () => _go(context, const PixKeysScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const SectionTitle('Contatos frequentes'),
          const SizedBox(height: 14),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: frequentContacts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (context, i) {
                final c = frequentContacts[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _go(context, PixSendScreen(contact: c)),
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: c.color,
                          child: Text(
                            c.initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.color.computeLuminance() > 0.5
                                  ? FinnTheme.black
                                  : FinnTheme.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.name.split(' ').first,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const SectionTitle('Últimos Pix'),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<Transaction>>(
            valueListenable: transactions,
            builder: (context, list, _) {
              final pix = list.where((t) => t.subtitle.startsWith('Pix')).take(4).toList();
              if (pix.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhum Pix recente.',
                      style: TextStyle(color: Colors.black54)),
                );
              }
              return Column(
                children: [for (final t in pix) TransactionTile(transaction: t)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PixAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PixAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FinnTheme.secondaryBlue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: FinnTheme.white, size: 26),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: FinnTheme.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
