import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

void main() {
  group('Tablero.nivel1', () {
    test('tiene 7 filas y 7 columnas en zonas y valores', () {
      final tablero = Tablero.nivel1();
      expect(tablero.zonasPorCelda.length, 7);
      expect(tablero.valores.length, 7);
      for (var fila = 0; fila < 7; fila++) {
        expect(tablero.zonasPorCelda[fila].length, 7);
        expect(tablero.valores[fila].length, 7);
      }
    });

    test('todas las celdas pertenecen a una zona con color declarado', () {
      final tablero = Tablero.nivel1();
      for (final fila in tablero.zonasPorCelda) {
        for (final id in fila) {
          expect(tablero.coloresPorZona.containsKey(id), true,
              reason: 'la zona $id no tiene color');
        }
      }
    });

    test('está completo porque todas las celdas tienen valor', () {
      expect(Tablero.nivel1().estaCompleto(), true);
    });

    test('es válido porque respeta las reglas de cada color', () {
      expect(Tablero.nivel1().esValido(), true);
    });
  });

  group('Tablero.nivel1Inicial', () {
    test('tiene el mismo tablero pero sin ningún número', () {
      final inicial = Tablero.nivel1Inicial();
      expect(inicial.zonasPorCelda, Tablero.nivel1().zonasPorCelda);
      expect(inicial.estaCompleto(), false);
      for (final fila in inicial.valores) {
        expect(fila.every((v) => v == null), true);
      }
    });
  });

  group('tipoDe', () {
    test('devuelve el color de la zona a la que pertenece la celda', () {
      final tablero = Tablero.nivel1();
      expect(tablero.tipoDe(0, 0), Tipo.amarillo);
      expect(tablero.tipoDe(0, 2), Tipo.azul);
      expect(tablero.tipoDe(2, 1), Tipo.rojo);
      expect(tablero.tipoDe(3, 2), Tipo.morado);
      expect(tablero.tipoDe(1, 0), Tipo.verde);
    });
  });

  group('zona', () {
    test('arma la zona amarilla (id 1) con su color y sus valores', () {
      final zona = Tablero.nivel1().zona(1);
      expect(zona.id, 1);
      expect(zona.tipo, Tipo.amarillo);
      expect(zona.valores, [1, 5, 3, 2, 6]);
      expect(zona.esValida(), true);
    });

    test('arma la zona azul (id 3) con un único valor repetido', () {
      final zona = Tablero.nivel1().zona(3);
      expect(zona.tipo, Tipo.azul);
      expect(zona.valores, [2, 2, 2, 2]);
      expect(zona.esValida(), true);
    });

    test('arma la zona morada (id 4) con dos valores distintos', () {
      final zona = Tablero.nivel1().zona(4);
      expect(zona.tipo, Tipo.morado);
      expect(zona.valores, [6, 3, 6, 3, 6, 3]);
      expect(zona.esValida(), true);
    });

    test('arma la zona roja (id 7) con valores únicos', () {
      final zona = Tablero.nivel1().zona(7);
      expect(zona.tipo, Tipo.rojo);
      expect(zona.valores, [2, 3, 1, 4, 5, 6]);
      expect(zona.esValida(), true);
    });

    test('lanza un error si la zona no existe', () {
      expect(() => Tablero.nivel1().zona(99), throwsArgumentError);
    });
  });

  group('zonas', () {
    test('devuelve todas las zonas ordenadas por id', () {
      final ids = Tablero.nivel1().zonas().map((z) => z.id).toList();
      expect(ids, [1, 2, 3, 4, 6, 7, 8, 10, 11]);
    });

    test('todas las zonas del tablero completo son válidas', () {
      for (final zona in Tablero.nivel1().zonas()) {
        expect(zona.esValida(), true, reason: 'la zona ${zona.id} no es válida');
      }
    });
  });

  group('esValido', () {
    test('es falso si una zona queda inválida', () {
      final tablero = Tablero.nivel1();
      // La zona azul (id 3) solo admite un valor distinto entre sus celdas.
      tablero.valores[0][2] = 5;
      expect(tablero.esValido(), false);
    });

    test('es falso si un valor está fuera del rango 1 a 6', () {
      final tablero = Tablero.nivel1();
      tablero.valores[0][0] = 9;
      expect(tablero.esValido(), false);
    });
  });
}