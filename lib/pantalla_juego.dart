import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pantalla_anclas.dart';
import 'tablero_bloc.dart';
import 'vista_juego.dart';

class PantallaJuego extends StatelessWidget {
  const PantallaJuego({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TableroBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Juego Brilliant')),
        body: BlocBuilder<TableroBloc, TableroState>(
          builder: (context, estado) => switch (estado) {
            TableroSinIniciar() => const PantallaAnclas(),
            TableroEnJuego juego => VistaJuego(
                tablero: juego.tablero,
                dados: juego.dados,
                elegido: juego.elegido,
                posibles: juego.posibles,
                puedeTirar: juego.puedeTirar,
              ),
            TableroResuelto(:final tablero) =>
              VistaJuego(tablero: tablero, resuelto: true),
          },
        ),
      ),
    );
  }
}