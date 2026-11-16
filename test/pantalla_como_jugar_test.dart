import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/pantalla_como_jugar.dart';
import 'package:pruebas_numeros/pantalla_juego.dart';

import 'ayudas_interfaz.dart';

void main() {
  testWidgets('explica los pasos, las reglas y el modo en linea', (
    tester,
  ) async {
    pantallaGrande(tester);
    await tester.pumpWidget(const MaterialApp(home: PantallaComoJugar()));

    expect(find.text('Pon tus anclas'), findsOneWidget);
    expect(find.text('Elige un dado'), findsOneWidget);
    expect(find.text('Escríbelo junto al otro número'), findsOneWidget);
    expect(find.text('La regla de cada color'), findsOneWidget);
    expect(find.textContaining('Roja: Ningún número se repite'), findsOne);
    expect(find.text('Jugar en línea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en el celular cabe sin desbordarse', (tester) async {
    pantallaGrande(tester, tamano: const Size(360, 640));
    await tester.pumpWidget(const MaterialApp(home: PantallaComoJugar()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('se abre desde la barra y desde la portada', (tester) async {
    pantallaGrande(tester);
    await tester.pumpWidget(
      const MaterialApp(home: PantallaJuego(tarjetaEnLinea: SizedBox())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('enlace_como_jugar')));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaComoJugar), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_como_jugar')));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaComoJugar), findsOneWidget);
  });
}
