import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'colores.dart';
import 'nivel.dart';
import 'tablero.dart';
import 'tablero_bloc.dart';

const Color _texto = Color(0xFF111827);
const Color _secundario = Color(0xFF6B7280);
const Color _borde = Color(0xFFE5E7EB);

class PantallaNiveles extends StatelessWidget {
  final Widget? tarjetaEnLinea;

  final bool viendoTableros;
  final VoidCallback? alElegirSolo;

  const PantallaNiveles({
    super.key,
    this.tarjetaEnLinea,
    this.viendoTableros = true,
    this.alElegirSolo,
  });

  @override
  Widget build(BuildContext context) {
    final enLinea = tarjetaEnLinea;
    final elegirModo = enLinea != null && !viendoTableros;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: elegirModo ? 880 : 1040),
          child: elegirModo
              ? _SelectorModo(enLinea: enLinea, alElegirSolo: alElegirSolo)
              : const _SelectorTablero(),
        ),
      ),
    );
  }
}

class _SelectorModo extends StatelessWidget {
  final Widget enLinea;
  final VoidCallback? alElegirSolo;

  const _SelectorModo({required this.enLinea, required this.alElegirSolo});

  @override
  Widget build(BuildContext context) {
    final solo = TarjetaModo(
      key: const Key('modo_solo'),
      ilustracion: const SizedBox(
        width: 96,
        child: MiniaturaNivel(nivel: nivel1),
      ),
      titulo: 'Jugar solo',
      descripcion:
          'Elige uno de los cuatro tableros oficiales y juega a tu '
          'ritmo.',
      accion: 'Elegir tablero',
      alTocar: alElegirSolo,
      destacada: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          'Juega solo o reta a otra persona en línea.',
          style: TextStyle(fontSize: 16, height: 1.5, color: _secundario),
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, espacio) => espacio.maxWidth < 640
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [solo, const SizedBox(height: 16), enLinea],
                )
              : _Estirar(
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: solo),
                        const SizedBox(width: 24),
                        Expanded(child: enLinea),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Estirar extends InheritedWidget {
  const _Estirar({required super.child});

  @override
  bool updateShouldNotify(_Estirar viejo) => false;
}

class TarjetaModo extends StatelessWidget {
  final Widget ilustracion;
  final String titulo;
  final String descripcion;
  final String accion;
  final IconData iconoAccion;
  final VoidCallback? alTocar;

  final bool destacada;
  final Key? claveBoton;

  const TarjetaModo({
    super.key,
    required this.ilustracion,
    required this.titulo,
    required this.descripcion,
    required this.accion,
    required this.alTocar,
    this.iconoAccion = Icons.arrow_forward_rounded,
    this.destacada = true,
    this.claveBoton,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final estirar =
        context.dependOnInheritedWidgetOfExactType<_Estirar>() != null;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _borde),
    );
    final etiqueta = Text(accion);
    final icono = Icon(iconoAccion, size: 20);
    final boton = destacada
        ? FilledButton.icon(
            key: claveBoton,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: alTocar,
            icon: icono,
            label: etiqueta,
          )
        : FilledButton.tonalIcon(
            key: claveBoton,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: alTocar,
            icon: icono,
            label: etiqueta,
          );

    return Material(
      color: Colors.white,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        customBorder: forma,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 144,
              color: colores.primaryContainer.withValues(alpha: 0.4),
              alignment: Alignment.center,
              child: ilustracion,
            ),
            Expanded(
              flex: estirar ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: _texto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _secundario,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (estirar) const Spacer(),
                    boton,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTablero extends StatelessWidget {
  const _SelectorTablero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elige un tablero',
          style: TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Son los cuatro niveles oficiales del juego',
          style: TextStyle(fontSize: 16, height: 1.5, color: _secundario),
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, espacio) {
            final angosto = espacio.maxWidth < 520;
            final separacion = angosto ? 12.0 : 24.0;
            final ancho = angosto ? (espacio.maxWidth - separacion) / 2 : 232.0;
            return Wrap(
              spacing: separacion,
              runSpacing: separacion,
              children: [
                for (final nivel in nivelesOficiales)
                  TarjetaNivel(
                    nivel: nivel,
                    ancho: ancho,
                    alTocar: nivel.disponible
                        ? () => context.read<TableroBloc>().add(
                            NivelElegido(nivel),
                          )
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class TarjetaNivel extends StatelessWidget {
  final Nivel nivel;
  final VoidCallback? alTocar;
  final double ancho;

  const TarjetaNivel({
    super.key,
    required this.nivel,
    this.alTocar,
    this.ancho = 232,
  });

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
        width: ancho,
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
                    height: ancho - 32,
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
                          nivel.disponible ? '' : 'No disponible',
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
      child: RepaintBoundary(
        child: CustomPaint(painter: _PintorMiniatura(nivel)),
      ),
    );
  }
}

class _PintorMiniatura extends CustomPainter {
  final Nivel nivel;

  _PintorMiniatura(this.nivel);

  @override
  void paint(Canvas canvas, Size size) {
    final marco = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.save();
    canvas.clipRRect(marco);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final ancho = size.width / nivel.columnas;
    final alto = size.height / nivel.filas;
    final pintura = Paint();
    for (var fila = 0; fila < nivel.filas; fila++) {
      for (var columna = 0; columna < nivel.columnas; columna++) {
        final zona = nivel.zonasPorCelda[fila][columna];
        pintura.color = zona == hueco
            ? colorHueco
            : colorDe(nivel.coloresPorZona[zona]!);
        canvas.drawRect(
          Rect.fromLTWH(
            columna * ancho + 0.5,
            fila * alto + 0.5,
            ancho - 1,
            alto - 1,
          ),
          pintura,
        );
      }
    }
    canvas.restore();
    canvas.drawRRect(
      marco.deflate(0.75),
      Paint()
        ..color = const Color(0xFF374151)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PintorMiniatura viejo) => viejo.nivel != nivel;
}
