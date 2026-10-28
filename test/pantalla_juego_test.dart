import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/main.dart';
import 'package:pruebas_numeros/nivel.dart';
import 'package:pruebas_numeros/pantalla_anclas.dart';
import 'package:pruebas_numeros/pantalla_juego.dart';
import 'package:pruebas_numeros/pantalla_niveles.dart';
import 'package:pruebas_numeros/vista_juego.dart';

import 'ayudas_interfaz.dart';

void main() {
  group('prueba de humo', () {
    testWidgets('la app arranca sin reventar', (tester) async {
      pantallaGrande(tester);

      await tester.pumpWidget(const JuegoBrilliantApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Juego Brilliant'), findsOneWidget);
    });

    testWidgets('arranca en el selector de niveles', (tester) async {
      pantallaGrande(tester);

      await tester.pumpWidget(const JuegoBrilliantApp());
      await tester.pumpAndSettle();

      expect(find.byType(PantallaNiveles), findsOneWidget);
      expect(find.byType(PantallaAnclas), findsNothing);
      expect(find.byType(VistaJuego), findsNothing);
      expect(find.text('Elige un tablero'), findsOneWidget);
    });
  });

  group('el paso de una pantalla a la otra', () {
    Future<void> elegirNivel1(WidgetTester tester) async {
      await tester.tap(find.text('Nivel 1'));
      await tester.pumpAndSettle();
    }

    testWidgets('al elegir un nivel se pasa a colocar las anclas',
        (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(const MaterialApp(home: PantallaJuego()));
      await tester.pumpAndSettle();

      await elegirNivel1(tester);

      expect(find.byType(PantallaAnclas), findsOneWidget);
      expect(find.byType(PantallaNiveles), findsNothing);
      expect(find.text('0 de 6 colocados'), findsOneWidget);
    });

    testWidgets('con las seis fichas puestas se entra a jugar', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(const MaterialApp(home: PantallaJuego()));
      await tester.pumpAndSettle();
      await elegirNivel1(tester);

      for (var n = 1; n <= 6; n++) {
        final ancla = nivel1.anclas[n - 1];
        await arrastrarFicha(tester, n, ancla.$1, ancla.$2);
      }

      expect(find.text('¡Listo! Empezar a jugar'), findsOneWidget);

      await tester.tap(find.text('¡Listo! Empezar a jugar'));
      await tester.pumpAndSettle();

      expect(find.byType(VistaJuego), findsOneWidget);
      expect(find.byType(PantallaAnclas), findsNothing);
      expect(find.text('Tira los dados para jugar'), findsOneWidget);
    });

    testWidgets('el boton no hace nada mientras falten fichas', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(const MaterialApp(home: PantallaJuego()));
      await tester.pumpAndSettle();
      await elegirNivel1(tester);

      await arrastrarFicha(tester, 1, 0, 2);
      expect(find.text('1 de 6 colocados'), findsOneWidget);

      await tester.tap(find.text('1 de 6 colocados'));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaAnclas), findsOneWidget);
      expect(find.byType(VistaJuego), findsNothing);
    });
  });
}