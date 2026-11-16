import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tablero_bloc.dart';
import 'package:pruebas_numeros/tipo_zona.dart';
import 'package:pruebas_numeros/vista_juego.dart';

import 'ayudas_interfaz.dart';

void main() {
  Tablero atorado() => Tablero(
    [
      [1, 1, 1],
    ],
    {1: Tipo.azul},
    [
      [1, null, 2],
    ],
  );

  test('si ya no hay ninguna jugada posible la partida termina', () async {
    final bloc = TableroBloc();

    bloc.add(ValoresInicialesProporcionados(atorado()));
    await Future<void>.delayed(Duration.zero);

    final estado = bloc.state;
    expect(estado, isA<TableroResuelto>());
    expect((estado as TableroResuelto).completo, isFalse);
    await bloc.close();
  });

  testWidgets('al terminar hay botones para salir o jugar otra vez', (
    tester,
  ) async {
    pantallaGrande(tester);
    var salio = false;
    var otraVez = false;
    await tester.pumpWidget(
      montar(
        VistaJuego(
          tablero: atorado(),
          resuelto: true,
          sinJugadas: true,
          conBotonTirar: false,
          alSalir: () => salio = true,
          alJugarOtraVez: () => otraVez = true,
        ),
      ),
    );

    expect(find.textContaining('Ya no queda ninguna jugada posible'), findsOne);
    await tester.tap(find.byKey(const Key('boton_salir_final')));
    await tester.tap(find.byKey(const Key('boton_otra_vez')));

    expect(salio, isTrue);
    expect(otraVez, isTrue);
  });
}
