import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/dados.dart';

void main() {
  test('los dos valores quedan siempre entre 1 y 6', () {
    final azar = Random(7);
    for (var tirada = 0; tirada < 300; tirada++) {
      final dados = Dados.tirar(azar);
      expect(dados.primero, inInclusiveRange(1, 6));
      expect(dados.segundo, inInclusiveRange(1, 6));
    }
  });

  test('con la misma semilla sale la misma tirada', () {
    final unos = Dados.tirar(Random(42));
    final otros = Dados.tirar(Random(42));
    expect(unos.primero, otros.primero);
    expect(unos.segundo, otros.segundo);
  });

  test('tiradas seguidas no son todas iguales', () {
    final azar = Random(3);
    final resultados = {
      for (var tirada = 0; tirada < 50; tirada++) Dados.tirar(azar).primero,
    };
    expect(resultados.length, greaterThan(1));
  });
    group('companeroDe', () {
    test('devuelve el otro valor de la tirada', () {
      const dados = Dados(2, 5);
      expect(dados.companeroDe(2), 5);
      expect(dados.companeroDe(5), 2);
    });

    test('con los dos dados iguales el companero es el mismo numero', () {
      const dados = Dados(4, 4);
      expect(dados.companeroDe(4), 4);
    });

    test('lanza un error si el numero no salio', () {
      const dados = Dados(2, 5);
      expect(() => dados.companeroDe(3), throwsArgumentError);
    });
  });

  group('contiene', () {
    test('reconoce los dos valores de la tirada', () {
      const dados = Dados(2, 5);
      expect(dados.contiene(2), true);
      expect(dados.contiene(5), true);
      expect(dados.contiene(4), false);
    });
  });
}