import 'package:flutter/material.dart';

import 'panel_reglas.dart';
import 'tablero.dart';
import 'tablero_interfaz.dart';

class VistaJuego extends StatelessWidget {
  final Tablero tablero;
  final bool resuelto;

  const VistaJuego({
    super.key,
    required this.tablero,
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
          Text(
            resuelto ? '¡Tablero resuelto!' : 'Partida en curso',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Los dados llegan en el siguiente paso.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}