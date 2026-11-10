import 'dados.dart';
import 'nivel.dart';
import 'tablero.dart';

enum FaseSala { espera, anclas, juego, terminada }

enum MotivoFinal { puntos, empate, rendicion, abandono, abandonoAmbos }

class JugadorEnLinea {
  final String usuario;
  final bool conectado;
  final bool listo;
  final int puntos;
  final bool jugoRonda;
  final bool terminado;

  /// Segundos que le quedan para volver si está desconectado.
  final int? segundosGracia;

  const JugadorEnLinea({
    required this.usuario,
    this.conectado = true,
    this.listo = false,
    this.puntos = 0,
    this.jugoRonda = false,
    this.terminado = false,
    this.segundosGracia,
  });

  bool get yaJugo => jugoRonda || terminado;

  factory JugadorEnLinea.deJson(Map<String, Object?> json) => JugadorEnLinea(
    usuario: json['usuario'] as String,
    conectado: json['conectado'] as bool? ?? true,
    listo: json['listo'] as bool? ?? false,
    puntos: json['puntos'] as int? ?? 0,
    jugoRonda: json['jugoRonda'] as bool? ?? false,
    terminado: json['terminado'] as bool? ?? false,
    segundosGracia: json['segundosGracia'] as int?,
  );
}

class ResultadoEnLinea {
  final String? ganador;
  final MotivoFinal motivo;

  const ResultadoEnLinea({required this.ganador, required this.motivo});
}

/// Lo que el servidor cuenta de una sala, visto por uno de sus jugadores.
class SalaEnLinea {
  final String codigo;
  final int nivel;
  final String anfitrion;
  final FaseSala fase;
  final int ronda;
  final Dados? dados;
  final int? segundosRonda;
  final List<JugadorEnLinea> jugadores;

  /// Las casillas que puso este jugador: sus anclas y sus jugadas.
  final Map<(int, int), int> mias;
  final ResultadoEnLinea? resultado;

  const SalaEnLinea({
    required this.codigo,
    required this.nivel,
    required this.anfitrion,
    this.fase = FaseSala.espera,
    this.ronda = 0,
    this.dados,
    this.segundosRonda,
    this.jugadores = const [],
    this.mias = const {},
    this.resultado,
  });

  factory SalaEnLinea.deJson(Map<String, Object?> json) {
    final dados = json['dados'] as List?;
    final resultado = json['resultado'] as Map<String, Object?>?;
    return SalaEnLinea(
      codigo: json['codigo'] as String,
      nivel: json['nivel'] as int,
      anfitrion: json['anfitrion'] as String,
      fase: FaseSala.values.byName(json['fase'] as String),
      ronda: json['ronda'] as int? ?? 0,
      dados: dados == null ? null : Dados(dados[0] as int, dados[1] as int),
      segundosRonda: json['segundosRonda'] as int?,
      jugadores: [
        for (final j in (json['jugadores'] as List? ?? const []))
          JugadorEnLinea.deJson(j as Map<String, Object?>),
      ],
      mias: {
        for (final c in (json['mias'] as List? ?? const []))
          ((c as List)[0] as int, c[1] as int): c[2] as int,
      },
      resultado: resultado == null
          ? null
          : ResultadoEnLinea(
              ganador: resultado['ganador'] as String?,
              motivo: MotivoFinal.values.byName(resultado['motivo'] as String),
            ),
    );
  }

  Nivel get datosNivel => nivelesOficiales.firstWhere(
    (n) => n.numero == nivel,
    orElse: () => nivel1,
  );

  bool esAnfitrion(String usuario) =>
      anfitrion.toLowerCase() == usuario.toLowerCase();

  JugadorEnLinea? yo(String usuario) => _buscar(usuario, mismo: true);
  JugadorEnLinea? rival(String usuario) => _buscar(usuario, mismo: false);

  JugadorEnLinea? _buscar(String usuario, {required bool mismo}) {
    for (final j in jugadores) {
      if ((j.usuario.toLowerCase() == usuario.toLowerCase()) == mismo) {
        return j;
      }
    }
    return null;
  }
}

/// El tablero del nivel con las casillas ya puestas.
Tablero tableroCon(Nivel nivel, Map<(int, int), int> casillas) {
  final tablero = Tablero.deNivel(nivel);
  casillas.forEach((celda, numero) {
    final (fila, columna) = celda;
    if (fila < tablero.valores.length &&
        columna < tablero.valores[fila].length) {
      tablero.valores[fila][columna] = numero;
    }
  });
  return tablero;
}

/// Los puntajes de cada zona en orden de llegada (`{"1": [8, 6, 4]}`): el
/// servidor da el primero a quien completa la zona antes que su rival.
Map<String, List<int>> tablaDePuntos(Nivel nivel) => {
  for (final zona in Tablero.deNivel(nivel).zonas()) '${zona.id}': zona.puntos,
};

/// Las zonas completas y válidas del tablero, para que el servidor sepa en
/// qué ronda se completó cada una.
List<int> zonasCompletas(Tablero tablero) => [
  for (final zona in tablero.zonasCompletas()) zona.id,
];

/// Si con esos dados hay alguna casilla donde escribir.
bool hayJugadaCon(Tablero tablero, Dados dados) =>
    tablero.celdasPosibles(dados.primero, dados.segundo).isNotEmpty ||
    tablero.celdasPosibles(dados.segundo, dados.primero).isNotEmpty;
