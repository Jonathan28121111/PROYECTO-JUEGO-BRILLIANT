import 'package:flutter/material.dart';

import 'pantalla_juego.dart';

void main() {
  runApp(const JuegoBrilliantApp());
}

class JuegoBrilliantApp extends StatelessWidget {
  const JuegoBrilliantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juego Brilliant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const PantallaJuego(),
    );
  }
}