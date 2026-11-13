import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/main.dart';
import 'package:pruebas_numeros/pantalla_cuenta.dart';
import 'package:pruebas_numeros/pantalla_niveles.dart';
import 'package:pruebas_numeros/pantalla_registro.dart';

import 'ayudas_interfaz.dart';
import 'servidor_falso.dart';

void main() {
  late ServidorFalso servidor;

  setUp(() => servidor = ServidorFalso());

  Future<void> abrir(WidgetTester tester) async {
    pantallaGrande(tester);
    await tester.pumpWidget(JuegoBrilliantApp(cliente: servidor.cliente()));
    await tester.pumpAndSettle();
  }

  Future<void> escribir(
    WidgetTester tester,
    String usuario,
    String contrasena,
  ) async {
    await tester.enterText(find.byKey(const Key('campo_usuario')), usuario);
    await tester.enterText(
      find.byKey(const Key('campo_contrasena')),
      contrasena,
    );
  }

  Future<void> crearCuenta(
    WidgetTester tester,
    String usuario,
    String contrasena, {
    String? confirmar,
  }) async {
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('registro_usuario')), usuario);
    await tester.enterText(
      find.byKey(const Key('registro_contrasena')),
      contrasena,
    );
    await tester.enterText(
      find.byKey(const Key('registro_confirmar')),
      confirmar ?? contrasena,
    );
    await tester.tap(find.byKey(const Key('boton_crear')));
    await tester.pumpAndSettle();
  }

  testWidgets('la app arranca pidiendo la cuenta', (tester) async {
    await abrir(tester);

    expect(find.byType(PantallaCuenta), findsOneWidget);
    expect(find.text('Inicio de sesión'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('crear cuenta abre su propia pagina', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaRegistro), findsOneWidget);
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Inicio de sesión'), findsNothing);
  });

  testWidgets('volver regresa al inicio de sesion', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('volver_inicio')));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaRegistro), findsNothing);
    expect(find.text('Inicio de sesión'), findsOneWidget);
  });

  testWidgets('crear cuenta lleva al selector de niveles', (tester) async {
    await abrir(tester);

    await crearCuenta(tester, 'jonathan', 'contrasena123');

    expect(find.byType(PantallaRegistro), findsNothing);
    expect(find.byType(PantallaNiveles), findsOneWidget);
    expect(servidor.cuentas, contains('jonathan'));
  });

  testWidgets('si las contrasenas no coinciden no llama al servidor', (
    tester,
  ) async {
    await abrir(tester);

    await crearCuenta(
      tester,
      'jonathan',
      'contrasena123',
      confirmar: 'otra-cosa',
    );

    expect(find.byType(PantallaRegistro), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(servidor.rutas, isEmpty);
  });

  testWidgets('el error del inicio de sesion no se arrastra al registro', (
    tester,
  ) async {
    await abrir(tester);
    await escribir(tester, 'jonathan', 'mala');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Usuario o contrasena incorrectos.'), findsOneWidget);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Usuario o contrasena incorrectos.'), findsNothing);
  });

  testWidgets('entrar con una cuenta existente', (tester) async {
    servidor.cuentas['jonathan'] = 'contrasena123';
    await abrir(tester);

    await escribir(tester, 'jonathan', 'contrasena123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaNiveles), findsOneWidget);
  });

  testWidgets('muestra el error del servidor', (tester) async {
    await abrir(tester);

    await escribir(tester, 'jonathan', 'mala');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaCuenta), findsOneWidget);
    expect(find.text('Usuario o contrasena incorrectos.'), findsOneWidget);
  });

  testWidgets('se puede jugar sin cuenta', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Jugar sin cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaNiveles), findsOneWidget);
    expect(servidor.rutas, isEmpty);
  });

  testWidgets('cerrar sesion desde el menu vuelve a la cuenta', (tester) async {
    await abrir(tester);
    await crearCuenta(tester, 'jonathan', 'contrasena123');

    await tester.tap(find.byKey(const Key('menu_cuenta')));
    await tester.pumpAndSettle();
    expect(find.text('jonathan'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaCuenta), findsOneWidget);
    expect(servidor.rutas, contains('DELETE /sesion'));
  });
}
