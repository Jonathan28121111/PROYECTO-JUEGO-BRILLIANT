import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'conexion_juego.dart';
import 'sala_en_linea.dart';
import 'tablero.dart';

// ---------------------------------------------------------------------------
// Eventos

sealed class PartidaEvent {}

/// Abre la conexión (o la vuelve a abrir tras una caída).
class Conectar extends PartidaEvent {}

/// Reintenta ya, sin esperar a que se cumpla la espera.
class ReintentarAhora extends PartidaEvent {}

class CrearSala extends PartidaEvent {
  final int nivel;
  CrearSala(this.nivel);
}

class UnirseSala extends PartidaEvent {
  final String codigo;
  UnirseSala(this.codigo);
}

/// El jugador volvió a escribir en el campo del código: el error se va.
class CorregirCodigo extends PartidaEvent {}

class SalirSala extends PartidaEvent {}

class EmpezarPartida extends PartidaEvent {}

class EnviarAnclas extends PartidaEvent {
  final Tablero tablero;
  EnviarAnclas(this.tablero);
}

class ColocarNumero extends PartidaEvent {
  final int fila;
  final int columna;
  final int numero;
  ColocarNumero(this.fila, this.columna, this.numero);
}

class Rendirse extends PartidaEvent {}

class _MensajeRecibido extends PartidaEvent {
  final Map<String, Object?> mensaje;
  _MensajeRecibido(this.mensaje);
}

class _ConexionPerdida extends PartidaEvent {
  final ConexionJuego conexion;
  _ConexionPerdida(this.conexion);
}

// ---------------------------------------------------------------------------
// Estado

enum EstadoConexion { conectando, conectado, reconectando, expulsado }

/// Una jugada que ya se ve en el tablero pero el servidor no ha confirmado.
class JugadaPendiente {
  final int ronda;
  final int fila;
  final int columna;
  final int numero;
  final int puntos;
  final bool terminado;

  const JugadaPendiente({
    required this.ronda,
    required this.fila,
    required this.columna,
    required this.numero,
    required this.puntos,
    required this.terminado,
  });

  Map<String, Object?> get mensaje => {
    'tipo': 'jugada',
    'ronda': ronda,
    'fila': fila,
    'columna': columna,
    'numero': numero,
    'puntos': puntos,
    'terminado': terminado,
  };
}

class PartidaState {
  final EstadoConexion conexion;
  final SalaEnLinea? sala;
  final bool cargando;
  final bool anclasEnviadas;
  final JugadaPendiente? pendiente;

  /// Intentos de reconexión seguidos que han fallado.
  final int intentos;
  final int? segundosParaReintentar;

  /// Un aviso para mostrar una vez. [numeroAviso] cambia con cada uno.
  final String? aviso;
  final bool avisoEsError;
  final int numeroAviso;

  /// Por qué el servidor nos sacó (otra ventana, sesión vencida...).
  final String? motivoExpulsion;

  /// Por qué no se pudo entrar con el código. Va debajo del campo.
  final String? errorCodigo;

  const PartidaState({
    this.conexion = EstadoConexion.conectando,
    this.sala,
    this.cargando = false,
    this.anclasEnviadas = false,
    this.pendiente,
    this.intentos = 0,
    this.segundosParaReintentar,
    this.aviso,
    this.avisoEsError = false,
    this.numeroAviso = 0,
    this.motivoExpulsion,
    this.errorCodigo,
  });

  bool get conectado => conexion == EstadoConexion.conectado;

  /// Las casillas propias que hay que dibujar, contando la jugada pendiente.
  Map<(int, int), int> get casillas {
    final sala = this.sala;
    if (sala == null) return const {};
    final jugada = pendiente;
    if (jugada == null) return sala.mias;
    return {...sala.mias, (jugada.fila, jugada.columna): jugada.numero};
  }

  PartidaState copyWith({
    EstadoConexion? conexion,
    SalaEnLinea? Function()? sala,
    bool? cargando,
    bool? anclasEnviadas,
    JugadaPendiente? Function()? pendiente,
    int? intentos,
    int? Function()? segundosParaReintentar,
    String? motivoExpulsion,
    String? Function()? errorCodigo,
  }) => PartidaState(
    conexion: conexion ?? this.conexion,
    sala: sala == null ? this.sala : sala(),
    cargando: cargando ?? this.cargando,
    anclasEnviadas: anclasEnviadas ?? this.anclasEnviadas,
    pendiente: pendiente == null ? this.pendiente : pendiente(),
    intentos: intentos ?? this.intentos,
    segundosParaReintentar: segundosParaReintentar == null
        ? this.segundosParaReintentar
        : segundosParaReintentar(),
    aviso: aviso,
    avisoEsError: avisoEsError,
    numeroAviso: numeroAviso,
    motivoExpulsion: motivoExpulsion ?? this.motivoExpulsion,
    errorCodigo: errorCodigo == null ? this.errorCodigo : errorCodigo(),
  );

