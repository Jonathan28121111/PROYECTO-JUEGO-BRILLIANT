import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/main.dart';
import 'package:pruebas_numeros/nivel.dart';
import 'package:pruebas_numeros/pantalla_anclas.dart';
import 'package:pruebas_numeros/pantalla_juego.dart';
import 'package:pruebas_numeros/pantalla_niveles.dart';
import 'package:pruebas_numeros/vista_juego.dart';

import 'ayudas_interfaz.dart';
import 'servidor_falso.dart';

void main() {
  group('prueba de humo', () {
    Future<void> abrirComoInvitado(WidgetTester tester) async {
      await tester.pumpWidget(
        JuegoBrilliantApp(cliente: ServidorFalso().cliente()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jugar sin cuenta'));
      await tester.pumpAndSettle();
    }

    testWidgets('la app arranca sin reventar', (tester) async {
      pantallaGrande(tester);

      await abrirComoInvitado(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Juego Brilliant'), findsOneWidget);
    });

    testWidgets('arranca preguntando como jugar', (tester) async {
      pantallaGrande(tester);

      await abrirComoInvitado(tester);

      expect(find.byType(PantallaNiveles), findsOneWidget);
      expect(find.text('¿Cómo quieres jugar?'), findsOneWidget);
      expect(find.byKey(const Key('modo_solo')), findsOneWidget);
      expect(find.byKey(const Key('modo_en_linea')), findsOneWidget);
      expect(find.byType(TarjetaNivel), findsNothing);
      expect(find.byType(PantallaAnclas), findsNothing);
      expect(find.byType(VistaJuego), findsNothing);
    });

    testWidgets('jugar solo lleva a los tableros y se puede volver', (
      tester,
    ) async {
      pantallaGrande(tester);
      await abrirComoInvitado(tester);

      await tester.tap(find.text('Elegir tablero'));
      await tester.pumpAndSettle();
      expect(find.text('Elige un tablero'), findsOneWidget);
      expect(find.byType(TarjetaNivel), findsNWidgets(4));

      await tester.tap(find.byKey(const Key('volver_modos')));
      await tester.pumpAndSettle();
      expect(find.text('¿Cómo quieres jugar?'), findsOneWidget);
    });

    testWidgets('al salir de un tablero se vuelve a los tableros, no a los '
        'modos', (tester) async {
      pantallaGrande(tester);
      await abrirComoInvitado(tester);
      await tester.tap(find.text('Elegir tablero'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nivel 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('salir_tablero')));
      await tester.pumpAndSettle();

      expect(find.text('Elige un tablero'), findsOneWidget);
    });
  });

  group('el paso de una pantalla a la otra', () {
    Future<void> elegirNivel1(WidgetTester tester) async {
      await tester.tap(find.text('Nivel 1'));
      await tester.pumpAndSettle();
    }

    testWidgets('al elegir un nivel se pasa a colocar las anclas', (
      tester,
    ) async {
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

  group('salir del tablero', () {
    Future<void> abrirNivel1(WidgetTester tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(const MaterialApp(home: PantallaJuego()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nivel 1'));
      await tester.pumpAndSettle();
    }

    Future<void> empezarPartida(WidgetTester tester) async {
      await abrirNivel1(tester);
      for (var n = 1; n <= 6; n++) {
        final ancla = nivel1.anclas[n - 1];
        await arrastrarFicha(tester, n, ancla.$1, ancla.$2);
      }
      await tester.tap(find.text('¡Listo! Empezar a jugar'));
      await tester.pumpAndSettle();
    }

    testWidgets('en la seleccion no hay boton de salir', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(const MaterialApp(home: PantallaJuego()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('salir_tablero')), findsNothing);
    });

    testWidgets('mientras se ponen las anclas sale directo', (tester) async {
      await abrirNivel1(tester);

      await tester.tap(find.byKey(const Key('salir_tablero')));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaNiveles), findsOneWidget);
      expect(find.byType(PantallaAnclas), findsNothing);
    });

    testWidgets('a media partida pregunta y nombra el tablero', (tester) async {
      await empezarPartida(tester);

      await tester.tap(find.byKey(const Key('salir_tablero')));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir del Nivel 1?'), findsOneWidget);

      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(find.byType(VistaJuego), findsOneWidget);

      await tester.tap(find.byKey(const Key('salir_tablero')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar_salir_tablero')));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaNiveles), findsOneWidget);
      expect(find.byType(VistaJuego), findsNothing);
    });

    testWidgets('despues de salir se puede elegir otro tablero', (
      tester,
    ) async {
      await abrirNivel1(tester);
      await tester.tap(find.byKey(const Key('salir_tablero')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nivel 2'));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaAnclas), findsOneWidget);
    });
  });
}
