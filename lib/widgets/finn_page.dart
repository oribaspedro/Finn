import 'package:flutter/material.dart';
import '../theme.dart';
import 'finn_header.dart';

/// Moldura das telas internas: cabeçalho verde (seta + título, sem logo) e
/// painel branco arredondado com o conteúdo.
class FinnPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? headerExtra;

  const FinnPage({
    super.key,
    required this.title,
    required this.child,
    this.headerExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinnTheme.mainBlue,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, headerExtra == null ? 20 : 28),
              child: Column(
                children: [
                  FinnBackHeader(title: title),
                  if (headerExtra != null) ...[
                    const SizedBox(height: 16),
                    headerExtra!,
                  ],
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
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: FinnTheme.secondaryBlue,
          foregroundColor: FinnTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

InputDecoration finnInput(String label, {String? hint, IconData? icon}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, color: FinnTheme.secondaryBlue),
    filled: true,
    fillColor: const Color(0xfff5f5f5),
    floatingLabelStyle: const TextStyle(color: FinnTheme.secondaryBlue),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    focusedBorder: border(FinnTheme.secondaryBlue, 1.5),
    errorBorder: border(FinnTheme.red),
    focusedErrorBorder: border(FinnTheme.red, 1.5),
  );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: FinnTheme.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
}
