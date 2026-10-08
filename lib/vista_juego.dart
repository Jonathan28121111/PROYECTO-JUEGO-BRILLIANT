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
  final bool resuelto;

  const VistaJuego({
    super.key,
    required this.tablero,
    this.dados,
    this.resuelto = false,
  });

  @override
  Widget build(BuildContext context) {
    final numeros = <(int, int), int>{};
    for (var fila = 0; fila < tablero.valores.length; fila++) {
      for (var columna = 0; columna < tablero.valores[fila].length; columna++) {
        final valor = tablero.valores[fila][columna];
        if (valor != null) {
          numeros[(fila, columna)] = valor;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(
                  width: 150,
                  child: PanelReglas(reglas: reglasIzquierda),
                ),
                Expanded(
                  child: Center(
                    child: TableroInterfaz(
                      tablero: tablero,
                      anclas: Tablero.anclasNivel1,
                      numeros: numeros,
                      arrastrando: false,
                      alSoltar: (_, __) {},
                      alQuitar: (_) {},
                    ),
                  ),
                ),
                const SizedBox(
                  width: 150,
                  child: PanelReglas(reglas: reglasDerecha),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dado(valor: dados?.primero),
              const SizedBox(width: 12),
              _Dado(valor: dados?.segundo),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: resuelto
                ? null
                : () => context.read<TableroBloc>().add(DadosTirados()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
          const SizedBox(height: 10),
          Text(
            resuelto ? '¡Tablero resuelto!' : 'Partida en curso',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Dado extends StatelessWidget {
  final int? valor;

  const _Dado({required this.valor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: valor == null ? Colors.grey.shade200 : Colors.white,
        border: Border.all(color: Colors.black, width: 2.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        valor == null ? '–' : '$valor',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: valor == null ? Colors.black26 : Colors.black,
        ),
      ),
    );
  }
}