import 'dart:async';

import 'package:pruebas_numeros/conexion_juego.dart';

/// Hace de servidor de partidas: guarda lo que manda el cliente y le
/// contesta lo que la prueba quiera. Puede tirar la conexión o negarse a
/// abrirla.
class ServidorJuegoFalso {
  final List<ConexionFalsa> conexiones = [];

  /// Si es true, los próximos intentos de conexión fallan.
  bool caido = false;

  /// Si es true, contesta solo el saludo con la bienvenida.
  final bool saludarSolo;
  final String usuario;

  ServidorJuegoFalso({this.saludarSolo = true, this.usuario = 'ana'});

  int intentos = 0;

  Future<ConexionJuego> abrir() async {
    intentos++;
    if (caido) throw Exception('servidor caído');
    final conexion = ConexionFalsa(this);
    conexiones.add(conexion);
    return conexion;
  }

  ConexionFalsa get actual => conexiones.last;

  /// Todo lo que mandó el cliente, por todas sus conexiones.
  List<Map<String, Object?>> get recibidos => [
    for (final c in conexiones) ...c.enviados,
  ];

  List<String> get tipos => [for (final m in recibidos) m['tipo'] as String];

  void mandar(Map<String, Object?> mensaje) => actual.recibir(mensaje);
}

class ConexionFalsa implements ConexionJuego {
  final ServidorJuegoFalso servidor;
  final _entrada = StreamController<Map<String, Object?>>();
  final List<Map<String, Object?>> enviados = [];
  bool cerrada = false;

  ConexionFalsa(this.servidor);

  @override
  Stream<Map<String, Object?>> get mensajes => _entrada.stream;

  @override
  void enviar(Map<String, Object?> mensaje) {
    if (cerrada) return;
    enviados.add(mensaje);
    if (servidor.saludarSolo && mensaje['tipo'] == 'hola') {
      scheduleMicrotask(() {
        recibir({'tipo': 'bienvenida', 'usuario': servidor.usuario});
      });
    }
  }

  void recibir(Map<String, Object?> mensaje) {
    if (!cerrada) _entrada.add(mensaje);
  }

  /// Simula que se cortó la red.
  void caer() {
    if (cerrada) return;
    cerrada = true;
    _entrada.close();
  }

  @override
  Future<void> cerrar() async {
    if (cerrada) return;
    cerrada = true;
    await _entrada.close();
  }
}

/// Un estado de sala como el que manda el servidor.
Map<String, Object?> estadoSala({
  String codigo = 'ABC234',
  int nivel = 1,
  String anfitrion = 'ana',
  String fase = 'espera',
  int ronda = 0,
  List<int>? dados,
  int? segundosRonda,
  List<Map<String, Object?>>? jugadores,
  List<List<int>> mias = const [],
  Map<String, Object?>? resultado,
}) => {
  'tipo': 'estado',
  'codigo': codigo,
  'nivel': nivel,
  'anfitrion': anfitrion,
  'fase': fase,
  'ronda': ronda,
  'dados': dados,
  'segundosRonda': segundosRonda,
  'jugadores': jugadores ?? [jugador('ana')],
  'mias': mias,
  'resultado': resultado,
};

Map<String, Object?> jugador(
  String usuario, {
  bool conectado = true,
  bool listo = false,
  int puntos = 0,
  bool jugoRonda = false,
  bool terminado = false,
  int? segundosGracia,
}) => {
  'usuario': usuario,
  'conectado': conectado,
  'listo': listo,
  'puntos': puntos,
  'jugoRonda': jugoRonda,
  'terminado': terminado,
  'segundosGracia': segundosGracia,
};
