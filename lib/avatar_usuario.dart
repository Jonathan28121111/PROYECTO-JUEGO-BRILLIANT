import 'package:flutter/material.dart';

const Color azulAvatar = Color(0xFF26A9E0);

/// Círculo de color con la silueta de una persona en línea blanca.
class AvatarUsuario extends StatelessWidget {
  final double tamano;
  final Color color;

  const AvatarUsuario({super.key, this.tamano = 40, this.color = azulAvatar});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: tamano,
      child: CustomPaint(painter: _PintorAvatar(color)),
    );
  }
}

class _PintorAvatar extends CustomPainter {
  final Color color;

  _PintorAvatar(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.shortestSide;
    final centro = Offset(size.width / 2, size.height / 2);
    final fondo = Paint()..color = color;
    final linea = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = lado * 0.036;

    canvas.drawCircle(centro, lado / 2, fondo);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centro, radius: lado / 2)),
    );

    // Hombros: un rectángulo redondeado que se corta con el borde del círculo.
    final izquierda = lado * 0.18;
    final derecha = lado * 0.82;
    final arriba = lado * 0.585;
    final radio = lado * 0.105;
    final cuerpo = Path()
      ..moveTo(izquierda, lado * 1.1)
      ..lineTo(izquierda, arriba + radio)
      ..arcToPoint(
        Offset(izquierda + radio, arriba),
        radius: Radius.circular(radio),
      )
      ..lineTo(derecha - radio, arriba)
      ..arcToPoint(
        Offset(derecha, arriba + radio),
        radius: Radius.circular(radio),
      )
      ..lineTo(derecha, lado * 1.1);
    canvas.drawPath(cuerpo, linea);

    // Cabeza: se borra la línea de los hombros detrás para dejar el hueco.
    final cabeza = Offset(lado / 2, lado * 0.36);
    final radioCabeza = lado * 0.2;
    canvas.drawCircle(cabeza, radioCabeza + lado * 0.04, fondo);
    canvas.drawCircle(cabeza, radioCabeza, linea);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorAvatar viejo) => viejo.color != color;
}
