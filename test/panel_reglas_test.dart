import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/colores.dart';
import 'package:pruebas_numeros/nivel.dart';
import 'package:pruebas_numeros/panel_reglas.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

import 'ayudas_interfaz.dart';

void main() {
  Future<void> montarPanel(WidgetTester tester, List<Regla> reglas) async {
    pantallaGrande(tester);
    await tester.pumpWidget(montar(
      Center(child: SizedBox(width: 150, height: 900, child: PanelReglas(reglas: reglas))),
    ));
    await tester.pumpAndSettle();
  }

  group('el panel de la izquierda', () {
    testWidgets('trae rojo, amarillo y azul', (tester) async {
      await montarPanel(tester, reglasIzquierda);

      expect(find.text('Todos distintos'), findsOneWidget);
      expect(find.text('Todos distintos,\ncasillas separadas'), findsOneWidget);
      expect(find.text('Todos iguales'), findsOneWidget);
    });

    testWidgets('rojo y amarillo comparten el simbolo', (tester) async {
      await montarPanel(tester, reglasIzquierda);

      expect(find.text('≠'), findsNWidgets(2));
      expect(find.text('='), findsOneWidget);
    });
  });

  group('el panel de la derecha', () {
    testWidgets('trae morado y verde', (tester) async {
      await montarPanel(tester, reglasDerecha);

      expect(find.text('XO'), findsOneWidget);
      expect(find.text('Solo dos valores'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(find.text('Cualquier número'), findsOneWidget);
    });
  });

  group('los puntajes', () {
    testWidgets('una tarjeta muestra los tres puntos de su color',
        (tester) async {
      await montarPanel(tester, const [Regla(Tipo.azul, '=', 'Todos iguales')]);

      expect(puntosPorTipo[Tipo.azul], [7, 5, 3]);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('los puntos salen del modelo, no estan escritos a mano',
        (tester) async {
      for (final tipo in Tipo.values) {
        await montarPanel(tester, [Regla(tipo, 'x', 'prueba')]);

        for (final punto in puntosPorTipo[tipo]!) {
          expect(
            find.text('$punto'),
            findsWidgets,
            reason: 'la tarjeta $tipo no muestra el $punto',
          );
        }
      }
    });
    test('todos los colores tienen sus tres puntajes declarados', () {
      for (final tipo in Tipo.values) {
        expect(puntosPorTipo[tipo], isNotNull, reason: 'falta $tipo');
        expect(puntosPorTipo[tipo], hasLength(3), reason: '$tipo mal declarado');
      }
    });

    test('los puntajes van de mayor a menor', () {
      // Primero, segundo y tercer jugador que completa la zona.
      for (final tipo in Tipo.values) {
        final puntos = puntosPorTipo[tipo]!;
        expect(puntos[0], greaterThan(puntos[1]), reason: '$tipo');
        expect(puntos[1], greaterThan(puntos[2]), reason: '$tipo');
      }
    });
  });

  group('el cuadrito del simbolo', () {
    testWidgets('se pinta del color de la regla', (tester) async {
      await montarPanel(tester, const [Regla(Tipo.morado, 'XO', 'prueba')]);

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == colorDe(Tipo.morado),
        ),
        findsOneWidget,
      );
    });

    testWidgets('el texto del simbolo contrasta con el fondo', (tester) async {
      await montarPanel(tester, const [Regla(Tipo.amarillo, '≠', 'prueba')]);

      final texto = tester.widget<Text>(find.text('≠'));
      expect(texto.style?.color, colorTextoSobre(colorDe(Tipo.amarillo)));
    });
  });

  group('no desborda', () {
    testWidgets('las cinco reglas juntas caben en una columna angosta',
        (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(montar(
        Center(
          child: SizedBox(
            width: 150,
            height: 300, 
            child: PanelReglas(
              reglas: const [...reglasIzquierda, ...reglasDerecha],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('reglasDe', () {
    test('reparte las reglas del nivel entre los dos paneles', () {
      final (izquierda, derecha) = reglasDe(nivel1);

      expect(izquierda, hasLength(3));
      expect(derecha, hasLength(2));
    });

    test('el nivel 4 reparte sus siete tipos', () {
      final (izquierda, derecha) = reglasDe(nivel4);

      expect(izquierda, hasLength(4));
      expect(derecha, hasLength(3));
    });

    test('cada tipo del nivel aparece una sola vez', () {
      for (final nivel in nivelesOficiales) {
        final (izquierda, derecha) = reglasDe(nivel);
        final tipos = [...izquierda, ...derecha].map((r) => r.tipo).toList();

        expect(tipos.toSet(), nivel.tiposUsados.toSet(),
            reason: 'nivel ${nivel.numero}');
        expect(tipos.toSet(), hasLength(tipos.length),
            reason: 'nivel ${nivel.numero}: un tipo repetido');
      }
    });

    test('no mete reglas de tipos que el nivel no usa', () {
      final (izquierda, derecha) = reglasDe(nivel1);
      final tipos = [...izquierda, ...derecha].map((r) => r.tipo);

      expect(tipos, isNot(contains(Tipo.blanco)));
      expect(tipos, isNot(contains(Tipo.naranja1a3)));
      expect(tipos, isNot(contains(Tipo.naranja4a6)));
    });

    test('el nivel 4 si trae las dos zonas de rango', () {
      final (izquierda, derecha) = reglasDe(nivel4);
      final tipos = [...izquierda, ...derecha].map((r) => r.tipo);

      expect(tipos, contains(Tipo.naranja1a3));
      expect(tipos, contains(Tipo.naranja4a6));
    });
  });

  group('los puntos salen del nivel', () {
    testWidgets('el verde vale distinto en el nivel 3 que en el 1',
        (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(montar(
        Center(
          child: SizedBox(
            width: 150,
            height: 900,
            child: PanelReglas(
              reglas: const [Regla(Tipo.verde, '?', 'Cualquier numero')],
              puntos: nivel3.puntos,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(nivel3.puntosDe(Tipo.verde), [8, 6, 4]);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('sin puntos del nivel usa los de omision', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(montar(
        Center(
          child: SizedBox(
            width: 150,
            height: 900,
            child: PanelReglas(
              reglas: const [Regla(Tipo.azul, '=', 'Todos iguales')],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('el modo compacto', () {
    Future<double?> tamanoDelSimbolo(
      WidgetTester tester,
      List<Regla> reglas,
      String simbolo,
    ) async {
      pantallaGrande(tester);
      await tester.pumpWidget(montar(
        Center(
          child: SizedBox(
            width: 150,
            height: 900,
            child: PanelReglas(reglas: reglas),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return tester.widget<Text>(find.text(simbolo)).style?.fontSize;
    }

    testWidgets('con tres reglas o menos las tarjetas van normales',
        (tester) async {
      final tamano = await tamanoDelSimbolo(
        tester,
        const [
          Regla(Tipo.azul, '=', 'a'),
          Regla(Tipo.verde, '?', 'b'),
          Regla(Tipo.rojo, 'x', 'c'),
        ],
        '=',
      );

      expect(tamano, 24);
    });

    testWidgets('con cuatro o mas se encogen', (tester) async {
      final tamano = await tamanoDelSimbolo(
        tester,
        const [
          Regla(Tipo.azul, '=', 'a'),
          Regla(Tipo.verde, '?', 'b'),
          Regla(Tipo.rojo, 'x', 'c'),
          Regla(Tipo.morado, 'y', 'd'),
        ],
        '=',
      );

      expect(tamano, 19);
    });

    testWidgets('las cuatro reglas del nivel 4 caben sin desbordar',
        (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(montar(
        Center(
          child: SizedBox(
            width: 150,
            height: 420,
            child: PanelReglas(
              reglas: reglasDe(nivel4).$1,
              puntos: nivel4.puntos,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
