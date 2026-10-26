import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pantalla_anclas.dart';
import 'pantalla_niveles.dart';
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
            TableroSinIniciar(:final nivel) => nivel == null
                ? const PantallaNiveles()
                : PantallaAnclas(nivel: nivel),
            TableroEnJuego juego => VistaJuego(
                tablero: juego.tablero,
                dados: juego.dados,
                elegido: juego.elegido,
                posibles: juego.posibles,
                puedeTirar: juego.puedeTirar,
                nivel: juego.nivel,
              ),
            TableroResuelto(:final tablero, :final nivel) =>
              VistaJuego(tablero: tablero, resuelto: true, nivel: nivel),
          },
        ),
      ),
    );
  }
}