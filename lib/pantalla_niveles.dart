import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'colores.dart';
import 'nivel.dart';
import 'tablero.dart';
import 'tablero_bloc.dart';

const Color _texto = Color(0xFF111827);
const Color _secundario = Color(0xFF6B7280);
const Color _borde = Color(0xFFE5E7EB);

/// La portada: cómo jugar y qué tablero. Patrón Dashboard / Overview: un
/// título, una frase y a lo más cinco tarjetas que llevan a otra pantalla.
class PantallaNiveles extends StatelessWidget {
  /// La invitación a jugar en línea, que va antes de los tableros.
  final Widget? encabezado;

  const PantallaNiveles({super.key, this.encabezado});

  @override
  Widget build(BuildContext context) {
    final arriba = encabezado;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (arriba != null) ...[
                const Text(
                  '¿Cómo quieres jugar?',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: _texto,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Juega solo en uno de los tableros oficiales, o en línea '
                  'contra otra persona.',
                  style: TextStyle(fontSize: 16, height: 1.5, color: _secundario),
                ),
                const SizedBox(height: 24),
                arriba,
                const SizedBox(height: 48),
              ],
              const Text(
                'Elige un tablero',
                style: TextStyle(
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: _texto,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Son los cuatro niveles oficiales del juego',
                style: TextStyle(fontSize: 14, height: 1.5, color: _secundario),
              ),
              const SizedBox(height: 16),
              Wrap(
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
    final primario = Theme.of(context).colorScheme.primary;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _borde),
    );

    return Opacity(
      opacity: habilitado ? 1 : 0.5,
      child: SizedBox(
        width: 232,
        child: Material(
          color: Colors.white,
          shape: forma,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            customBorder: forma,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: nivel.disponible
                          ? MiniaturaNivel(nivel: nivel)
                          : const Text(
                              'Falta transcribir\nla carta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: _secundario,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nivel.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: _texto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nivel.disponible
                              ? '${nivel.coloresPorZona.length} zonas'
                              : 'No disponible',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: _secundario,
                          ),
                        ),
                      ),
                      if (habilitado) ...[
                        Text(
                          'Jugar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primario,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: primario,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
          border: Border.all(color: const Color(0xFF374151), width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
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
