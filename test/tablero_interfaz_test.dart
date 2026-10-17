import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/colores.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tablero_interfaz.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

import 'ayudas_interfaz.dart';

void main() {
  Tablero tresColores() => Tablero(
        [
          [1, 2, 3],
        ],
        {1: Tipo.rojo, 2: Tipo.azul, 3: Tipo.verde},
        [
          [null, null, null],
        ],
      );

  Future<void> montarTablero(
    WidgetTester tester, {
    required Tablero tablero,
    List<(int, int)> anclas = const [],
    Map<(int, int), int> numeros = const {},
    List<(int, int)> posibles = const [],
    bool arrastrando = false,
    void Function((int, int), int)? alSoltar,
    void Function((int, int))? alQuitar,
    void Function((int, int))? alTocar,
  }) async {
    pantallaGrande(tester);
    await tester.pumpWidget(montar(
      Center(
        child: SizedBox(
          width: 600,
          height: 600,
          child: TableroInterfaz(
            tablero: tablero,
            anclas: anclas,
            numeros: numeros,
            posibles: posibles,
            arrastrando: arrastrando,
            alSoltar: alSoltar ?? (_, _) {},
            alQuitar: alQuitar ?? (_) {},
            alTocar: alTocar,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('la rejilla', () {
    testWidgets('dibuja una casilla por cada celda del tablero',
        (tester) async {
      await montarTablero(tester, tablero: tresColores());

      expect(
        find.descendant(
          of: find.byType(TableroInterfaz),
          matching: find.byType(LayoutBuilder),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('el tablero del nivel 1 dibuja las 49 casillas',
        (tester) async {
      await montarTablero(tester, tablero: Tablero.nivel1Inicial());

      expect(
        find.descendant(
          of: find.byType(TableroInterfaz),
          matching: find.byType(LayoutBuilder),
        ),
        findsNWidgets(49),
      );
    });

    testWidgets('se dibuja cuadrado aunque la caja no lo sea', (tester) async {
      await montarTablero(tester, tablero: tresColores());

      final cuadro = tester.getRect(
        find.descendant(
          of: find.byType(TableroInterfaz),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(cuadro.width, cuadro.height);
    });
  });

  group('los colores', () {
    testWidgets('cada casilla se pinta del color de su zona', (tester) async {
      await montarTablero(tester, tablero: tresColores());

      // Una casilla de cada color, ni más ni menos.
      for (final tipo in [Tipo.rojo, Tipo.azul, Tipo.verde]) {
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == colorDe(tipo),
          ),
          findsOneWidget,
          reason: 'falta la casilla $tipo',
        );
      }
    });

    testWidgets('no usa un color que no esta en el tablero', (tester) async {
      await montarTablero(tester, tablero: tresColores());

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == colorDe(Tipo.morado),
        ),
        findsNothing,
      );
    });
  });

  group('las estrellas de las anclas', () {
    testWidgets('solo las anclas llevan estrella', (tester) async {
      await montarTablero(
        tester,
        tablero: tresColores(),
        anclas: const [(0, 0)],
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('sin anclas no hay ninguna estrella', (tester) async {
      await montarTablero(tester, tablero: tresColores());

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('solo las anclas reciben fichas', (tester) async {
      await montarTablero(
        tester,
        tablero: tresColores(),
        anclas: const [(0, 0), (0, 2)],
      );

      expect(find.byType(DragTarget<int>), findsNWidgets(2));
    });
  });

  group('los numeros', () {
    testWidgets('muestra los numeros que le pasan', (tester) async {
      await montarTablero(
        tester,
        tablero: tresColores(),
        anclas: const [(0, 0)],
        numeros: const {(0, 0): 4},
      );

      expect(enElTablero('4'), findsOneWidget);
    });

    testWidgets('las casillas sin numero quedan vacias', (tester) async {
      await montarTablero(
        tester,
        tablero: tresColores(),
        numeros: const {(0, 1): 6},
      );

      expect(enElTablero('6'), findsOneWidget);
      for (final otro in ['1', '2', '3', '4', '5']) {
        expect(enElTablero(otro), findsNothing);
      }
    });
  });

  group('los toques', () {
    testWidgets('tocar una casilla posible avisa con sus coordenadas',
        (tester) async {
      (int, int)? tocada;

      await montarTablero(
        tester,
        tablero: tresColores(),
        posibles: const [(0, 1)],
        alTocar: (celda) => tocada = celda,
      );

      await tester.tapAt(centroDeCelda(tester, 0, 1, filas: 1, columnas: 3));
      await tester.pumpAndSettle();

      expect(tocada, (0, 1));
    });

    testWidgets('tocar una casilla que no es posible no avisa', (tester) async {
      (int, int)? tocada;

      await montarTablero(
        tester,
        tablero: tresColores(),
        posibles: const [(0, 1)],
        alTocar: (celda) => tocada = celda,
      );

      await tester.tapAt(centroDeCelda(tester, 0, 2, filas: 1, columnas: 3));
      await tester.pumpAndSettle();

      expect(tocada, null);
    });

    testWidgets('tocar un ancla con numero pide quitarlo', (tester) async {
      (int, int)? quitada;

      await montarTablero(
        tester,
        tablero: tresColores(),
        anclas: const [(0, 0)],
        numeros: const {(0, 0): 4},
        alQuitar: (celda) => quitada = celda,
      );

      await tester.tapAt(centroDeCelda(tester, 0, 0, filas: 1, columnas: 3));
      await tester.pumpAndSettle();

      expect(quitada, (0, 0));
    });

    testWidgets('tocar un ancla vacia no pide quitar nada', (tester) async {
      (int, int)? quitada;

      await montarTablero(
        tester,
        tablero: tresColores(),
        anclas: const [(0, 0)],
        alQuitar: (celda) => quitada = celda,
      );

      await tester.tapAt(centroDeCelda(tester, 0, 0, filas: 1, columnas: 3));
      await tester.pumpAndSettle();

      expect(quitada, null);
    });
  });

  group('soltar una ficha', () {
    testWidgets('el ancla avisa que celda y que numero recibio',
        (tester) async {
      (int, int)? celdaRecibida;
      int? numeroRecibido;

      pantallaGrande(tester);
      await tester.pumpWidget(montar(
        Column(
          children: [
            Draggable<int>(
              data: 5,
              feedback: const SizedBox(width: 40, height: 40),
              child: const SizedBox(width: 40, height: 40, child: Text('5')),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 600,
                  height: 600,
                  child: TableroInterfaz(
                    tablero: tresColores(),
                    anclas: const [(0, 2)],
                    numeros: const {},
                    arrastrando: true,
                    alSoltar: (celda, numero) {
                      celdaRecibida = celda;
                      numeroRecibido = numero;
                    },
                    alQuitar: (_) {},
                  ),
                ),
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      final gesto = await tester.startGesture(
        tester.getCenter(find.widgetWithText(Draggable<int>, '5')),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await gesto.moveTo(centroDeCelda(tester, 0, 2, filas: 1, columnas: 3));
      await tester.pump();
      await gesto.up();
      await tester.pumpAndSettle();

      expect(celdaRecibida, (0, 2));
      expect(numeroRecibido, 5);
    });
  });
}
