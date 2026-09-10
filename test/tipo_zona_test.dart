import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

void main() {
  group('esValida', () {
    test('zona roja con valores únicos es válida', () {
      expect(const Zona(7, Tipo.rojo, [1, 2, 3, 4, 5, 6]).esValida(), true);
    });

    test('zona roja con repetidos no es válida', () {
      expect(const Zona(7, Tipo.rojo, [1, 2, 2]).esValida(), false);
    });

    test('zona amarilla con valores únicos es válida', () {
      expect(const Zona(1, Tipo.amarillo, [1, 5, 3, 2, 6]).esValida(), true);
    });

    test('zona azul con un solo valor es válida', () {
      expect(const Zona(3, Tipo.azul, [2, 2, 2, 2]).esValida(), true);
    });

    test('zona azul con valores distintos no es válida', () {
      expect(const Zona(3, Tipo.azul, [2, 2, 5]).esValida(), false);
    });

    test('zona morada con dos valores es válida', () {
      expect(const Zona(4, Tipo.morado, [6, 3, 6, 3]).esValida(), true);
    });

    test('zona morada con tres valores no es válida', () {
      expect(const Zona(4, Tipo.morado, [6, 3, 1]).esValida(), false);
    });

    test('zona verde acepta valores mezclados', () {
      expect(const Zona(2, Tipo.verde, [5, 2, 5, 3, 6, 1]).esValida(), true);
    });

    test('un número fuera del rango 1 a 6 invalida cualquier zona', () {
      expect(const Zona(2, Tipo.verde, [1, 9]).esValida(), false);
    });

    test('zona vacía es válida', () {
      expect(const Zona(7, Tipo.rojo, []).esValida(), true);
    });
  });

  group('aceptaNumero', () {
    test('la roja rechaza un número que ya tiene', () {
      expect(const Zona(7, Tipo.rojo, [1, 2, 3]).aceptaNumero(2), false);
    });

    test('la roja acepta un número nuevo', () {
      expect(const Zona(7, Tipo.rojo, [1, 2, 3]).aceptaNumero(4), true);
    });

    test('la azul solo acepta el mismo número', () {
      const zona = Zona(3, Tipo.azul, [2, 2]);
      expect(zona.aceptaNumero(2), true);
      expect(zona.aceptaNumero(5), false);
    });

    test('la morada rechaza un tercer valor', () {
      expect(const Zona(4, Tipo.morado, [6, 3]).aceptaNumero(1), false);
    });

    test('la verde acepta cualquiera del 1 al 6', () {
      expect(const Zona(2, Tipo.verde, [5, 2]).aceptaNumero(5), true);
    });

    test('la verde rechaza un número fuera del rango', () {
      expect(const Zona(2, Tipo.verde, [5, 2]).aceptaNumero(7), false);
    });
  });
}