import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() => runApp(const FinnApp());

class FinnApp extends StatelessWidget {
  const FinnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: FinnTheme.mainBlue),
        scaffoldBackgroundColor: FinnTheme.white,
      ),
      // Barra de status (hora, bateria, sinal) com ícones brancos, pois todas as
      // telas têm o topo em azul escuro.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // Android
          statusBarBrightness: Brightness.dark, // iOS
        ),
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
