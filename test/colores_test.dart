import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/colores.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

void main() {
  group('colorDe', () {
    test('los dos naranjas comparten color y se distinguen por el simbolo', () {
      expect(colorDe(Tipo.naranja1a3), colorDe(Tipo.naranja4a6));
    });

    test('los demas tipos no repiten color', () {
      final otros = Tipo.values.where((t) => t != Tipo.naranja4a6);
      expect(otros.map(colorDe).toSet(), hasLength(otros.length));
    });

    test('ningun color es transparente', () {
      for (final tipo in Tipo.values) {
        expect(colorDe(tipo), isNot(Colors.transparent), reason: '$tipo');
      }
    });

    test('el mismo tipo siempre da el mismo color', () {
      expect(colorDe(Tipo.rojo), colorDe(Tipo.rojo));
      expect(colorDe(Tipo.rojo), const Color(0xFFE53935));
    });
  });

  group('colorTextoSobre', () {
    test('sobre un fondo oscuro escribe en blanco', () {
      expect(colorTextoSobre(Colors.black), Colors.white);
      expect(colorTextoSobre(const Color(0xFF1B5E20)), Colors.white);
    });

    test('sobre un fondo claro escribe en negro', () {
      expect(colorTextoSobre(Colors.white), Colors.black87);
      expect(colorTextoSobre(colorDe(Tipo.amarillo)), Colors.black87);
      expect(colorTextoSobre(colorDe(Tipo.blanco)), Colors.black87);
    });

    test('para cualquier color del juego devuelve uno de los dos', () {
      for (final tipo in Tipo.values) {
        expect(
          colorTextoSobre(colorDe(tipo)),
          anyOf(Colors.white, Colors.black87),
          reason: '$tipo',
        );
      }
    });

    test('para cualquier color posible devuelve uno de los dos', () {
      for (var rojo = 0; rojo < 256; rojo += 51) {
        for (var verde = 0; verde < 256; verde += 51) {
          for (var azul = 0; azul < 256; azul += 51) {
            final fondo = Color.fromARGB(255, rojo, verde, azul);
            expect(
              colorTextoSobre(fondo),
              anyOf(Colors.white, Colors.black87),
              reason: 'fallo con $fondo',
            );
          }
        }
      }
    });

    test('el texto nunca sale del mismo color que el fondo', () {
      for (final tipo in Tipo.values) {
        expect(colorTextoSobre(colorDe(tipo)), isNot(colorDe(tipo)),
            reason: '$tipo quedaria ilegible');
      }
    });
  });
}