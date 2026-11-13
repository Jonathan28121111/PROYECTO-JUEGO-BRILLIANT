import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tipo_zona.dart';
import 'package:pruebas_numeros/vista_juego.dart';

import 'ayudas_interfaz.dart';

void main() {
  Tablero tres(List<int?> valores) => Tablero(
    [
      [1, 1, 1],
    ],
    {1: Tipo.verde},
    [valores],
  );

  testWidgets('una zona incompleta conserva su color', (tester) async {
    pantallaGrande(tester);
    await tester.pumpWidget(montar(VistaJuego(tablero: tres([2, null, 4]))));

    expect(find.byKey(const Key('celda_apagada')), findsNothing);
  });

  testWidgets('al completar la zona se ve mas opaca', (tester) async {
    pantallaGrande(tester);
    await tester.pumpWidget(montar(VistaJuego(tablero: tres([2, 3, 4]))));

    expect(find.byKey(const Key('celda_apagada')), findsNWidgets(3));
  });

  testWidgets('se pueden apagar las zonas que completo otro', (tester) async {
    pantallaGrande(tester);
    await tester.pumpWidget(
      montar(VistaJuego(tablero: tres([2, null, 4]), zonasApagadas: const {1})),
    );

    expect(find.byKey(const Key('celda_apagada')), findsNWidgets(3));
  });
}
