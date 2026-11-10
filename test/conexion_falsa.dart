import 'dart:async';

import 'package:pruebas_numeros/conexion_juego.dart';

class ServidorJuegoFalso {
  final List<ConexionFalsa> conexiones = [];

  bool caido = false;

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
