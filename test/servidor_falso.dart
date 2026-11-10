import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pruebas_numeros/cliente_cuentas.dart';

class ServidorFalso {
  final Map<String, String> cuentas = {};
  final Map<String, String> sesiones = {};
  final List<String> rutas = [];
  bool caido = false;
  var _siguiente = 0;

  ClienteCuentas cliente() => ClienteCuentas(
    base: Uri.parse('http://servidor.falso'),
    cliente: MockClient(_contestar),
  );

  Future<http.Response> _contestar(http.Request peticion) async {
    if (caido) {
      throw http.ClientException('sin red');
    }
    rutas.add('${peticion.method} ${peticion.url.path}');
    final cuerpo = peticion.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(peticion.body) as Map<String, dynamic>;
    final token = peticion.headers['authorization']?.substring(7);
    final usuario = cuerpo['usuario'] as String?;
    final contrasena = cuerpo['contrasena'] as String?;

    switch ('${peticion.method} ${peticion.url.path}') {
      case 'POST /registro':
        if (cuentas.containsKey(usuario)) {
          return _error(409, 'nombre_ocupado', 'Ese usuario ya existe.');
        }
        if (contrasena!.length < 8) {
          return _error(400, 'contrasena_corta', 'La contrasena es corta.');
        }
        cuentas[usuario!] = contrasena;
        return _json(201, {'usuario': usuario, 'token': _abrir(usuario)});
      case 'POST /sesion':
        if (cuentas[usuario] != contrasena) {
          return _error(
            401,
            'credenciales_malas',
            'Usuario o contrasena incorrectos.',
          );
        }
        return _json(200, {'usuario': usuario, 'token': _abrir(usuario!)});
      case 'DELETE /sesion':
        sesiones.remove(token);
        return http.Response('', 204);
      case 'DELETE /cuenta':
        final dueno = sesiones[token];
        if (dueno == null) {
          return _error(401, 'sin_sesion', 'No hay sesion abierta.');
        }
        if (cuentas[dueno] != contrasena) {
          return _error(403, 'contrasena_mala', 'La contrasena no coincide.');
        }
        cuentas.remove(dueno);
        sesiones.removeWhere((_, u) => u == dueno);
        return http.Response('', 204);
    }
    return _error(404, 'no_existe', 'Ruta desconocida.');
  }

  String _abrir(String usuario) {
    final token = 'token-${_siguiente++}';
    sesiones[token] = usuario;
    return token;
  }

  static http.Response _json(int codigo, Map<String, dynamic> cuerpo) =>
      http.Response(jsonEncode(cuerpo), codigo);

  static http.Response _error(int codigo, String clave, String mensaje) =>
      _json(codigo, {'error': clave, 'mensaje': mensaje});
}
