import 'package:flutter/material.dart';

import 'tipo_zona.dart';

const Color colorHueco = Color(0xFFBDBDBD);
const Color _naranja = Color(0xFFF2A444);

Color colorDe(Tipo tipo) {
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
    case Tipo.blanco:
      return const Color(0xFFE8E8E0);
    case Tipo.naranja1a3:
    case Tipo.naranja4a6:
      return _naranja;
  }
}

Color colorTextoSobre(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black87;
}
