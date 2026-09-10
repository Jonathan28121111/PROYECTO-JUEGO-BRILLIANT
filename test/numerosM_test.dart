  import 'package:flutter_test/flutter_test.dart';
  import 'package:pruebas_numeros/numerosM.dart';
    
    void main() {
    group('bloque morado: máximo dos valores distintos', () {
      test('lista con dos valores y número repetido retorna true', () {
        expect(cabenSoloDosValores([5, 4, 5], 4), true);
      });

      test('lista con un valor y número nuevo retorna true', () {
        expect(cabenSoloDosValores([5, 5, 5], 4), true);
      });

      test('lista con dos valores y un tercer número retorna false', () {
        expect(cabenSoloDosValores([5, 4], 3), false);
      });

      test('lista que ya tiene tres valores retorna false', () {
        expect(cabenSoloDosValores([5, 4, 3], 5), false);
      });

      test('lista vacía retorna true', () {
        expect(cabenSoloDosValores([], 6), true);
      });

      test('todos iguales retorna true', () {
        expect(cabenSoloDosValores([2, 2, 2], 2), true);
      });
    });
    }