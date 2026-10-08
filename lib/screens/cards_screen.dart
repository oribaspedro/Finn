import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/finn_page.dart';
import '../widgets/wallet_card.dart';

/// Telas 3 e 4 do mockup numa só tela: a pilha de cartões e o cartão
/// selecionado. Tudo é animado no mesmo lugar (sem trocar de rota), então o
/// cartão sobe/desce suavemente e os outros se reacomodam.
///
/// - Tocar num cartão: ele sobe para o topo.
/// - Tocar em outro cartão: troca o selecionado.
/// - Tocar no selecionado, deslizar para baixo nele, ou botão voltar:
///   ele desce de volta para a pilha.
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  static const double _frontHeight = 280; // altura visível do cartão da frente
  static const double _peek = 56; // quanto cada cartão de trás "aparece"
  static const double _bleed = 40; // esconde os cantos de baixo fora da tela
  static const double _selectedHeight = 250;
  static const double _selectedTop = 28; // distância do cartão selecionado ao topo do painel branco
  static const _duration = Duration(milliseconds: 450);
  static const _curve = Curves.easeOutCubic;

  int? _selected;

  void _onCardTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _selected = _selected == i ? null : i);
  }

  void _deselect() {
    if (_selected == null) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Com um cartão aberto, "voltar" fecha o cartão em vez de sair da tela.
      canPop: _selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _deselect();
      },
      // Mesmo estilo das outras telas: topo verde com texto branco e
      // painel branco com a pilha de cartões.
      child: FinnPage(
        title: 'Meus cartões',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final n = cards.length;
            final remaining = [
              for (var i = 0; i < n; i++)
                if (i != _selected) i,
            ];
            final m = remaining.length;

            return Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < n; i++)
                  _buildCard(i, h, remaining, m, _selectedTop),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(
    int i,
    double h,
    List<int> remaining,
    int m,
    double selectedTop,
  ) {
    final isSelected = i == _selected;
    final double top;
    final double bottom;

    if (isSelected) {
      top = selectedTop;
      bottom = h - selectedTop - _selectedHeight;
    } else {
      // Os cartões que sobram se reorganizam em pilha compacta.
      final rank = remaining.indexOf(i);
      top = h - _frontHeight - (m - 1 - rank) * _peek;
      bottom = -_bleed;
    }

    return AnimatedPositioned(
      key: ValueKey(i),
      duration: _duration,
      curve: _curve,
      left: 0,
      right: 0,
      top: top,
      bottom: bottom,
      child: WalletCard(
        data: cards[i],
        expanded: isSelected,
        onTap: () => _onCardTap(i),
        onSwipeDown: isSelected ? _deselect : null,
      ),
    );
  }
}
