import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'cliente_cuentas.dart';

abstract interface class ConexionJuego {
  Stream<Map<String, Object?>> get mensajes;

  void enviar(Map<String, Object?> mensaje);

  Future<void> cerrar();
}

typedef AbrirConexion = Future<ConexionJuego> Function();

Uri direccionJuego([String base = direccionServidor]) {
  final http = Uri.parse(base);
  return http.replace(
    scheme: http.scheme == 'https' ? 'wss' : 'ws',
    path: '${http.path.replaceAll(RegExp(r'/$'), '')}/juego',
  );
}

Future<ConexionJuego> abrirWebSocket({
  Uri? direccion,
  Duration espera = const Duration(seconds: 8),
}) async {
  final canal = WebSocketChannel.connect(direccion ?? direccionJuego());
  try {
    await canal.ready.timeout(espera);
  } catch (_) {
    unawaited(canal.sink.close().catchError((_) {}));
    rethrow;
  }
  return _ConexionWebSocket(canal);
}

class _ConexionWebSocket implements ConexionJuego {
  final WebSocketChannel _canal;
  bool _cerrada = false;

  _ConexionWebSocket(this._canal);

  @override
  late final Stream<Map<String, Object?>> mensajes = _canal.stream
      .map((dato) => dato is String ? jsonDecode(dato) : null)
      .where((json) => json is Map<String, Object?>)
      .cast<Map<String, Object?>>()
      .handleError((Object _) {});

  @override
  void enviar(Map<String, Object?> mensaje) {
    if (_cerrada) return;
    try {
      _canal.sink.add(jsonEncode(mensaje));
    } catch (_) {}
  }

  @override
  Future<void> cerrar() async {
    if (_cerrada) return;
    _cerrada = true;
    await _canal.sink
        .close()
        .timeout(const Duration(seconds: 3), onTimeout: () {})
        .catchError((_) {});
  }
}
