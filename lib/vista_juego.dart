import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dados.dart';
import 'panel_reglas.dart';
import 'tablero.dart';
import 'tablero_bloc.dart';
import 'tablero_interfaz.dart';

class VistaJuego extends StatelessWidget {
  final Tablero tablero;
  final Dados? dados;
  final int? elegido;
  final List<(int, int)> posibles;
  final bool resuelto;

  const VistaJuego({
    super.key,
    required this.tablero,
    this.dados,
    this.elegido,
    this.posibles = const [],
    this.resuelto = false,
  });

  String get _instruccion {
    if (resuelto) return '¡Tablero resuelto!';
    if (dados == null) return 'Tirá los dados para jugar';
    if (elegido == null) return 'Elegí cuál de los dos números vas a escribir';
    if (posibles.isEmpty) {
      return 'Con ese número no hay jugada: probá con el otro';
    }
    return 'Tocá una casilla resaltada';
  }

  @override
  Widget build(BuildContext context) {
    final tirada = dados;

    final numeros = <(int, int), int>{};
    for (var fila = 0; fila < tablero.valores.length; fila++) {
      for (var columna = 0; columna < tablero.valores[fila].length; columna++) {
        final valor = tablero.valores[fila][columna];
        if (valor != null) {
          numeros[(fila, columna)] = valor;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final altoTablero =
            (restricciones.maxHeight - 200).clamp(220.0, 600.0).toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: altoTablero,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 140,
                      child: PanelReglas(reglas: reglasIzquierda),
                    ),
                    Expanded(
                      child: Center(
                        child: TableroInterfaz(
                          tablero: tablero,
                          anclas: Tablero.anclasNivel1,
                          numeros: numeros,
                          arrastrando: false,
                          posibles: posibles,
                          alSoltar: (_, __) {},
                          alQuitar: (_) {},
                          alTocar: (celda) => context
                              .read<TableroBloc>()
                              .add(NumeroColocado(celda.$1, celda.$2)),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 140,
                      child: PanelReglas(reglas: reglasDerecha),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dado(
                    valor: tirada?.primero,
                    seleccionado: tirada != null && elegido == tirada.primero,
                    alTocar: tirada == null
                        ? null
                        : () => context
                            .read<TableroBloc>()
                            .add(NumeroElegido(tirada.primero)),
                  ),
                  const SizedBox(width: 12),
                  _Dado(
                    valor: tirada?.segundo,
                    seleccionado: tirada != null && elegido == tirada.segundo,
                    alTocar: tirada == null
                        ? null
                        : () => context
                            .read<TableroBloc>()
                            .add(NumeroElegido(tirada.segundo)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: resuelto
                    ? null
                    : () => context.read<TableroBloc>().add(DadosTirados()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: const Text(
                  'Tirar los dados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _instruccion,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Dado extends StatelessWidget {
  final int? valor;
  final bool seleccionado;
  final VoidCallback? alTocar;

  const _Dado({
    required this.valor,
    this.seleccionado = false,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              valor == null ? const Color(0xFFF2B8B5) : const Color(0xFFE53935),
          border: Border.all(
            color: seleccionado ? const Color(0xFF1B5E20) : Colors.black,
            width: seleccionado ? 5 : 2.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          valor == null ? '–' : '$valor',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: valor == null ? Colors.black26 : Colors.white,
          ),
        ),
      ),
    );
  }
}