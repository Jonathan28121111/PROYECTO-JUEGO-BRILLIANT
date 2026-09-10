import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/numeros.dart';

void main() {
  group('todosSerianDiferentes', () {
    test('lista sin repetidos y número nuevo retorna true', () {
      expect(todosSerianDiferentes([1, 2, 3], 4), true);
    });

    test('el número ya existe en la lista retorna false', () {
      expect(todosSerianDiferentes([1, 2, 3], 2), false);
    });

    test('la lista ya tiene repetidos retorna false', () {
      expect(todosSerianDiferentes([1, 2, 2, 3], 5), false);
    });

    test('lista vacía retorna true', () {
      expect(todosSerianDiferentes([], 7), true);
    });

    test('un solo elemento igual al número retorna false', () {
      expect(todosSerianDiferentes([9], 9), false);
    });

    test('funciona con números negativos', () {
      expect(todosSerianDiferentes([-1, -2, 0], -3), true);
      expect(todosSerianDiferentes([-1, -2, 0], -1), false);
    });
  });
  
}

