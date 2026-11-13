import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/dado_animado.dart';
import 'package:pruebas_numeros/dados.dart';
import 'package:pruebas_numeros/nivel.dart';
import 'package:pruebas_numeros/sonidos.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/vista_juego.dart';

import 'ayudas_interfaz.dart';
import 'flutter_test_config.dart';

void main() {
  setUp(() {
    sonidosTocados.clear();
    Sonidos.activos.value = true;
  });

  test('con los sonidos apagados no suena nada', () {
    Sonidos.activos.value = false;

    Sonidos.tocar(Sonido.colocar);

    expect(sonidosTocados, isEmpty);
  });

  test('cada sonido apunta a un archivo del pack', () {
    Sonidos.tocar(Sonido.zonaCompletada);

    expect(sonidosTocados, ['sonidos/zona_completada.m4a']);
  });

  testWidgets('un sonido con retraso suena despues', (tester) async {
    Sonidos.tocar(
      Sonido.zonaCompletada,
      retraso: const Duration(milliseconds: 180),
    );
    expect(sonidosTocados, isEmpty);

    await tester.pump(const Duration(milliseconds: 200));

    expect(sonidosTocados, ['sonidos/zona_completada.m4a']);
  });

  testWidgets('elegir un dado suena', (tester) async {
    pantallaGrande(tester);
    final tablero = Tablero.deNivel(nivel1);
    await tester.pumpWidget(
      montar(
        VistaJuego(
          tablero: tablero,
          dados: const Dados(3, 5),
          puedeTirar: false,
          alElegir: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('dado_1')));
    await tester.pump();

    expect(sonidosTocados, ['sonidos/elegir_dado.m4a']);
  });

  testWidgets('al salir una tirada nueva suenan los dados una vez', (
    tester,
  ) async {
    Widget dados(Object tirada) => MaterialApp(
      home: Row(
        children: [
          DadoAnimado(valor: 3, tirada: tirada, sonarAlRodar: true),
          DadoAnimado(valor: 5, tirada: tirada),
        ],
      ),
    );
    await tester.pumpWidget(dados(Object()));
    await tester.pumpWidget(dados(Object()));
    await tester.pumpAndSettle();

    expect(sonidosTocados, hasLength(1));
    expect(sonidosTocados.single, 'sonidos/tirar_dados.m4a');
  });
}
