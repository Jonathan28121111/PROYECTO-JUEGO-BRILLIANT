import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'almacen_servidor_io.dart'
    if (dart.library.js_interop) 'almacen_servidor_web.dart'
    as almacen;

const String _definido = String.fromEnvironment('SERVIDOR');
const int puertoServidor = 8080;

String direccionPorDefecto() {
  if (_definido.isNotEmpty) return _definido;
  if (kIsWeb && Uri.base.host.isNotEmpty) {
    return 'http://${Uri.base.host}:$puertoServidor';
  }
  return 'http://localhost:$puertoServidor';
}

final ValueNotifier<String> servidorActual = ValueNotifier(
  direccionPorDefecto(),
);

Future<String?> Function() leerServidor = () =>
    almacen.leerPreferencia('servidor');
Future<void> Function(String) escribirServidor = (direccion) =>
    almacen.guardarPreferencia('servidor', direccion);

Future<void> cargarServidorGuardado() async {
  final guardado = await leerServidor();
  if (guardado != null) servidorActual.value = guardado;
}

Future<void> guardarServidor(String direccion) async {
  servidorActual.value = direccion;
  await escribirServidor(direccion);
}

String? normalizarServidor(String texto) {
  var limpio = texto.trim();
  if (limpio.isEmpty) return null;
  if (!limpio.contains('://')) limpio = 'http://$limpio';
  final uri = Uri.tryParse(limpio);
  if (uri == null ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  final conPuerto = uri.hasPort ? uri : uri.replace(port: puertoServidor);
  return Uri(
    scheme: conPuerto.scheme,
    host: conPuerto.host,
    port: conPuerto.port,
  ).toString();
}

String mostrarServidor(String direccion) =>
    Uri.tryParse(direccion)?.authority ?? direccion;

Future<bool> servidorResponde(String direccion) async {
  try {
    await http.get(Uri.parse(direccion)).timeout(const Duration(seconds: 4));
    return true;
  } catch (_) {
    return false;
  }
}
