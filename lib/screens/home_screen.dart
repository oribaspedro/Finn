import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/finn_header.dart';
import '../widgets/portfolio_window.dart';
import 'balance_distribution_screen.dart';
import 'cards_screen.dart';
import 'pix_screen.dart';
import 'statement_screen.dart';
import 'transfer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.receipt_long, 'Extrato', () => _go(context, const StatementScreen())),
      _Action(Icons.attach_money, 'Pix', () => _go(context, const PixScreen())),
      _Action(Icons.credit_card, 'Cartões', () => _go(context, const CardsScreen())),
      _Action(Icons.redo, 'Transferências', () => _go(context, const TransferScreen())),
    ];

    return Scaffold(
      backgroundColor: FinnTheme.mainBlue,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_outlined,
                          color: FinnTheme.white, size: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Olá, ',
                            children: [
                              TextSpan(
                                text: 'Lucas!',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          style: TextStyle(color: FinnTheme.white, fontSize: 18),
                        ),
                      ),
                      const FinnLogo(width: 120),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _BalanceCard(
                    onTap: () => _go(context, const BalanceDistributionScreen()),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: FinnTheme.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 36, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carrossel de ações rápidas
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final a in actions) ...[
                              _ActionButton(action: a),
                              const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Janela com a performance da carteira de criptomoedas
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: CryptoWindow(),
                      ),
                      const SizedBox(height: 20),
                      // Janela com a performance da carteira de ações
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: PortfolioWindow(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BalanceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FinnTheme.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 20, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo total:',
                        style: TextStyle(fontSize: 12, color: FinnTheme.secondaryBlue)),
                    const SizedBox(height: 2),
                    // Atualiza sozinho quando um pagamento muda o saldo das contas.
                    ValueListenableBuilder<List<BankAccount>>(
                      valueListenable: accounts,
                      builder: (context, _, __) => Text(
                        formatBRL(totalBalance),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: FinnTheme.secondaryBlue,
                          fontFamilyFallback: FinnTheme.serifFallback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: FinnTheme.secondaryBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  _Action(this.icon, this.label, this.onTap);
}

class _ActionButton extends StatelessWidget {
  final _Action action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FinnTheme.secondaryBlue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: SizedBox(
          width: 118,
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: FinnTheme.white, size: 26),
              const SizedBox(height: 10),
              Text(
                action.label,
                style: const TextStyle(color: FinnTheme.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
