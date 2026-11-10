import 'dart:convert';

import 'package:http/http.dart' as http;

const String direccionServidor = String.fromEnvironment(
  'SERVIDOR',
  defaultValue: 'http://localhost:8080',
);

class Cuenta {
  final String usuario;
  final String token;

  const Cuenta({required this.usuario, required this.token});
}

class ErrorCuenta implements Exception {
  final String clave;
  final String mensaje;

  const ErrorCuenta(this.clave, this.mensaje);

  static const sinConexion = ErrorCuenta(
    'sin_conexion',
    'No se pudo conectar con el servidor.',
  );

  @override
  String toString() => 'ErrorCuenta($clave): $mensaje';
}

class ClienteCuentas {
  final Uri base;
  final http.Client _http;

  ClienteCuentas({Uri? base, http.Client? cliente})
    : base = base ?? Uri.parse(direccionServidor),
      _http = cliente ?? http.Client();

  Future<Cuenta> registrar(String usuario, String contrasena) =>
      _entrar('/registro', usuario, contrasena);

  Future<Cuenta> iniciarSesion(String usuario, String contrasena) =>
      _entrar('/sesion', usuario, contrasena);

  Future<void> cerrarSesion(String token) async {
    await _pedir('DELETE', '/sesion', token: token);
  }

  Future<void> borrarCuenta(String token, String contrasena) async {
    await _pedir(
      'DELETE',
      '/cuenta',
      token: token,
      cuerpo: {'contrasena': contrasena},
    );
  }

  void cerrar() => _http.close();

  Future<Cuenta> _entrar(String ruta, String usuario, String contrasena) async {
    final json = await _pedir(
      'POST',
      ruta,
      cuerpo: {'usuario': usuario, 'contrasena': contrasena},
    );
    return Cuenta(
      usuario: json['usuario'] as String,
      token: json['token'] as String,
    );
  }

  Future<Map<String, dynamic>> _pedir(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    String? token,
  }) async {
    final peticion = http.Request(metodo, base.resolve(ruta));
    peticion.headers['content-type'] = 'application/json';
    if (token != null) {
      peticion.headers['authorization'] = 'Bearer $token';
    }
    if (cuerpo != null) {
      peticion.body = jsonEncode(cuerpo);
    }

    final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(await _http.send(peticion));
    } on Exception {
      throw ErrorCuenta.sinConexion;
    }

    final json = _decodificar(respuesta.body);
    if (respuesta.statusCode >= 400) {
      throw ErrorCuenta(
        json['error'] as String? ?? 'desconocido',
        json['mensaje'] as String? ?? 'El servidor respondio con un error.',
      );
    }
    return json;
  }

  static Map<String, dynamic> _decodificar(String texto) {
    if (texto.isEmpty) {
      return {};
    }
    try {
      final json = jsonDecode(texto);
      return json is Map<String, dynamic> ? json : {};
    } on FormatException {
      return {};
    }
  }
}
