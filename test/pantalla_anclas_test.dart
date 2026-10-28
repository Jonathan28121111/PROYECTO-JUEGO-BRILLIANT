import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/nivel.dart';
import 'package:pruebas_numeros/pantalla_anclas.dart';
import 'package:pruebas_numeros/tablero_bloc.dart';

import 'ayudas_interfaz.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester, {
    TableroBloc? bloc,
    Nivel nivel = nivel1,
  }) async {
    pantallaGrande(tester);
    await tester.pumpWidget(montar(PantallaAnclas(nivel: nivel), bloc: bloc));
    await tester.pumpAndSettle();
  }

  group('como se dibuja al abrir', () {
    testWidgets('hay una estrella por cada ancla', (tester) async {
      await abrir(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(6));
    });

    testWidgets('la bandeja arranca con las seis fichas', (tester) async {
      await abrir(tester);

      expect(find.byType(Draggable<int>), findsNWidgets(6));
      for (var n = 1; n <= 6; n++) {
        expect(find.widgetWithText(Draggable<int>, '$n'), findsOneWidget);
      }
    });

    testWidgets('el tablero empieza sin ningun numero', (tester) async {
      await abrir(tester);

      for (var n = 1; n <= 6; n++) {
        expect(enElTablero('$n'), findsNothing);
      }
    });

    testWidgets('el contador arranca en cero', (tester) async {
      await abrir(tester);

      expect(find.text('0 de 6 colocados'), findsOneWidget);
      expect(find.text('¡Listo! Empezar a jugar'), findsNothing);
    });
  });

  group('soltar una ficha', () {
    testWidgets('el numero aparece en la casilla donde lo solte',
        (tester) async {
      await abrir(tester);

      await arrastrarFicha(tester, 3, 0, 2);

      expect(enElTablero('3'), findsOneWidget);
    });

    testWidgets('la ficha usada desaparece de la bandeja', (tester) async {
      await abrir(tester);

      await arrastrarFicha(tester, 3, 0, 2);

      expect(find.widgetWithText(Draggable<int>, '3'), findsNothing);
      expect(find.byType(Draggable<int>), findsNWidgets(5));
    });

    testWidgets('el contador sube de uno en uno', (tester) async {
      await abrir(tester);

      await arrastrarFicha(tester, 1, 0, 2);
      expect(find.text('1 de 6 colocados'), findsOneWidget);

      await arrastrarFicha(tester, 2, 1, 5);
      expect(find.text('2 de 6 colocados'), findsOneWidget);
    });

    testWidgets('soltar en una casilla que no es ancla no hace nada',
        (tester) async {
      await abrir(tester);

      await arrastrarFicha(tester, 4, 0, 0);

      expect(enElTablero('4'), findsNothing);
      expect(find.text('0 de 6 colocados'), findsOneWidget);
      expect(find.byType(Draggable<int>), findsNWidgets(6));
    });
  });

  group('corregir lo que ya puse', () {
    testWidgets('tocar un numero puesto lo quita y lo regresa a la bandeja',
        (tester) async {
      await abrir(tester);
      await arrastrarFicha(tester, 3, 0, 2);
      expect(enElTablero('3'), findsOneWidget);

      await tester.tapAt(centroDeCelda(tester, 0, 2));
      await tester.pumpAndSettle();

      expect(enElTablero('3'), findsNothing);
      expect(find.widgetWithText(Draggable<int>, '3'), findsOneWidget);
      expect(find.text('0 de 6 colocados'), findsOneWidget);
    });

    testWidgets('soltar otro numero en la misma ancla lo reemplaza',
        (tester) async {
      await abrir(tester);

      await arrastrarFicha(tester, 3, 0, 2);
      await arrastrarFicha(tester, 4, 0, 2);

      expect(enElTablero('4'), findsOneWidget);
      expect(enElTablero('3'), findsNothing);
      expect(find.text('1 de 6 colocados'), findsOneWidget);
      expect(find.widgetWithText(Draggable<int>, '3'), findsOneWidget);
    });

    testWidgets('tocar una casilla vacia no hace nada', (tester) async {
      await abrir(tester);
      await arrastrarFicha(tester, 3, 0, 2);

      await tester.tapAt(centroDeCelda(tester, 1, 5)); // ancla, pero vacía
      await tester.tapAt(centroDeCelda(tester, 0, 0)); // casilla normal
      await tester.pumpAndSettle();

      expect(find.text('1 de 6 colocados'), findsOneWidget);
    });
  });

  group('el boton de empezar', () {
    testWidgets('cambia de texto al completar las seis', (tester) async {
      await abrir(tester);

      for (var n = 1; n <= 6; n++) {
        await arrastrarFicha(
          tester,
          n,
          [0, 1, 3, 3, 5, 6][n - 1],
          [2, 5, 1, 4, 2, 4][n - 1],
        );
      }

      expect(find.text('¡Listo! Empezar a jugar'), findsOneWidget);
      expect(find.text('6 de 6 colocados'), findsNothing);
    });

    testWidgets('al tocarlo le manda los valores iniciales al bloc',
        (tester) async {
      final bloc = TableroBloc();
      addTearDown(bloc.close);

      await abrir(tester, bloc: bloc);
      expect(bloc.state, isA<TableroSinIniciar>());

      for (var n = 1; n <= 6; n++) {
        await arrastrarFicha(
          tester,
          n,
          [0, 1, 3, 3, 5, 6][n - 1],
          [2, 5, 1, 4, 2, 4][n - 1],
        );
      }

      await tester.tap(find.text('¡Listo! Empezar a jugar'));
      await tester.pumpAndSettle();

      expect(bloc.state, isA<TableroEnJuego>());
      final juego = bloc.state as TableroEnJuego;
      expect(juego.tablero.valores[0][2], 1);
      expect(juego.tablero.valores[1][5], 2);
      expect(juego.tablero.valores[6][4], 6);
      expect(juego.tablero.valores[0][0], null);
    });

    testWidgets('no manda nada mientras falte una ficha', (tester) async {
      final bloc = TableroBloc();
      addTearDown(bloc.close);

      await abrir(tester, bloc: bloc);

      for (var n = 1; n <= 5; n++) {
        await arrastrarFicha(
          tester,
          n,
          [0, 1, 3, 3, 5][n - 1],
          [2, 5, 1, 4, 2][n - 1],
        );
      }

      await tester.tap(find.text('5 de 6 colocados'));
      await tester.pumpAndSettle();

      expect(bloc.state, isA<TableroSinIniciar>());
    });
  });

  group('los paneles de reglas', () {
    testWidgets('se dibujan los de los dos lados', (tester) async {
      await abrir(tester);

      expect(find.text('≠'), findsNWidgets(2));
      expect(find.text('='), findsOneWidget);
      expect(find.text('XO'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });
  });

  group('las zonas con rango del nivel 4', () {
    const anclaArriba = (0, 4); 
    const anclaAbajo = (6, 1); 

    testWidgets('rechaza un 3 en la zona que solo toma del 4 al 6',
        (tester) async {
      await abrir(tester, nivel: nivel4);

      await arrastrarFicha(tester, 3, anclaArriba.$1, anclaArriba.$2);

      expect(enElTablero('3'), findsNothing);
      expect(find.text('0 de 6 colocados'), findsOneWidget);
      expect(find.widgetWithText(Draggable<int>, '3'), findsOneWidget);
    });

    testWidgets('acepta un 5 en esa misma casilla', (tester) async {
      await abrir(tester, nivel: nivel4);

      await arrastrarFicha(tester, 5, anclaArriba.$1, anclaArriba.$2);

      expect(enElTablero('5'), findsOneWidget);
      expect(find.text('1 de 6 colocados'), findsOneWidget);
    });

    testWidgets('rechaza un 6 en la zona que solo toma del 1 al 3',
        (tester) async {
      await abrir(tester, nivel: nivel4);

      await arrastrarFicha(tester, 6, anclaAbajo.$1, anclaAbajo.$2);

      expect(enElTablero('6'), findsNothing);
      expect(find.text('0 de 6 colocados'), findsOneWidget);
    });

    testWidgets('acepta un 2 en esa misma casilla', (tester) async {
      await abrir(tester, nivel: nivel4);

      await arrastrarFicha(tester, 2, anclaAbajo.$1, anclaAbajo.$2);

      expect(enElTablero('2'), findsOneWidget);
    });
  });

  group('las anclas de los otros niveles', () {
    testWidgets('sin zonas de rango cualquier numero entra', (tester) async {
      for (final nivel in [nivel1, nivel2, nivel3]) {
        await abrir(tester, nivel: nivel);

        final ancla = nivel.anclas.first;
        await arrastrarFicha(tester, 3, ancla.$1, ancla.$2);

        expect(enElTablero('3'), findsOneWidget,
            reason: 'el nivel ${nivel.numero} rechazo un 3');
      }
    });

    testWidgets('cada nivel dibuja sus propias estrellas', (tester) async {
      for (final nivel in nivelesOficiales) {
        await abrir(tester, nivel: nivel);

        expect(find.byIcon(Icons.star), findsNWidgets(6),
            reason: 'nivel ${nivel.numero}');
      }
    });
  });
}