  PartidaState conAviso(String texto, {bool error = false}) => PartidaState(
    conexion: conexion,
    sala: sala,
    cargando: false,
    anclasEnviadas: anclasEnviadas,
    pendiente: pendiente,
    intentos: intentos,
    segundosParaReintentar: segundosParaReintentar,
    aviso: texto,
    avisoEsError: error,
    numeroAviso: numeroAviso + 1,
    motivoExpulsion: motivoExpulsion,
    errorCodigo: errorCodigo,
  );
}

// ---------------------------------------------------------------------------
// Bloc

class PartidaBloc extends Bloc<PartidaEvent, PartidaState> {
  final String usuario;
  final String token;
  final AbrirConexion abrir;

  /// Cuánto esperar antes de cada reintento; el último se repite.
  final List<Duration> esperas;

  ConexionJuego? _conexion;
  StreamSubscription<Map<String, Object?>>? _suscripcion;
  Timer? _reintento;
  bool _cerrando = false;
  bool _reenviarAlVolver = false;
  bool _saliendo = false;
  bool _esperandoUnirse = false;
  int? _rondaPasada;

  PartidaBloc({
    required this.usuario,
    required this.token,
    AbrirConexion? abrir,
    this.esperas = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ],
  }) : abrir = abrir ?? abrirWebSocket,
       super(const PartidaState()) {
    on<Conectar>(_alConectar);
    on<ReintentarAhora>((_, emit) {
      if (state.conexion == EstadoConexion.conectado) return;
      if (state.conexion == EstadoConexion.expulsado) {
        // "Jugar en esta ventana": se vuelve a conectar y el servidor
        // desplaza a la otra.
        emit(PartidaState(sala: state.sala, numeroAviso: state.numeroAviso));
      }
      _reintento?.cancel();
      add(Conectar());
    });
    on<_MensajeRecibido>(_alRecibir);
    on<_ConexionPerdida>(_alPerder);
    on<CrearSala>(
      (e, emit) => _pedir(emit, {'tipo': 'crear_sala', 'nivel': e.nivel}),
    );
    on<UnirseSala>(_alUnirse);
    on<CorregirCodigo>((_, emit) {
      if (state.errorCodigo != null) {
        emit(state.copyWith(errorCodigo: () => null));
      }
    });
    on<SalirSala>((_, emit) {
      _saliendo = true;
      _pedir(emit, {'tipo': 'salir_sala'});
    });
    on<EmpezarPartida>((_, emit) => _pedir(emit, {'tipo': 'empezar'}));
    on<EnviarAnclas>(_alEnviarAnclas);
    on<ColocarNumero>(_alColocar);
    on<Rendirse>((_, emit) => _pedir(emit, {'tipo': 'rendirse'}));
  }

  // -- Conexión ------------------------------------------------------------

  Future<void> _alConectar(Conectar _, Emitter<PartidaState> emit) async {
    if (_cerrando || state.conexion == EstadoConexion.expulsado) return;
    _reintento?.cancel();
    _soltarConexion();
    emit(
      state.copyWith(
        conexion: state.sala == null && state.intentos == 0
            ? EstadoConexion.conectando
            : EstadoConexion.reconectando,
        segundosParaReintentar: () => null,
        motivoExpulsion: null,
      ),
    );

    final ConexionJuego conexion;
    try {
      conexion = await abrir();
    } catch (_) {
      _programarReintento(emit);
      return;
    }
    if (_cerrando || isClosed) {
      await conexion.cerrar();
      return;
    }

    _conexion = conexion;
    _suscripcion = conexion.mensajes.listen(
      (m) => add(_MensajeRecibido(m)),
      onDone: () => add(_ConexionPerdida(conexion)),
      onError: (Object _) {},
      cancelOnError: false,
    );
    conexion.enviar({'tipo': 'hola', 'token': token});
  }

  void _alPerder(_ConexionPerdida e, Emitter<PartidaState> emit) {
    if (!identical(e.conexion, _conexion)) return;
    _conexion = null;
    _suscripcion?.cancel();
    _suscripcion = null;
    if (_cerrando || state.conexion == EstadoConexion.expulsado) return;
    if (state.pendiente != null) _reenviarAlVolver = true;
    // Un "pasar" que se mandó justo antes de la caída pudo perderse.
    _rondaPasada = null;
    _programarReintento(emit);
  }

  void _programarReintento(Emitter<PartidaState> emit) {
    final intentos = state.intentos + 1;
    final espera = esperas[(intentos - 1).clamp(0, esperas.length - 1)];
    emit(
      state.copyWith(
        conexion: EstadoConexion.reconectando,
        intentos: intentos,
        cargando: false,
        segundosParaReintentar: () => espera.inSeconds,
      ),
    );
    _reintento?.cancel();
    _reintento = Timer(espera, () {
      if (!isClosed) add(Conectar());
    });
  }

  /// Suelta la conexión actual sin esperar a que termine de cerrarse: con la
  /// red caída el cierre de un WebSocket puede tardar mucho y no debe frenar
  /// la reconexión.
  void _soltarConexion() {
    final suscripcion = _suscripcion;
    final vieja = _conexion;
    _suscripcion = null;
    _conexion = null;
    unawaited(suscripcion?.cancel());
    unawaited(vieja?.cerrar());
  }

  // -- Mensajes del servidor -----------------------------------------------

  void _alRecibir(_MensajeRecibido e, Emitter<PartidaState> emit) {
    final m = e.mensaje;
    switch (m['tipo']) {
      case 'bienvenida':
        emit(
          state.copyWith(
            conexion: EstadoConexion.conectado,
            intentos: 0,
            segundosParaReintentar: () => null,
          ),
        );

      case 'sin_sala':
        final sacado =
            state.sala != null &&
            !_saliendo &&
            state.sala!.fase != FaseSala.terminada;
        _saliendo = false;
        _reenviarAlVolver = false;
        final limpio = state.copyWith(
          sala: () => null,
          cargando: false,
          anclasEnviadas: false,
          pendiente: () => null,
        );
        emit(
          sacado
              ? limpio.conAviso(
                  'Se perdió la conexión y saliste de la sala.',
                  error: true,
                )
              : limpio,
        );

      case 'estado':
        _alEstado(SalaEnLinea.deJson(m), emit);

      case 'sala_cerrada':
        emit(
          state
              .copyWith(sala: () => null, anclasEnviadas: false)
              .conAviso(m['mensaje'] as String? ?? 'La sala se cerró.'),
        );

      case 'reemplazada':
        _expulsar(
          emit,
          m['mensaje'] as String? ?? 'Abriste el juego en otra ventana.',
        );

      case 'error':
        final clave = m['error'];
        if (clave == 'sin_sesion' || clave == 'sin_saludo') {
          _expulsar(
            emit,
            'Tu sesión venció. Vuelve a iniciar sesión para jugar en línea.',
          );
          return;
        }
        if (_esperandoUnirse) {
          _esperandoUnirse = false;
          emit(
            state.copyWith(
              cargando: false,
              errorCodigo: () =>
                  m['mensaje'] as String? ?? 'No se pudo entrar.',
            ),
          );
          return;
        }
        var nuevo = state;
        if (clave == 'ya_jugaste' || clave == 'ronda_equivocada') {
          // La jugada no cuenta: el tablero vuelve a lo que dice el servidor.
          nuevo = nuevo.copyWith(pendiente: () => null);
        }
        if (clave == 'anclas_invalidas' || clave == 'fase_equivocada') {
          nuevo = nuevo.copyWith(anclasEnviadas: false);
        }
        emit(
          nuevo.conAviso(
            m['mensaje'] as String? ?? 'Algo salió mal.',
            error: true,
          ),
        );
    }
  }

  void _alEstado(SalaEnLinea sala, Emitter<PartidaState> emit) {
    _esperandoUnirse = false;
    var nuevo = state.copyWith(
      sala: () => sala,
      cargando: false,
      errorCodigo: () => null,
    );
    String? aviso;

    if (sala.fase != FaseSala.anclas) {
      nuevo = nuevo.copyWith(anclasEnviadas: false);
    }

    final pendiente = state.pendiente;
    if (pendiente != null) {
      final confirmada =
          sala.mias[(pendiente.fila, pendiente.columna)] == pendiente.numero;
      final yo = sala.yo(usuario);
      if (confirmada) {
        nuevo = nuevo.copyWith(pendiente: () => null);
        _reenviarAlVolver = false;
      } else if (sala.fase != FaseSala.juego || sala.ronda != pendiente.ronda) {
        nuevo = nuevo.copyWith(pendiente: () => null);
        _reenviarAlVolver = false;
        if (sala.fase == FaseSala.juego) {
          aviso = 'Tu jugada no llegó a tiempo y pasaste esa ronda.';
        }
      } else if (_reenviarAlVolver && yo != null && !yo.yaJugo) {
        _reenviarAlVolver = false;
        _conexion?.enviar(pendiente.mensaje);
      }
    }
    emit(aviso == null ? nuevo : nuevo.conAviso(aviso, error: true));

    _quizaPasar(emit);
  }

  /// Si con los dados de la ronda no hay dónde escribir, se pasa solo.
  void _quizaPasar(Emitter<PartidaState> emit) {
    final sala = state.sala;
    final dados = sala?.dados;
    final yo = sala?.yo(usuario);
    if (sala == null ||
        dados == null ||
        yo == null ||
        sala.fase != FaseSala.juego ||
        yo.yaJugo ||
        state.pendiente != null ||
        _rondaPasada == sala.ronda) {
      return;
    }
    final tablero = tableroCon(sala.datosNivel, state.casillas);
    if (hayJugadaCon(tablero, dados)) return;

    _rondaPasada = sala.ronda;
    _conexion?.enviar({'tipo': 'pasar', 'ronda': sala.ronda});
    emit(
      state.conAviso(
        'Con ${dados.primero} y ${dados.segundo} no había jugada: '
        'pasas esta ronda.',
      ),
    );
  }

  void _expulsar(Emitter<PartidaState> emit, String motivo) {
    _reintento?.cancel();
    emit(
      state.copyWith(
        conexion: EstadoConexion.expulsado,
        cargando: false,
        motivoExpulsion: motivo,
      ),
    );
    _soltarConexion();
  }

  // -- Acciones del jugador ------------------------------------------------

  void _pedir(Emitter<PartidaState> emit, Map<String, Object?> mensaje) {
    if (!state.conectado) {
      emit(
        state.conAviso(
          'Sin conexión con el servidor. Espera a que se reconecte.',
          error: true,
        ),
      );
      return;
    }
    emit(state.copyWith(cargando: true));
    _conexion?.enviar(mensaje);
  }

  void _alUnirse(UnirseSala e, Emitter<PartidaState> emit) {
    final codigo = e.codigo.trim().toUpperCase();
    if (codigo.length != 6) {
      emit(
        state.copyWith(
          errorCodigo: () => 'Escribe los 6 caracteres del código de la sala.',
        ),
      );
      return;
    }
    emit(state.copyWith(errorCodigo: () => null));
    _esperandoUnirse = state.conectado;
    _pedir(emit, {'tipo': 'unirse', 'codigo': codigo});
  }

  void _alEnviarAnclas(EnviarAnclas e, Emitter<PartidaState> emit) {
    final valores = [
      for (var f = 0; f < e.tablero.valores.length; f++)
        for (var c = 0; c < e.tablero.valores[f].length; c++)
          if (e.tablero.valores[f][c] case final n?) [f, c, n],
    ];
    _pedir(emit, {'tipo': 'anclas', 'valores': valores});
    if (state.conectado) {
      emit(state.copyWith(anclasEnviadas: true, cargando: false));
    }
  }

  void _alColocar(ColocarNumero e, Emitter<PartidaState> emit) {
    final sala = state.sala;
    final dados = sala?.dados;
    final yo = sala?.yo(usuario);
    if (sala == null ||
        dados == null ||
        yo == null ||
        sala.fase != FaseSala.juego ||
        yo.yaJugo ||
        state.pendiente != null ||
        !dados.contiene(e.numero)) {
      return;
    }

    final tablero = tableroCon(sala.datosNivel, state.casillas);
    final posibles = tablero.celdasPosibles(
      e.numero,
      dados.companeroDe(e.numero),
    );
    if (!posibles.contains((e.fila, e.columna))) return;

    tablero.valores[e.fila][e.columna] = e.numero;
    final jugada = JugadaPendiente(
      ronda: sala.ronda,
      fila: e.fila,
      columna: e.columna,
      numero: e.numero,
      puntos: tablero.puntos,
      terminado: tablero.estaCompleto() && tablero.esValido(),
    );
    emit(state.copyWith(pendiente: () => jugada));

    if (state.conectado) {
      _conexion?.enviar(jugada.mensaje);
    } else {
      // Se manda en cuanto vuelva la conexión.
      _reenviarAlVolver = true;
    }
  }

  @override
  Future<void> close() async {
    _cerrando = true;
    _reintento?.cancel();
    _soltarConexion();
    return super.close();
  }
}
