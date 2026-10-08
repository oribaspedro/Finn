import 'package:flutter/material.dart';

class FinnTheme {
  // Obs.: no arquivo original o alpha era 0 (transparente). Corrigido para 255.
  static const Color black = Color.fromARGB(255, 20, 20, 20);
  static const Color mainBlue = Color(0xff0f2238);
  static const Color secondaryBlue = Color(0xff091727);
  /// Verde de "ganho/entrada" (alta, resultado positivo), independente do tema.
  static const Color gain = Color(0xff04ca88);
  static const Color white = Color(0xffffffff);
  static const Color red = Color(0xffff5757);
  static const Color yellow = Color(0xfffff856);
  static const Color blue = Color(0xff3b71ea);
  static const Color pink = Color(0xffff2f93);
  static const Color lightGray = Color(0xffd6d6d6);

  /// Fonte serifada usada nos valores (troque por uma fonte do projeto, ex.: Lora).
  static const List<String> serifFallback = ['Georgia', 'Times New Roman', 'serif'];
}
