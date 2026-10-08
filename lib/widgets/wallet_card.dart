import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Cartão com feedback de toque, gesto de "deslizar para baixo" e dados.
/// O cabeçalho (banco + bandeira) fica sempre visível, inclusive na pilha;
/// os detalhes aparecem só quando o cartão está expandido (selecionado).
class WalletCard extends StatefulWidget {
  final CardData data;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onSwipeDown;

  const WalletCard({
    super.key,
    required this.data,
    required this.expanded,
    required this.onTap,
    this.onSwipeDown,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    // Texto escuro sobre cartão claro (amarelo), branco nos demais.
    final fg = d.color.computeLuminance() > 0.5 ? FinnTheme.black : FinnTheme.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 250) widget.onSwipeDown?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: d.color,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(45, 0, 0, 0),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho: sempre visível (aparece na "espiada" da pilha).
                SizedBox(
                  height: 24,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.bank,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        d.brand,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Detalhes: só aparecem com o cartão selecionado.
                Expanded(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: widget.expanded ? 1 : 0,
                      duration: Duration(milliseconds: widget.expanded ? 350 : 150),
                      curve: Curves.easeIn,
                      child: _Details(data: d, fg: fg),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final CardData data;
  final Color fg;
  const _Details({required this.data, required this.fg});

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView (sem rolagem) evita o erro de overflow de poucos
    // pixels causado por diferenças de altura de fonte entre plataformas.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.contactless_outlined,
                  color: fg.withOpacity(0.8), size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.maskedNumber,
            style: TextStyle(
              color: fg,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Field('Titular', data.holder, fg)),
              _Field('Validade', data.expiry, fg),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Field(
                    'Limite disponível', formatBRL(data.availableLimit), fg),
              ),
              _Field('Fatura atual', formatBRL(data.invoice), fg),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  const _Field(this.label, this.value, this.fg);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: fg.withOpacity(0.7), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
