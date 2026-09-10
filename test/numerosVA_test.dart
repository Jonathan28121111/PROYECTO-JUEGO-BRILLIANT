import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/numerosVA.dart';

void main() {
  group('bloque azul: todos iguales', () {
    test('lista con el mismo número y número igual retorna true', () {
      expect(todosSerianIguales([5, 5, 5], 5), true);
    });

    test('número distinto al de la lista retorna false', () {
      expect(todosSerianIguales([5, 5, 5], 2), false);
    });

    test('lista con valores mezclados retorna false', () {
      expect(todosSerianIguales([5, 5, 3], 5), false);
    });

    test('lista vacía retorna true', () {
      expect(todosSerianIguales([], 4), true);
    });

    test('lista de un elemento igual al número retorna true', () {
      expect(todosSerianIguales([6], 6), true);
    });
  });

  group('bloque verde: comodín', () {
    test('número dentro del rango retorna true', () {
      expect(cualquierNumeroEsValido([2, 5, 3], 4), true);
    });

    test('acepta el número aunque ya esté en la lista', () {
      expect(cualquierNumeroEsValido([2, 2, 2], 2), true);
    });

    test('número menor a 1 retorna false', () {
      expect(cualquierNumeroEsValido([1, 2], 0), false);
    });

    test('número mayor a 6 retorna false', () {
      expect(cualquierNumeroEsValido([1, 2], 7), false);
    });

    test('lista vacía con número válido retorna true', () {
      expect(cualquierNumeroEsValido([], 3), true);
    });
  });
}