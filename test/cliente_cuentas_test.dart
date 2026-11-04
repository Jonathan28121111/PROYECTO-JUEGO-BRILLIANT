import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pruebas_numeros/cliente_cuentas.dart';

import 'servidor_falso.dart';

void main() {
  late ServidorFalso servidor;
  late ClienteCuentas cliente;

  setUp(() {
    servidor = ServidorFalso();
    cliente = servidor.cliente();
  });

  test('registrar devuelve la cuenta con su token', () async {
    final cuenta = await cliente.registrar('jonathan', 'contrasena123');

    expect(cuenta.usuario, 'jonathan');
    expect(cuenta.token, isNotEmpty);
    expect(servidor.cuentas, contains('jonathan'));
  });

  test('iniciar sesion con la contrasena correcta', () async {
    servidor.cuentas['jonathan'] = 'contrasena123';

    final cuenta = await cliente.iniciarSesion('jonathan', 'contrasena123');

    expect(cuenta.usuario, 'jonathan');
  });

  test('convierte la respuesta de error en ErrorCuenta', () async {
    servidor.cuentas['jonathan'] = 'contrasena123';

    expect(
      () => cliente.iniciarSesion('jonathan', 'equivocada'),
      throwsA(
        isA<ErrorCuenta>()
            .having((e) => e.clave, 'clave', 'credenciales_malas')
            .having((e) => e.mensaje, 'mensaje', contains('incorrectos')),
      ),
    );
  });

  test('sin red avisa que no hay conexion', () async {
    servidor.caido = true;

    expect(
      () => cliente.registrar('jonathan', 'contrasena123'),
      throwsA(
        isA<ErrorCuenta>().having((e) => e.clave, 'clave', 'sin_conexion'),
      ),
    );
  });

  test('cerrar sesion manda el token', () async {
    final cuenta = await cliente.registrar('jonathan', 'contrasena123');

    await cliente.cerrarSesion(cuenta.token);

    expect(servidor.sesiones, isNot(contains(cuenta.token)));
  });

  test('borrar cuenta manda el token y la contrasena', () async {
    final cuenta = await cliente.registrar('jonathan', 'contrasena123');

    await cliente.borrarCuenta(cuenta.token, 'contrasena123');

    expect(servidor.cuentas, isEmpty);
  });

  test('manda JSON con las cabeceras correctas', () async {
    late http.Request vista;
    final espia = ClienteCuentas(
      base: Uri.parse('http://servidor.falso'),
      cliente: MockClient((peticion) async {
        vista = peticion;
        return http.Response('', 204);
      }),
    );

    await espia.borrarCuenta('abc', 'contrasena123');

    expect(vista.url.toString(), 'http://servidor.falso/cuenta');
    expect(vista.method, 'DELETE');
    expect(vista.headers['authorization'], 'Bearer abc');
    expect(vista.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(vista.body), {'contrasena': 'contrasena123'});
  });

  test('una respuesta de error sin JSON no revienta', () async {
    final roto = ClienteCuentas(
      base: Uri.parse('http://servidor.falso'),
      cliente: MockClient((_) async => http.Response('<html>', 502)),
    );

    expect(
      () => roto.iniciarSesion('a', 'b'),
      throwsA(
        isA<ErrorCuenta>().having((e) => e.clave, 'clave', 'desconocido'),
      ),
    );
  });
}
