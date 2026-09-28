import 'package:flutter/material.dart';

import 'tablero.dart';
import 'tablero_interfaz.dart';

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
      home: const PantallaTablero(),
    );
  }
}

class PantallaTablero extends StatelessWidget {
  const PantallaTablero({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juego Brilliant')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
            child: TableroInterfaz(
            tablero: Tablero.nivel1Inicial(),
            anclas: Tablero.anclasNivel1,
          ),
        ),
      ),
    );
  }
}