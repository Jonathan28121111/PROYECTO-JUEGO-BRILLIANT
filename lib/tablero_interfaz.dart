import 'package:flutter/material.dart';

import 'colores.dart';
import 'tablero.dart';
import 'tipo_zona.dart';

class MarcaZona {
  final String usuario;
  final Color color;

  const MarcaZona(this.usuario, this.color);

  String get letra => usuario.isEmpty ? '?' : usuario[0].toUpperCase();
}

class TableroInterfaz extends StatelessWidget {
  final Tablero tablero;
  final List<(int, int)> anclas;
  final Map<(int, int), int> numeros;
  final bool arrastrando;
  final List<(int, int)> posibles;
  final void Function((int, int) celda, int numero) alSoltar;
  final void Function((int, int) celda) alQuitar;
  final void Function((int, int) celda)? alTocar;

  final bool Function((int, int) celda, int numero)? aceptaFicha;

  final Map<(int, int), List<MarcaZona>> marcas;

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
    this.aceptaFicha,
    this.marcas = const {},
  });

  @override
  Widget build(BuildContext context) {
    final tocar = alTocar;
    final acepta = aceptaFicha;

    final anclas = this.anclas.toSet();
    final posibles = this.posibles.toSet();

    return RepaintBoundary(
      child: AspectRatio(
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
                      for (
                        var columna = 0;
                        columna < tablero.zonasPorCelda[fila].length;
                        columna++
                      )
                        Expanded(
                          child: _Celda(
                            tipo: tablero.esHueco(fila, columna)
                                ? null
                                : tablero.tipoDe(fila, columna),
                            esAncla: anclas.contains((fila, columna)),
                            numero: numeros[(fila, columna)],
                            llamando:
                                arrastrando &&
                                anclas.contains((fila, columna)) &&
                                numeros[(fila, columna)] == null,
                            esPosible: posibles.contains((fila, columna)),
                            marcas: marcas[(fila, columna)] ?? const [],
                            alSoltar: (n) => alSoltar((fila, columna), n),
                            alQuitar: () => alQuitar((fila, columna)),
                            alTocar: tocar == null
                                ? null
                                : () => tocar((fila, columna)),
                            aceptaFicha: acepta == null
                                ? null
                                : (n) => acepta((fila, columna), n),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  final Tipo? tipo;
  final bool esAncla;
  final int? numero;
  final bool llamando;
  final bool esPosible;
  final void Function(int) alSoltar;
  final VoidCallback alQuitar;
  final VoidCallback? alTocar;
  final bool Function(int)? aceptaFicha;
  final List<MarcaZona> marcas;

  const _Celda({
    required this.tipo,
    required this.esAncla,
    required this.numero,
    required this.llamando,
    required this.esPosible,
    required this.alSoltar,
    required this.alQuitar,
    required this.alTocar,
    this.aceptaFicha,
    this.marcas = const [],
  });

  @override
  Widget build(BuildContext context) {
    final zona = tipo;
    if (zona == null) {
      return Container(
        decoration: BoxDecoration(
          color: colorHueco,
          border: Border.all(color: Colors.black26, width: 1),
        ),
      );
    }

    final color = colorDe(zona);
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
            if (marcas.isNotEmpty)
              Positioned(
                top: r.maxWidth * 0.04,
                right: r.maxWidth * 0.04,
                left: r.maxWidth * 0.04,
                child: Wrap(
                  key: const Key('marcas_zona'),
                  alignment: WrapAlignment.end,
                  spacing: 1,
                  runSpacing: 1,
                  children: [
                    for (final marca in marcas)
                      Tooltip(
                        message: 'Completada por ${marca.usuario}',
                        child: Container(
                          width: r.maxWidth * 0.28,
                          height: r.maxWidth * 0.28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: marca.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            marca.letra,
                            style: TextStyle(
                              fontSize: r.maxWidth * 0.17,
                              height: 1,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
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
        onWillAcceptWithDetails: (detalles) =>
            aceptaFicha?.call(detalles.data) ?? true,
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

    final tocar = esPosible
        ? alTocar
        : (numero != null && esAncla ? alQuitar : null);
    if (tocar == null) {
      return contenido;
    }

    return GestureDetector(onTap: tocar, child: contenido);
  }
}
