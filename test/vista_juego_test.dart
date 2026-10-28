import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/dados.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tablero_bloc.dart';
import 'package:pruebas_numeros/tipo_zona.dart';
import 'package:pruebas_numeros/vista_juego.dart';

import 'ayudas_interfaz.dart';

void main() {
  Future<void> montarVista(
    WidgetTester tester, {
    Tablero? tablero,
    Dados? dados,
    int? elegido,
    List<(int, int)> posibles = const [],
    bool puedeTirar = true,
    bool resuelto = false,
    TableroBloc? bloc,
  }) async {
    pantallaGrande(tester);
    await tester.pumpWidget(montar(
      VistaJuego(
        tablero: tablero ?? Tablero.nivel1Inicial(),
        dados: dados,
        elegido: elegido,
        posibles: posibles,
        puedeTirar: puedeTirar,
        resuelto: resuelto,
      ),
      bloc: bloc,
    ));
    await tester.pumpAndSettle();
  }

  group('el mensaje de abajo', () {
    testWidgets('resuelto gana sobre todo lo demas', (tester) async {
      await montarVista(tester, tablero: Tablero.nivel1(), resuelto: true);

      expect(find.text('¡Tablero resuelto!'), findsOneWidget);
    });

    testWidgets('sin tirada pide tirar', (tester) async {
      await montarVista(tester);

      expect(find.text('Tira los dados para jugar'), findsOneWidget);
    });

    testWidgets('si se puede volver a tirar lo dice', (tester) async {
      await montarVista(tester, dados: const Dados(5, 6), puedeTirar: true);

      expect(find.text('No hay ninguna jugada: vuelve a tirar'), findsOneWidget);
    });

    testWidgets('con tirada y sin elegir pide elegir', (tester) async {
      await montarVista(
        tester,
        dados: const Dados(3, 2),
        puedeTirar: false,
      );

      expect(
        find.text('Elige cuál de los dos números vas a escribir'),
        findsOneWidget,
      );
    });

    testWidgets('con un numero elegido que no sirve manda al otro',
        (tester) async {
      await montarVista(
        tester,
        dados: const Dados(3, 2),
        elegido: 3,
        posibles: const [],
        puedeTirar: false,
      );

      expect(
        find.text('Con ese número no hay jugada: prueba con el otro'),
        findsOneWidget,
      );
    });

    testWidgets('con jugadas disponibles pide tocar una casilla',
        (tester) async {
      await montarVista(
        tester,
        dados: const Dados(3, 2),
        elegido: 3,
        posibles: const [(0, 1)],
        puedeTirar: false,
      );

      expect(find.text('Toca una casilla resaltada'), findsOneWidget);
    });
  });

  group('el marcador', () {
    testWidgets('el tablero vacio arranca en cero', (tester) async {
      await montarVista(tester);

      expect(find.text('0'), findsOneWidget);
      expect(find.text('puntos'), findsOneWidget);
      expect(find.textContaining('zonas'), findsNothing);
    });

    testWidgets('el tablero resuelto muestra los 54 puntos', (tester) async {
      await montarVista(tester, tablero: Tablero.nivel1(), resuelto: true);

      expect(find.text('54'), findsOneWidget);
      expect(find.textContaining('zonas'), findsNothing);
    });

    testWidgets('el puntaje baja si una zona queda incompleta', (tester) async {
      final tablero = Tablero.nivel1();
      tablero.valores[0][2] = null; // una casilla de la zona azul, que vale 7

      await montarVista(tester, tablero: tablero);

      expect(find.text('47'), findsOneWidget);
    });
  });

  group('los dados', () {
    Finder dadoCon(String texto) =>
        find.widgetWithText(AnimatedContainer, texto);

    testWidgets('sin tirada los dos salen en blanco', (tester) async {
      await montarVista(tester);

      expect(dadoCon('–'), findsNWidgets(2));
    });

    testWidgets('con tirada cada dado muestra su valor', (tester) async {
      await montarVista(tester, dados: const Dados(3, 2), puedeTirar: false);

      expect(dadoCon('3'), findsOneWidget);
      expect(dadoCon('2'), findsOneWidget);
      expect(dadoCon('–'), findsNothing);
    });

    testWidgets('con los dos dados iguales se ven los dos', (tester) async {
      await montarVista(tester, dados: const Dados(4, 4), puedeTirar: false);

      expect(dadoCon('4'), findsNWidgets(2));
    });
  });

  group('el boton de tirar', () {
    FilledButton boton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    testWidgets('esta activo cuando se puede tirar', (tester) async {
      await montarVista(tester, puedeTirar: true);

      expect(boton(tester).onPressed, isNotNull);
    });

    testWidgets('esta apagado si hay una jugada pendiente', (tester) async {
      await montarVista(
        tester,
        dados: const Dados(3, 2),
        elegido: 3,
        posibles: const [(0, 1)],
        puedeTirar: false,
      );

      expect(boton(tester).onPressed, isNull);
    });

    testWidgets('esta apagado cuando el tablero ya esta resuelto',
        (tester) async {
      await montarVista(tester, tablero: Tablero.nivel1(), resuelto: true);

      expect(boton(tester).onPressed, isNull);
    });
  });

  group('lo que le avisa al bloc', () {
    testWidgets('el boton manda DadosTirados', (tester) async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      addTearDown(bloc.close);

      await montarVista(tester, tablero: tableroChico(Tipo.verde), bloc: bloc);

      bloc.add(ValoresInicialesProporcionados(tableroChico(Tipo.verde)));
      await tester.pump();
      expect((bloc.state as TableroEnJuego).dados, null);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      final juego = bloc.state as TableroEnJuego;
      expect(juego.dados?.primero, 3);
      expect(juego.dados?.segundo, 2);
    });

    testWidgets('tocar un dado manda NumeroElegido', (tester) async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      addTearDown(bloc.close);

      await montarVista(
        tester,
        tablero: tableroChico(Tipo.verde),
        dados: const Dados(3, 2),
        puedeTirar: false,
        bloc: bloc,
      );

      bloc.add(ValoresInicialesProporcionados(tableroChico(Tipo.verde)));
      await tester.pump();
      bloc.add(DadosTirados());
      await tester.pump();
      expect((bloc.state as TableroEnJuego).elegido, null);

      await tester.tap(find.widgetWithText(AnimatedContainer, '3'));
      await tester.pump();

      expect((bloc.state as TableroEnJuego).elegido, 3);
    });

    testWidgets('tocar una casilla resaltada manda NumeroColocado',
        (tester) async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      addTearDown(bloc.close);

      pantallaGrande(tester);
      await tester.pumpWidget(montar(const SizedBox(), bloc: bloc));

      bloc.add(ValoresInicialesProporcionados(tableroChico(Tipo.verde)));
      await tester.pump();
      bloc.add(DadosTirados());
      await tester.pump();
      bloc.add(NumeroElegido(3));
      await tester.pump();

      final juego = bloc.state as TableroEnJuego;
      expect(juego.posibles, [(0, 1)]);

      await tester.pumpWidget(montar(
        VistaJuego(
          tablero: juego.tablero,
          dados: juego.dados,
          elegido: juego.elegido,
          posibles: juego.posibles,
          puedeTirar: juego.puedeTirar,
        ),
        bloc: bloc,
      ));
      await tester.pumpAndSettle();

      await tester.tapAt(centroDeCelda(tester, 0, 1, filas: 1, columnas: 3));
      await tester.pump();

      expect(juego.tablero.valores[0][1], 3);
      final despues = bloc.state as TableroEnJuego;
      expect(despues.dados, null);
      expect(despues.elegido, null);
    });

    testWidgets('tocar una casilla que no esta resaltada no escribe nada',
        (tester) async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      addTearDown(bloc.close);

      final tablero = tableroChico(Tipo.verde);

      await montarVista(
        tester,
        tablero: tablero,
        dados: const Dados(3, 2),
        elegido: 3,
        posibles: const [(0, 1)],
        puedeTirar: false,
        bloc: bloc,
      );

      bloc.add(ValoresInicialesProporcionados(tablero));
      await tester.pump();
      bloc.add(DadosTirados());
      await tester.pump();
      bloc.add(NumeroElegido(3));
      await tester.pump();

      await tester.tapAt(centroDeCelda(tester, 0, 2, filas: 1, columnas: 3));
      await tester.pump();

      expect(tablero.valores[0][2], null);
    });
  });

  group('los paneles de reglas', () {
    testWidgets('se dibujan a los dos lados del tablero', (tester) async {
      await montarVista(tester);

      expect(find.text('≠'), findsNWidgets(2));
      expect(find.text('='), findsOneWidget);
      expect(find.text('XO'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });
  });
}