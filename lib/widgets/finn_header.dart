import 'package:flutter/material.dart';
import '../theme.dart';

/// Logo "Finn" recortada (a imagem é quadrada, com bastante margem).
class FinnLogo extends StatelessWidget {
  final double width;
  const FinnLogo({super.key, this.width = 120});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: const Alignment(0, -0.06),
        widthFactor: 0.78,
        heightFactor: 0.34,
        child: Image.asset('assets/imgs/logo.png', width: width, height: width),
      ),
    );
  }
}

/// Cabeçalho das telas internas: seta de voltar + título (sem logo).
class FinnBackHeader extends StatelessWidget {
  final String title;
  const FinnBackHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: FinnTheme.white),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FinnTheme.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
