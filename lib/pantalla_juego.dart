import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pantalla_anclas.dart';
import 'pantalla_niveles.dart';
import 'tablero_bloc.dart';
import 'vista_juego.dart';

class PantallaJuego extends StatefulWidget {
  final List<Widget> acciones;

  final Widget? tarjetaEnLinea;

  const PantallaJuego({
    super.key,
    this.acciones = const [],
    this.tarjetaEnLinea,
  });

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  bool _viendoTableros = false;

  @override
  Widget build(BuildContext context) {
    final conModos = widget.tarjetaEnLinea != null;
    final viendoTableros = _viendoTableros || !conModos;

    return BlocProvider(
      create: (_) => TableroBloc(),
      child: BlocBuilder<TableroBloc, TableroState>(
        builder: (context, estado) {
          final enSeleccion =
              estado is TableroSinIniciar && estado.nivel == null;
          final ancho = MediaQuery.sizeOf(context).width >= 600;

          final Widget? atras;
          if (!enSeleccion) {
            atras = BotonSalirTablero(estado: estado, conTexto: ancho);
          } else if (conModos && viendoTableros) {
            atras = _BotonAtras(
              clave: const Key('volver_modos'),
              texto: 'Modos',
              tooltip: 'Volver a elegir cómo jugar',
              conTexto: ancho,
              alTocar: () => setState(() => _viendoTableros = false),
            );
          } else {
            atras = null;
          }

          return Scaffold(
            appBar: AppBar(
              leadingWidth: atras == null ? null : (ancho ? 136 : 56),
              leading: atras,
              actions: widget.acciones,
            ),
            body: switch (estado) {
              TableroSinIniciar(:final nivel) =>
                nivel == null
                    ? PantallaNiveles(
                        tarjetaEnLinea: widget.tarjetaEnLinea,
                        viendoTableros: viendoTableros,
                        alElegirSolo: () =>
                            setState(() => _viendoTableros = true),
                      )
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

class _BotonAtras extends StatelessWidget {
  final Key clave;
  final String texto;
  final String tooltip;
  final bool conTexto;
  final VoidCallback alTocar;

  const _BotonAtras({
    required this.clave,
    required this.texto,
    required this.tooltip,
    required this.conTexto,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    if (!conTexto) {
      return IconButton(
        key: clave,
        tooltip: tooltip,
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: alTocar,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton.icon(
        key: clave,
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        label: Text(texto),
        onPressed: alTocar,
      ),
    );
  }
}

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
  Widget build(BuildContext context) => _BotonAtras(
    clave: const Key('salir_tablero'),
    texto: 'Tableros',
    tooltip: 'Volver a los tableros',
    conTexto: conTexto,
    alTocar: () => _salir(context),
  );
}
