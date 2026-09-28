import 'package:flutter/material.dart';

import 'tablero.dart';
import 'tipo_zona.dart';

class TableroInterfaz extends StatelessWidget {
  final Tablero tablero;
  final List<(int, int)> anclas;
  final Map<(int, int), int> numeros;
  final bool arrastrando;
  final void Function((int, int) celda, int numero) alSoltar;
  final void Function((int, int) celda) alQuitar;

  const TableroInterfaz({
    super.key,
    required this.tablero,
    required this.anclas,
    required this.numeros,
    required this.arrastrando,
    required this.alSoltar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Column(
          children: [
            for (var fila = 0; fila < tablero.tipos.length; fila++)
              Expanded(
                child: Row(
                  children: [
                    for (var columna = 0;
                        columna < tablero.tipos[fila].length;
                        columna++)
                      Expanded(
                        child: _Celda(
                          tipo: tablero.tipos[fila][columna],
                          esAncla: anclas.contains((fila, columna)),
                          numero: numeros[(fila, columna)],
                          llamando: arrastrando &&
                              anclas.contains((fila, columna)) &&
                              numeros[(fila, columna)] == null,
                          alSoltar: (n) => alSoltar((fila, columna), n),
                          alQuitar: () => alQuitar((fila, columna)),
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
  final void Function(int) alSoltar;
  final VoidCallback alQuitar;

  const _Celda({
    required this.tipo,
    required this.esAncla,
    required this.numero,
    required this.llamando,
    required this.alSoltar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorDe(tipo);
    final colorTexto =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    final celda = Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: !esAncla
          ? null
          : LayoutBuilder(
              builder: (context, r) => Stack(
                children: [
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

    if (!esAncla) return celda;

    return DragTarget<int>(
      onAcceptWithDetails: (detalles) => alSoltar(detalles.data),
      builder: (context, candidatos, _) => GestureDetector(
        onTap: numero == null ? null : alQuitar,
        child: Stack(
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
      ),
    );
  }

  Color _colorDe(Tipo tipo) {
    switch (tipo) {
      case Tipo.rojo:
        return const Color(0xFFE53935);
      case Tipo.amarillo:
        return const Color(0xFFFDD835);
      case Tipo.verde:
        return const Color(0xFF43A047);
      case Tipo.azul:
        return const Color(0xFF1E88E5);
      case Tipo.morado:
        return const Color(0xFF8E24AA);
    }
  }
}