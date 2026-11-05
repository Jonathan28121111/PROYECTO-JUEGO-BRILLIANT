import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/partida_bloc.dart';
import 'package:pruebas_numeros/sala_en_linea.dart';
import 'package:pruebas_numeros/tablero.dart';

import 'conexion_falsa.dart';

/// Una casilla con un 5 al lado de (0, 1), que es verde: con los dados 3 y 5
/// se puede escribir el 3 ahí.
const anclaConJugada = [
  [0, 2, 5],
];

void main() {
  late ServidorJuegoFalso servidor;
  late PartidaBloc bloc;

  setUp(() {
    servidor = ServidorJuegoFalso();
    bloc = PartidaBloc(
      usuario: 'ana',
      token: 'token-de-ana',
      abrir: servidor.abrir,
      esperas: const [Duration(milliseconds: 20)],
    );
  });

  tearDown(() => bloc.close());

  Future<void> esperar([int ms = 5]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  Future<void> conectar() async {
    bloc.add(Conectar());
    await esperar();
  }

  Future<void> llega(Map<String, Object?> mensaje) async {
    servidor.mandar(mensaje);
    await esperar();
  }

  Future<void> enJuego({
    List<int> dados = const [3, 5],
    int ronda = 1,
    List<List<int>> mias = anclaConJugada,
  }) async {
    await conectar();
    await llega(
      estadoSala(
        fase: 'juego',
        ronda: ronda,
        dados: dados,
        mias: mias,
        jugadores: [jugador('ana', listo: true), jugador('beto', listo: true)],
      ),
    );
  }

  group('conexion', () {
    test('saluda con el token y queda conectado', () async {
      await conectar();

      expect(servidor.recibidos.first, {
        'tipo': 'hola',
        'token': 'token-de-ana',
      });
      expect(bloc.state.conexion, EstadoConexion.conectado);
    });

    test('si se cae, reintenta solo y vuelve a saludar', () async {
      await conectar();

      servidor.actual.caer();
      await esperar();
      expect(bloc.state.conexion, EstadoConexion.reconectando);
      expect(bloc.state.intentos, 1);

      await esperar(40);
      expect(servidor.conexiones, hasLength(2));
      expect(servidor.tipos.where((t) => t == 'hola'), hasLength(2));
      expect(bloc.state.conexion, EstadoConexion.conectado);
      expect(bloc.state.intentos, 0);
    });

    test('mientras el servidor no responde sigue reintentando', () async {
      servidor.caido = true;
      await conectar();
      expect(bloc.state.conexion, EstadoConexion.reconectando);

      await esperar(80);
      expect(servidor.intentos, greaterThan(2));

      servidor.caido = false;
      await esperar(40);
      expect(bloc.state.conexion, EstadoConexion.conectado);
    });

    test('reintentar ahora no espera a la cuenta', () async {
      bloc = PartidaBloc(
        usuario: 'ana',
        token: 't',
        abrir: servidor.abrir,
        esperas: const [Duration(seconds: 30)],
      );
      servidor.caido = true;
      await conectar();
      servidor.caido = false;

      bloc.add(ReintentarAhora());
      await esperar();

      expect(bloc.state.conexion, EstadoConexion.conectado);
    });

    test('si se abre en otra ventana no reintenta', () async {
      await conectar();

      await llega({'tipo': 'reemplazada', 'mensaje': 'Otra ventana.'});
      servidor.actual.caer();
      await esperar(50);

      expect(bloc.state.conexion, EstadoConexion.expulsado);
      expect(bloc.state.motivoExpulsion, 'Otra ventana.');
      expect(servidor.conexiones, hasLength(1));
    });

    test('jugar en esta ventana vuelve a conectar', () async {
      await conectar();
      await llega({'tipo': 'reemplazada', 'mensaje': 'Otra ventana.'});

      bloc.add(ReintentarAhora());
      await esperar();

      expect(bloc.state.conexion, EstadoConexion.conectado);
      expect(bloc.state.motivoExpulsion, isNull);
    });

    test('con la sesion vencida pide volver a entrar', () async {
      await conectar();

      await llega({'tipo': 'error', 'error': 'sin_sesion', 'mensaje': 'x'});

      expect(bloc.state.conexion, EstadoConexion.expulsado);
      expect(bloc.state.motivoExpulsion, contains('sesión'));
    });

    test('al cerrar el bloc se cierra la conexion', () async {
      await conectar();
      await bloc.close();

      expect(servidor.actual.cerrada, isTrue);
    });
  });

  group('lobby', () {
    test('crear sala manda el nivel', () async {
      await conectar();
      bloc.add(CrearSala(2));
      await esperar();

      expect(servidor.recibidos.last, {'tipo': 'crear_sala', 'nivel': 2});
      expect(bloc.state.cargando, isTrue);
    });

    test('el estado que llega se convierte en la sala', () async {
      await conectar();
      await llega(
        estadoSala(
          codigo: 'XYZ789',
          jugadores: [jugador('ana'), jugador('beto')],
        ),
      );

      final sala = bloc.state.sala!;
      expect(sala.codigo, 'XYZ789');
      expect(sala.fase, FaseSala.espera);
      expect(sala.rival('ana')?.usuario, 'beto');
      expect(bloc.state.cargando, isFalse);
    });

    test('unirse normaliza el codigo', () async {
      await conectar();
      bloc.add(UnirseSala(' abc234 '));
      await esperar();

      expect(servidor.recibidos.last, {'tipo': 'unirse', 'codigo': 'ABC234'});
    });

    test('un codigo incompleto no llega al servidor', () async {
      await conectar();
      bloc.add(UnirseSala('abc'));
      await esperar();

      expect(servidor.tipos, isNot(contains('unirse')));
      expect(bloc.state.avisoEsError, isTrue);
    });

    test('un error del servidor se muestra como aviso', () async {
      await conectar();
      bloc.add(UnirseSala('ZZZZZZ'));
      await esperar();
      await llega({
        'tipo': 'error',
        'error': 'sala_no_existe',
        'mensaje': 'No hay ninguna sala con ese código.',
      });

      expect(bloc.state.aviso, 'No hay ninguna sala con ese código.');
      expect(bloc.state.cargando, isFalse);
    });

    test('sin conexion las acciones avisan en vez de perderse', () async {
      servidor.caido = true;
      await conectar();

      bloc.add(CrearSala(1));
      await esperar();

      expect(bloc.state.aviso, contains('Sin conexión'));
    });

    test('si te sacan de la sala por una caida, te avisa', () async {
      await conectar();
      await llega(estadoSala());

      await llega({'tipo': 'sin_sala'});

      expect(bloc.state.sala, isNull);
      expect(bloc.state.aviso, contains('saliste de la sala'));
    });

    test('salir a proposito no muestra aviso', () async {
      await conectar();
      await llega(estadoSala());
      bloc.add(SalirSala());
      await esperar();

      await llega({'tipo': 'sin_sala'});

      expect(bloc.state.sala, isNull);
      expect(bloc.state.aviso, isNull);
    });

    test('si el anfitrion cierra la sala, avisa', () async {
      await conectar();
      await llega(estadoSala(anfitrion: 'beto'));

      await llega({'tipo': 'sala_cerrada', 'mensaje': 'Se fue.'});

      expect(bloc.state.sala, isNull);
      expect(bloc.state.aviso, 'Se fue.');
    });
  });

  group('anclas', () {
    test('manda las casillas puestas y espera al rival', () async {
      await conectar();
      await llega(estadoSala(fase: 'anclas'));
      final tablero = Tablero.nivel1Inicial()
        ..valores[0][2] = 1
        ..valores[1][5] = 2;

      bloc.add(EnviarAnclas(tablero));
      await esperar();

      expect(servidor.recibidos.last, {
        'tipo': 'anclas',
        'valores': [
          [0, 2, 1],
          [1, 5, 2],
        ],
      });
      expect(bloc.state.anclasEnviadas, isTrue);
    });
  });

  group('jugadas', () {
    test('colocar manda la jugada con los puntos y se ve enseguida', () async {
      await enJuego();

      bloc.add(ColocarNumero(0, 1, 3));
      await esperar();

      expect(servidor.recibidos.last, {
        'tipo': 'jugada',
        'ronda': 1,
        'fila': 0,
        'columna': 1,
        'numero': 3,
        'puntos': 0,
        'terminado': false,
      });
      expect(bloc.state.casillas[(0, 1)], 3);
      expect(bloc.state.pendiente, isNotNull);
    });

    test('una casilla que no es valida no se manda', () async {
      await enJuego();

      bloc.add(ColocarNumero(6, 6, 3));
      bloc.add(ColocarNumero(0, 1, 4));
      await esperar();

      expect(servidor.tipos, isNot(contains('jugada')));
    });

    test('cuando el servidor la confirma deja de estar pendiente', () async {
      await enJuego();
      bloc.add(ColocarNumero(0, 1, 3));
      await esperar();

      await llega(
        estadoSala(
          fase: 'juego',
          ronda: 1,
          dados: [3, 5],
          mias: [
            ...anclaConJugada,
            [0, 1, 3],
          ],
          jugadores: [jugador('ana', jugoRonda: true), jugador('beto')],
        ),
      );

      expect(bloc.state.pendiente, isNull);
      expect(bloc.state.casillas[(0, 1)], 3);
    });

    test('una jugada hecha sin conexion se manda al volver', () async {
      await enJuego();
      servidor.actual.caer();
      await esperar();

      bloc.add(ColocarNumero(0, 1, 3));
      await esperar();
      expect(bloc.state.casillas[(0, 1)], 3);

      await esperar(40);
      await llega(
        estadoSala(
          fase: 'juego',
          ronda: 1,
          dados: [3, 5],
          mias: anclaConJugada,
          jugadores: [jugador('ana'), jugador('beto')],
        ),
      );

      expect(
        servidor.actual.enviados.map((m) => m['tipo']),
        contains('jugada'),
      );
    });

    test('si la ronda paso sin la jugada, se descarta y avisa', () async {
      await enJuego();
      servidor.actual.caer();
      await esperar();
      bloc.add(ColocarNumero(0, 1, 3));
      await esperar(40);

      await llega(
        estadoSala(
          fase: 'juego',
          ronda: 2,
          dados: [3, 5],
          mias: anclaConJugada,
          jugadores: [jugador('ana'), jugador('beto')],
        ),
      );

      expect(bloc.state.pendiente, isNull);
      expect(bloc.state.casillas[(0, 1)], isNull);
      expect(bloc.state.aviso, contains('no llegó a tiempo'));
    });

    test('sin ninguna jugada posible pasa solo, una vez por ronda', () async {
      await enJuego(mias: const []);

      expect(servidor.recibidos.last, {'tipo': 'pasar', 'ronda': 1});
      expect(bloc.state.aviso, contains('pasas esta ronda'));

      await llega(
        estadoSala(
          fase: 'juego',
          ronda: 1,
          dados: [3, 5],
          jugadores: [jugador('ana'), jugador('beto', jugoRonda: true)],
        ),
      );
      expect(servidor.tipos.where((t) => t == 'pasar'), hasLength(1));
    });

    test('con alguna jugada posible no pasa', () async {
      await enJuego();

      expect(servidor.tipos, isNot(contains('pasar')));
    });

    test('rendirse manda el mensaje', () async {
      await enJuego();
      bloc.add(Rendirse());
      await esperar();

      expect(servidor.recibidos.last, {'tipo': 'rendirse'});
    });
  });
}
