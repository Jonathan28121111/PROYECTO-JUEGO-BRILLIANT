import 'dart:math';

import 'package:flutter/material.dart';

const Color rojoDado = Color(0xFFE53935);
const Color rojoDadoApagado = Color(0xFFF2B8B5);

/// Un dado con puntos que rueda cada vez que llega una tirada nueva.
class DadoAnimado extends StatefulWidget {
  /// El número que salió, o null si todavía no se ha tirado.
  final int? valor;

  /// Identifica la tirada: cuando cambia, el dado vuelve a rodar aunque el
  /// número sea el mismo que antes.
  final Object? tirada;

  final bool seleccionado;
  final VoidCallback? alTocar;
  final double tamano;

  const DadoAnimado({
    super.key,
    required this.valor,
    this.tirada,
    this.seleccionado = false,
    this.alTocar,
    this.tamano = 60,
  });

  @override
  State<DadoAnimado> createState() => _DadoAnimadoState();
}

class _DadoAnimadoState extends State<DadoAnimado>
    with SingleTickerProviderStateMixin {
  static const _duracion = Duration(milliseconds: 650);
  static const _cambiosDeCara = 8;

  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: _duracion,
    value: 1,
  );
  final Random _azar = Random();
  List<int> _carasDeGiro = const [];
  late double _sentido = 1;

  @override
  void didUpdateWidget(DadoAnimado viejo) {
    super.didUpdateWidget(viejo);
    if (widget.valor != null && !identical(viejo.tirada, widget.tirada)) {
      _rodar();
    }
  }

  void _rodar() {
    _carasDeGiro = [
      for (var i = 0; i < _cambiosDeCara; i++) _azar.nextInt(6) + 1,
    ];
    _sentido = _azar.nextBool() ? 1 : -1;
    _giro.forward(from: 0);
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  int? _caraVisible(double t) {
    if (t >= 1 || _carasDeGiro.isEmpty) return widget.valor;
    // Las caras cambian rápido al principio y se van frenando.
    final avance = Curves.easeOut.transform(t);
    final indice = (avance * _cambiosDeCara).floor();
    return indice >= _cambiosDeCara ? widget.valor : _carasDeGiro[indice];
  }

  @override
  Widget build(BuildContext context) {
    final vacio = widget.valor == null;

    return Semantics(
      button: widget.alTocar != null,
      selected: widget.seleccionado,
      label: vacio ? 'Dado sin tirar' : 'Dado: ${widget.valor}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: widget.alTocar == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.alTocar,
          child: AnimatedBuilder(
            animation: _giro,
            builder: (context, _) {
              final t = _giro.value;
              final frenado = 1 - Curves.easeOutCubic.transform(t);
              final angulo = _sentido * frenado * pi * 3;
              final salto = sin(t * pi) * widget.tamano * 0.28;
              final escala = 1 + sin(t * pi) * 0.12;

              return Transform.translate(
                offset: Offset(0, -salto),
                child: Transform.rotate(
                  angle: angulo,
                  child: Transform.scale(
                    scale: escala,
                    child: _Cuerpo(
                      cara: _caraVisible(t),
                      vacio: vacio,
                      seleccionado: widget.seleccionado,
                      tamano: widget.tamano,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  final int? cara;
  final bool vacio;
  final bool seleccionado;
  final double tamano;

  const _Cuerpo({
    required this.cara,
    required this.vacio,
    required this.seleccionado,
    required this.tamano,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * 0.14),
      decoration: BoxDecoration(
        gradient: vacio
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0544F), rojoDado, Color(0xFFC62828)],
              ),
        color: vacio ? rojoDadoApagado : null,
        border: Border.all(
          color: seleccionado ? const Color(0xFF1B5E20) : Colors.black,
          width: seleccionado ? 4 : 2.5,
        ),
        borderRadius: BorderRadius.circular(tamano * 0.2),
        boxShadow: vacio
            ? null
            : const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: CaraDado(valor: cara),
    );
  }
}

/// Los puntos de una cara del dado, del 1 al 6. Sin valor no dibuja nada.
class CaraDado extends StatelessWidget {
  final int? valor;
  final Color color;

  const CaraDado({super.key, required this.valor, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PintorPuntos(valor, color),
    );
  }
}

class _PintorPuntos extends CustomPainter {
  final int? valor;
  final Color color;

  _PintorPuntos(this.valor, this.color);

  // Posiciones en una rejilla de 3x3: 0 = izquierda/arriba, 2 = derecha/abajo.
  static const Map<int, List<(int, int)>> _puntos = {
    1: [(1, 1)],
    2: [(0, 0), (2, 2)],
    3: [(0, 0), (1, 1), (2, 2)],
    4: [(0, 0), (2, 0), (0, 2), (2, 2)],
    5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)],
    6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final puntos = _puntos[valor];
    if (puntos == null) return;

    final lado = size.shortestSide;
    final radio = lado * 0.11;
    final paso = (lado - radio * 2) / 2;
    final pintura = Paint()..color = color;
    final sombra = Paint()..color = const Color(0x33000000);

    for (final (columna, fila) in puntos) {
      final centro = Offset(radio + columna * paso, radio + fila * paso);
      canvas.drawCircle(centro + Offset(0, radio * 0.18), radio, sombra);
      canvas.drawCircle(centro, radio, pintura);
    }
  }

  @override
  bool shouldRepaint(_PintorPuntos viejo) =>
      viejo.valor != valor || viejo.color != color;
}
