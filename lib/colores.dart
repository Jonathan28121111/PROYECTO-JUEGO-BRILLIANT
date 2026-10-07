import 'package:flutter/material.dart';

import 'tipo_zona.dart';

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
  }
}

Color colorTextoSobre(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black87;
}