import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'colores.dart';
import 'nivel.dart';
import 'tablero.dart';
import 'tablero_bloc.dart';

class PantallaNiveles extends StatelessWidget {
  const PantallaNiveles({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Elige un tablero',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Son los cuatro niveles oficiales del juego',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: [
                for (final nivel in nivelesOficiales)
                  TarjetaNivel(
                    nivel: nivel,
                    alTocar: nivel.disponible
                        ? () => context
                            .read<TableroBloc>()
                            .add(NivelElegido(nivel))
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TarjetaNivel extends StatelessWidget {
  final Nivel nivel;
  final VoidCallback? alTocar;

  const TarjetaNivel({super.key, required this.nivel, this.alTocar});

  @override
  Widget build(BuildContext context) {
    final habilitado = alTocar != null;

    return Opacity(
      opacity: habilitado ? 1 : 0.45,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nivel.nombre,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: Center(
                    child: nivel.disponible
                        ? MiniaturaNivel(nivel: nivel)
                        : const Text(
                            'Falta transcribir\nla carta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  nivel.disponible
                      ? '${nivel.coloresPorZona.length} zonas'
                      : 'No disponible',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MiniaturaNivel extends StatelessWidget {
  final Nivel nivel;

  const MiniaturaNivel({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          children: [
            for (var fila = 0; fila < nivel.filas; fila++)
              Expanded(
                child: Row(
                  children: [
                    for (var columna = 0; columna < nivel.columnas; columna++)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(0.5),
                          color: nivel.zonasPorCelda[fila][columna] == hueco
                              ? colorHueco
                              : colorDe(
                                  nivel.coloresPorZona[
                                      nivel.zonasPorCelda[fila][columna]]!,
                                ),
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
