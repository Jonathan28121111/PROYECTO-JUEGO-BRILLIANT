import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dado_animado.dart';
import 'dados.dart';
import 'nivel.dart';
import 'panel_reglas.dart';
import 'tablero.dart';
import 'tablero_bloc.dart';
import 'tablero_interfaz.dart';

class VistaJuego extends StatelessWidget {
  final Tablero tablero;
  final Dados? dados;
  final int? elegido;
  final List<(int, int)> posibles;
  final bool puedeTirar;
  final bool resuelto;
  final Nivel nivel;

  const VistaJuego({
    super.key,
    required this.tablero,
    this.dados,
    this.elegido,
    this.posibles = const [],
    this.puedeTirar = true,
    this.resuelto = false,
    this.nivel = nivel1,
  });

  String get _instruccion {
    if (resuelto) return '¡Tablero resuelto!';
    if (dados == null) return 'Tira los dados para jugar';
    if (puedeTirar) return 'No hay ninguna jugada: vuelve a tirar';
    if (elegido == null) return 'Elige cuál de los dos números vas a escribir';
    if (posibles.isEmpty) {
      return 'Con ese número no hay jugada: prueba con el otro';
    }
    return 'Toca una casilla resaltada';
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
            (restricciones.maxHeight - 250).clamp(220.0, 600.0).toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: altoTablero,
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: PanelReglas(
                    reglas: reglasDe(nivel).$1,
                    puntos: nivel.puntos,
                  ),
                    ),
                    Expanded(
                      child: Center(
                        child: TableroInterfaz(
                          tablero: tablero,
                          anclas: nivel.anclas,
                          numeros: numeros,
                          arrastrando: false,
                          posibles: posibles,
                          alSoltar: (_, _) {},
                          alQuitar: (_) {},
                          alTocar: (celda) => context
                              .read<TableroBloc>()
                              .add(NumeroColocado(celda.$1, celda.$2)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: PanelReglas(
                    reglas: reglasDe(nivel).$2,
                    puntos: nivel.puntos,
                  ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Marcador(puntos: tablero.puntos),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DadoAnimado(
                    key: const Key('dado_1'),
                    valor: tirada?.primero,
                    tirada: tirada,
                    seleccionado: tirada != null && elegido == tirada.primero,
                    alTocar: tirada == null
                        ? null
                        : () => context
                            .read<TableroBloc>()
                            .add(NumeroElegido(tirada.primero)),
                  ),
                  const SizedBox(width: 18),
                  DadoAnimado(
                    key: const Key('dado_2'),
                    valor: tirada?.segundo,
                    tirada: tirada,
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
                onPressed: (resuelto || !puedeTirar)
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

class _Marcador extends StatelessWidget {
  final int puntos;

  const _Marcador({required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$puntos',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            puntos == 1 ? 'punto' : 'puntos',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
