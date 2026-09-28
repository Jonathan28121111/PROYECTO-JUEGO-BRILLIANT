import 'package:flutter/material.dart';

import 'tablero.dart';
import 'tipo_zona.dart';

class TableroInterfaz extends StatelessWidget {
  final Tablero tablero;
  final List<List<int>> anclas;

  const TableroInterfaz({
    super.key,
    required this.tablero,
    required this.anclas,
  });

  bool _esAncla(int fila, int columna) {
    return anclas.any((a) => a[0] == fila && a[1] == columna);
  }

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
                          esAncla: _esAncla(fila, columna),
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

  const _Celda({required this.tipo, required this.esAncla});

  @override
  Widget build(BuildContext context) {
    final color = _colorDe(tipo);
    final colorEstrella =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: !esAncla
          ? null
          : LayoutBuilder(
              builder: (context, restricciones) => Padding(
                padding: EdgeInsets.all(restricciones.maxWidth * 0.06),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Icon(
                    Icons.star,
                    size: restricciones.maxWidth * 0.28,
                    color: colorEstrella,
                  ),
                ),
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