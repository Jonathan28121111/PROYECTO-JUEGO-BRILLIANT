import 'package:flutter/material.dart';

import 'colores.dart';
import 'tablero.dart';
import 'tipo_zona.dart';

class TableroInterfaz extends StatelessWidget {
  final Tablero tablero;
  final List<(int, int)> anclas;
  final Map<(int, int), int> numeros;
  final bool arrastrando;
  final List<(int, int)> posibles;
  final void Function((int, int) celda, int numero) alSoltar;
  final void Function((int, int) celda) alQuitar;
  final void Function((int, int) celda)? alTocar;

  const TableroInterfaz({
    super.key,
    required this.tablero,
    required this.anclas,
    required this.numeros,
    required this.arrastrando,
    required this.alSoltar,
    required this.alQuitar,
    this.posibles = const [],
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final tocar = alTocar;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Column(
          children: [
            for (var fila = 0; fila < tablero.zonasPorCelda.length; fila++)
              Expanded(
                child: Row(
                  children: [
                    for (var columna = 0;
                        columna < tablero.zonasPorCelda[fila].length;
                        columna++)
                      Expanded(
                        child: _Celda(
                          tipo: tablero.tipoDe(fila, columna),
                          esAncla: anclas.contains((fila, columna)),
                          numero: numeros[(fila, columna)],
                          llamando: arrastrando &&
                              anclas.contains((fila, columna)) &&
                              numeros[(fila, columna)] == null,
                          esPosible: posibles.contains((fila, columna)),
                          alSoltar: (n) => alSoltar((fila, columna), n),
                          alQuitar: () => alQuitar((fila, columna)),
                          alTocar:
                              tocar == null ? null : () => tocar((fila, columna)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  final Tipo tipo;
  final bool esAncla;
  final int? numero;
  final bool llamando;
  final bool esPosible;
  final void Function(int) alSoltar;
  final VoidCallback alQuitar;
  final VoidCallback? alTocar;

  const _Celda({
    required this.tipo,
    required this.esAncla,
    required this.numero,
    required this.llamando,
    required this.esPosible,
    required this.alSoltar,
    required this.alQuitar,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorDe(tipo);
    final colorTexto = colorTextoSobre(color);

    final celda = Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, r) => Stack(
          children: [
            if (esAncla)
              Padding(
                padding: EdgeInsets.all(r.maxWidth * 0.06),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: AnimatedScale(
                    scale: llamando ? 1.6 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.star,
                      size: r.maxWidth * 0.28,
                      color: colorTexto,
                    ),
                  ),
                ),
              ),
            if (numero != null)
              Center(
                child: Text(
                  '$numero',
                  style: TextStyle(
                    fontSize: r.maxWidth * 0.5,
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    Widget contenido = celda;

    if (esAncla) {
      contenido = DragTarget<int>(
        onAcceptWithDetails: (detalles) => alSoltar(detalles.data),
        builder: (context, candidatos, _) => Stack(
          fit: StackFit.expand,
          children: [
            celda,
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: candidatos.isNotEmpty
                    ? 0.45
                    : llamando
                        ? 0.15
                        : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (esPosible) {
      contenido = Stack(
        fit: StackFit.expand,
        children: [
          contenido,
          IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorTexto.withAlpha(40),
                border: Border.all(color: colorTexto, width: 3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      );
    }

    final tocar =
        esPosible ? alTocar : (numero != null && esAncla ? alQuitar : null);
    if (tocar == null) {
      return contenido;
    }

    return GestureDetector(onTap: tocar, child: contenido);
  }
}