import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/bloques.dart';

void main() {
  group('valoresDe', () {
    test('extrae los valores del rojo', () {
      expect(valoresDe(Region.rojo), [2, 3, 1, 4, 1, 2, 5, 6, 3, 4, 6, 5]);
    });

    test('extrae los valores del amarillo', () {
      expect(valoresDe(Region.amarillo), [1, 5, 3, 2, 6]);
    });

    test('extrae los valores del verde', () {
      expect(valoresDe(Region.verde), [5, 2, 5, 2, 3, 2, 4, 6, 3, 3, 6, 1]);
    });

    test('extrae los valores del azul', () {
      expect(valoresDe(Region.azul), [2, 2, 2, 2, 4, 4, 4, 4]);
    });

    test('extrae los valores del morado', () {
      expect(valoresDe(Region.morado), [6, 3, 6, 3, 6, 3, 4, 1, 4, 4, 1, 1]);
    });

    test('ignora las celdas vacías', () {
      expect(valoresDe(Region.rojo).length, 12);
    });
  });
}