import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/nivel.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

Map<int, int> celdasPorZona(Nivel nivel) {
  final cuenta = <int, int>{};
  for (final fila in nivel.zonasPorCelda) {
    for (final id in fila) {
      if (id == hueco) continue;
      cuenta[id] = (cuenta[id] ?? 0) + 1;
    }
  }
  return cuenta;
}

void main() {
  group('los niveles oficiales', () {
    test('son cuatro y estan numerados del 1 al 4', () {
      expect(nivelesOficiales, hasLength(4));
      for (var i = 0; i < 4; i++) {
        expect(nivelesOficiales[i].numero, i + 1);
      }
    });

    test('los cuatro estan transcritos y se pueden jugar', () {
      for (final nivel in nivelesOficiales) {
        expect(nivel.disponible, true, reason: 'nivel ${nivel.numero}');
        expect(nivel.nombre, isNotEmpty);
      }
    });

    test('todos son de 7 por 7', () {
      for (final nivel in nivelesOficiales) {
        expect(nivel.filas, 7, reason: 'nivel ${nivel.numero}');
        expect(nivel.columnas, 7, reason: 'nivel ${nivel.numero}');
        for (final fila in nivel.zonasPorCelda) {
          expect(fila, hasLength(7), reason: 'nivel ${nivel.numero}');
        }
      }
    });

    test('cada carta tiene el numero de zonas que marca su panel', () {
      expect(nivel1.coloresPorZona, hasLength(9));
      expect(nivel2.coloresPorZona, hasLength(10));
      expect(nivel3.coloresPorZona, hasLength(8));
      expect(nivel4.coloresPorZona, hasLength(8));
    });
  });

  group('la forma de cada tablero', () {
    test('toda casilla pertenece a una zona con color declarado', () {
      for (final nivel in nivelesOficiales) {
        for (final fila in nivel.zonasPorCelda) {
          for (final id in fila) {
            if (id == hueco) continue;
            expect(nivel.coloresPorZona.containsKey(id), true,
                reason: 'nivel ${nivel.numero}: la zona $id no tiene color');
          }
        }
      }
    });

    test('no se declaran zonas que no aparecen en el tablero', () {
      for (final nivel in nivelesOficiales) {
        final enElTablero = {
          for (final fila in nivel.zonasPorCelda) ...fila,
        }..remove(hueco);
        expect(nivel.coloresPorZona.keys.toSet(), enElTablero,
            reason: 'nivel ${nivel.numero}');
      }
    });

    test('las 49 casillas estan repartidas entre las zonas', () {
      for (final nivel in nivelesOficiales) {
        final total =
            celdasPorZona(nivel).values.fold(0, (suma, n) => suma + n);
        expect(total, 49, reason: 'nivel ${nivel.numero}');
      }
    });

    test('ninguna zona queda de una sola casilla', () {
      for (final nivel in nivelesOficiales) {
        celdasPorZona(nivel).forEach((id, cuantas) {
          expect(cuantas, greaterThan(1),
              reason: 'nivel ${nivel.numero}: la zona $id tiene $cuantas');
        });
      }
    });

    test('las zonas de todos distintos caben en el 1 al 6', () {
      for (final nivel in nivelesOficiales) {
        final cuenta = celdasPorZona(nivel);
        nivel.coloresPorZona.forEach((id, tipo) {
          if (tipo != Tipo.rojo && tipo != Tipo.amarillo) return;
          expect(cuenta[id], lessThanOrEqualTo(6),
              reason: 'nivel ${nivel.numero}: la zona $id es de ${cuenta[id]}');
        });
      }
    });
  });

  group('las anclas', () {
    test('son seis en cada nivel', () {
      for (final nivel in nivelesOficiales) {
        expect(nivel.anclas, hasLength(6), reason: 'nivel ${nivel.numero}');
      }
    });

    test('caen dentro del tablero', () {
      for (final nivel in nivelesOficiales) {
        for (final (fila, columna) in nivel.anclas) {
          expect(fila, inInclusiveRange(0, nivel.filas - 1));
          expect(columna, inInclusiveRange(0, nivel.columnas - 1));
        }
      }
    });

    test('no se repiten', () {
      for (final nivel in nivelesOficiales) {
        expect(nivel.anclas.toSet(), hasLength(nivel.anclas.length),
            reason: 'nivel ${nivel.numero}');
      }
    });

    test('caen en seis zonas distintas', () {
      for (final nivel in nivelesOficiales) {
        final zonas = [
          for (final (fila, columna) in nivel.anclas)
            nivel.zonasPorCelda[fila][columna],
        ];
        expect(zonas.toSet(), hasLength(6),
            reason: 'nivel ${nivel.numero}: dos anclas en la misma zona');
      }
    });
  });

  group('los puntajes', () {
    test('cada nivel declara los puntos de todos sus tipos', () {
      for (final nivel in nivelesOficiales) {
        for (final tipo in nivel.tiposUsados) {
          expect(nivel.puntos[tipo], isNotNull,
              reason: 'nivel ${nivel.numero}: falta $tipo');
          expect(nivel.puntos[tipo], hasLength(3));
        }
      }
    });

    test('van de mayor a menor', () {
      for (final nivel in nivelesOficiales) {
        nivel.puntos.forEach((tipo, puntos) {
          expect(puntos[0], greaterThan(puntos[1]), reason: '$tipo');
          expect(puntos[1], greaterThan(puntos[2]), reason: '$tipo');
        });
      }
    });

    test('el verde vale distinto en cada nivel', () {
      expect(nivel1.puntosDe(Tipo.verde), [4, 3, 2]);
      expect(nivel3.puntosDe(Tipo.verde), [8, 6, 4]);
      expect(nivel4.puntosDe(Tipo.verde), [3, 2, 1]);
    });

    test('si el nivel no lo declara cae en el valor por omision', () {
      const sinPuntos = Nivel(
        numero: 9,
        nombre: 'prueba',
        zonasPorCelda: [
          [1],
        ],
        coloresPorZona: {1: Tipo.rojo},
        anclas: [],
      );
      expect(sinPuntos.puntosDe(Tipo.rojo), puntosPorTipo[Tipo.rojo]);
    });
  });

  group('tiposUsados', () {
    test('devuelve solo los colores del nivel, sin repetir', () {
      expect(nivel1.tiposUsados, [
        Tipo.rojo,
        Tipo.amarillo,
        Tipo.verde,
        Tipo.azul,
        Tipo.morado,
      ]);
      expect(nivel4.tiposUsados, contains(Tipo.naranja1a3));
      expect(nivel4.tiposUsados, contains(Tipo.naranja4a6));
      for (final nivel in nivelesOficiales) {
        expect(nivel.tiposUsados.toSet(), hasLength(nivel.tiposUsados.length));
      }
    });

    test('solo el nivel 2 y el 3 usan el blanco', () {
      expect(nivel1.tiposUsados, isNot(contains(Tipo.blanco)));
      expect(nivel2.tiposUsados, contains(Tipo.blanco));
      expect(nivel3.tiposUsados, contains(Tipo.blanco));
      expect(nivel4.tiposUsados, isNot(contains(Tipo.blanco)));
    });
  });

  group('Tablero.deNivel', () {
    test('arma un tablero vacio con la forma del nivel', () {
      for (final nivel in nivelesOficiales) {
        final tablero = Tablero.deNivel(nivel);

        expect(tablero.zonasPorCelda, nivel.zonasPorCelda);
        expect(tablero.estaCompleto(), false);
        expect(tablero.puntos, 0);
        for (final fila in tablero.valores) {
          expect(fila.every((v) => v == null), true);
        }
      }
    });

    test('cada llamada da un tablero nuevo', () {
      final uno = Tablero.deNivel(nivel2);
      final otro = Tablero.deNivel(nivel2);

      uno.valores[0][0] = 4;

      expect(otro.valores[0][0], null);
    });

    test('las zonas del tablero cobran lo que dice el nivel', () {
      final tablero = Tablero.deNivel(nivel4);
      expect(tablero.zona(5).tipo, Tipo.verde);
      expect(tablero.zona(5).puntos, [3, 2, 1]);
    });
  });

  group('las zonas con rango', () {
    test('la de 1 a 3 rechaza del 4 para arriba', () {
      const zona = Zona(1, Tipo.naranja1a3, [1, 3]);
      expect(zona.aceptaNumero(2), true);
      expect(zona.aceptaNumero(4), false);
      expect(zona.aceptaNumero(6), false);
    });

    test('la de 4 a 6 rechaza del 3 para abajo', () {
      const zona = Zona(1, Tipo.naranja4a6, [4, 6]);
      expect(zona.aceptaNumero(5), true);
      expect(zona.aceptaNumero(3), false);
      expect(zona.aceptaNumero(1), false);
    });

    test('dentro del rango no le molesta repetir', () {
      expect(const Zona(1, Tipo.naranja1a3, [2, 2, 2]).esValida(), true);
      expect(const Zona(1, Tipo.naranja4a6, [5, 5]).esValida(), true);
    });

    test('los tipos sin rango aceptan del 1 al 6', () {
      expect(const Zona(1, Tipo.verde, []).rango, (1, 6));
      expect(const Zona(1, Tipo.naranja1a3, []).rango, (1, 3));
      expect(const Zona(1, Tipo.naranja4a6, []).rango, (4, 6));
    });
  });

  group('la zona blanca', () {
    test('pide todos iguales, como la azul', () {
      expect(const Zona(1, Tipo.blanco, [4, 4, 4]).esValida(), true);
      expect(const Zona(1, Tipo.blanco, [4, 5]).esValida(), false);
    });

    test('vacia es valida', () {
      expect(const Zona(1, Tipo.blanco, []).esValida(), true);
    });
  });

  group('los huecos', () {
    Tablero conHueco() => Tablero(
          [
            [1, hueco, 1],
          ],
          {1: Tipo.verde},
          [
            [2, null, null],
          ],
        );

    test('esHueco distingue la casilla sin zona', () {
      final tablero = conHueco();
      expect(tablero.esHueco(0, 0), false);
      expect(tablero.esHueco(0, 1), true);
    });

    test('no se puede escribir en un hueco', () {
      expect(conHueco().celdasPosibles(3, 2), isEmpty);
    });

    test('un tablero lleno salvo sus huecos esta completo', () {
      final tablero = conHueco();
      tablero.valores[0][2] = 5;

      expect(tablero.estaCompleto(), true);
    });

    test('ninguna carta oficial trae huecos', () {
      for (final nivel in nivelesOficiales) {
        for (final fila in nivel.zonasPorCelda) {
          expect(fila, isNot(contains(hueco)),
              reason: 'nivel ${nivel.numero}');
        }
      }
    });
  });
}
