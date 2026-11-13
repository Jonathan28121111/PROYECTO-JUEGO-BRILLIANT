import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/cliente_cuentas.dart';
import 'package:pruebas_numeros/conexion_juego.dart';
import 'package:pruebas_numeros/pantalla_cuenta.dart';
import 'package:pruebas_numeros/servidor.dart';
import 'package:pruebas_numeros/sesion_bloc.dart';

import 'servidor_falso.dart';

void main() {
  late String? guardado;
  late String original;

  setUp(() {
    original = servidorActual.value;
    guardado = null;
    escribirServidor = (d) async => guardado = d;
  });

  tearDown(() => servidorActual.value = original);

  group('normalizar la direccion', () {
    test('una IP sola lleva http y el puerto 8080', () {
      expect(normalizarServidor(' 10.22.17.151 '), 'http://10.22.17.151:8080');
    });

    test('respeta el puerto y el esquema que se escriben', () {
      expect(
        normalizarServidor('https://juego.ejemplo:9000/'),
        'https://juego.ejemplo:9000',
      );
    });

    test('rechaza lo vacio o lo que no es una direccion', () {
      expect(normalizarServidor(''), isNull);
      expect(normalizarServidor('ftp://algo'), isNull);
    });
  });

  test('el cliente y las partidas usan el servidor elegido', () {
    servidorActual.value = 'http://10.0.0.5:8080';

    expect(ClienteCuentas().base.toString(), 'http://10.0.0.5:8080');
    expect(direccionJuego().toString(), 'ws://10.0.0.5:8080/juego');
  });

  Future<void> abrirDialogo(
    WidgetTester tester, {
    required bool responde,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DialogoServidor(probar: (_) async => responde),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('campo_servidor')),
      '10.22.17.151',
    );
    await tester.tap(find.byKey(const Key('guardar_servidor')));
    await tester.pumpAndSettle();
  }

  testWidgets('si el servidor responde, se guarda', (tester) async {
    await abrirDialogo(tester, responde: true);

    expect(servidorActual.value, 'http://10.22.17.151:8080');
    expect(guardado, 'http://10.22.17.151:8080');
    expect(find.byType(DialogoServidor), findsNothing);
  });

  testWidgets('si no responde, avisa y deja guardar igual', (tester) async {
    await abrirDialogo(tester, responde: false);

    expect(find.textContaining('No encontré el servidor'), findsOneWidget);
    expect(guardado, isNull);

    await tester.tap(find.byKey(const Key('guardar_igual')));
    await tester.pumpAndSettle();

    expect(guardado, 'http://10.22.17.151:8080');
  });

  testWidgets('el inicio de sesion muestra el servidor', (tester) async {
    servidorActual.value = 'http://10.22.17.151:8080';
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SesionBloc(ServidorFalso().cliente()),
          child: const PantallaCuenta(),
        ),
      ),
    );

    expect(find.text('Servidor: 10.22.17.151:8080'), findsOneWidget);
    expect(find.byKey(const Key('cambiar_servidor')), findsOneWidget);
  });
}
