import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pantalla_anclas.dart';
import 'pantalla_niveles.dart';
import 'tablero_bloc.dart';
import 'vista_juego.dart';

class PantallaJuego extends StatelessWidget {
  final List<Widget> acciones;
  final Widget? encabezadoNiveles;

  const PantallaJuego({
    super.key,
    this.acciones = const [],
    this.encabezadoNiveles,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TableroBloc(),
      child: BlocBuilder<TableroBloc, TableroState>(
        builder: (context, estado) {
          final enSeleccion =
              estado is TableroSinIniciar && estado.nivel == null;
          final ancho = MediaQuery.sizeOf(context).width >= 600;

          return Scaffold(
            appBar: AppBar(
              leadingWidth: enSeleccion ? null : (ancho ? 136 : 56),
              leading: enSeleccion
                  ? null
                  : BotonSalirTablero(estado: estado, conTexto: ancho),
              title: const Text('Juego Brilliant'),
              actions: acciones,
            ),
            body: switch (estado) {
              TableroSinIniciar(:final nivel) =>
                nivel == null
                    ? PantallaNiveles(encabezado: encabezadoNiveles)
                    : PantallaAnclas(nivel: nivel),
              TableroEnJuego juego => VistaJuego(
                tablero: juego.tablero,
                dados: juego.dados,
                elegido: juego.elegido,
                posibles: juego.posibles,
                puedeTirar: juego.puedeTirar,
                nivel: juego.nivel,
              ),
              TableroResuelto(:final tablero, :final nivel) => VistaJuego(
                tablero: tablero,
                resuelto: true,
                nivel: nivel,
              ),
            },
          );
        },
      ),
    );
  }
}

/// Vuelve a la selección de tableros. Si hay una partida a medias, antes
/// pregunta, porque lo que lleva el tablero se pierde.
class BotonSalirTablero extends StatelessWidget {
  final TableroState estado;
  final bool conTexto;

  const BotonSalirTablero({
    super.key,
    required this.estado,
    required this.conTexto,
  });

  Future<void> _salir(BuildContext context) async {
    final bloc = context.read<TableroBloc>();
    if (estado case TableroEnJuego(:final nivel)) {
      final salir = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: Text('¿Salir del ${nivel.nombre}?'),
          content: const Text(
            'Se pierde lo que llevas en este tablero. Puedes volver a '
            'empezarlo cuando quieras.',
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(contexto, false),
              child: const Text('Seguir jugando'),
            ),
            FilledButton(
              key: const Key('confirmar_salir_tablero'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.pop(contexto, true),
              child: const Text('Salir del tablero'),
            ),
          ],
        ),
      );
      if (salir != true) return;
    }
    bloc.add(VolverAlInicio());
  }

  @override
  Widget build(BuildContext context) {
    if (!conTexto) {
      return IconButton(
        key: const Key('salir_tablero'),
        tooltip: 'Volver a los tableros',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => _salir(context),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton.icon(
        key: const Key('salir_tablero'),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        label: const Text('Tableros'),
        onPressed: () => _salir(context),
      ),
    );
  }
}
