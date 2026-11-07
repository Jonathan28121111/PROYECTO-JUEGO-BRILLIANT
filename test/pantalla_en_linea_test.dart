import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/cliente_cuentas.dart';
import 'package:pruebas_numeros/main.dart';
import 'package:pruebas_numeros/pantalla_anclas.dart';
import 'package:pruebas_numeros/pantalla_en_linea.dart';
import 'package:pruebas_numeros/sesion_bloc.dart';
import 'package:pruebas_numeros/tablero_interfaz.dart';
import 'package:pruebas_numeros/vista_juego.dart';

import 'ayudas_interfaz.dart';
import 'conexion_falsa.dart';
import 'servidor_falso.dart';

void main() {
  late ServidorJuegoFalso servidor;

  setUp(() => servidor = ServidorJuegoFalso());

  Future<void> abrir(WidgetTester tester) async {
    pantallaGrande(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SesionBloc(ServidorFalso().cliente()),
          child: PantallaEnLinea(
            cuenta: const Cuenta(usuario: 'ana', token: 'token-de-ana'),
            abrir: servidor.abrir,
            esperas: const [Duration(seconds: 2)],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> llega(WidgetTester tester, Map<String, Object?> mensaje) async {
    servidor.mandar(mensaje);
    await tester.pump();
    await tester.pump();
  }

  Map<String, Object?> enJuego({
    List<Map<String, Object?>>? jugadores,
    int? segundosRonda = 90,
  }) => estadoSala(
    fase: 'juego',
    ronda: 3,
    dados: [3, 5],
    segundosRonda: segundosRonda,
    mias: const [
      [0, 2, 5],
    ],
    jugadores:
        jugadores ??
        [
          jugador('ana', listo: true, puntos: 12),
          jugador('beto', listo: true, puntos: 7),
        ],
  );

  /// Saca la pantalla del árbol para que se cierre el bloc y sus relojes.
  Future<void> cerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  group('lobby', () {
    testWidgets('al conectar muestra las dos opciones', (tester) async {
      await abrir(tester);

      expect(find.text('Hola, ana'), findsOneWidget);
      expect(find.text('Crear sala'), findsWidgets);
      expect(find.text('Unirse a una sala'), findsOneWidget);
      expect(find.text('Código de la sala'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('crear sala manda el nivel elegido', (tester) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('nivel_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('boton_crear_sala')));
      await tester.pump();

      expect(servidor.recibidos.last, {'tipo': 'crear_sala', 'nivel': 2});
      await cerrar(tester);
    });

    testWidgets('el codigo se escribe en mayusculas', (tester) async {
      await abrir(tester);

      await tester.enterText(find.byKey(const Key('campo_codigo')), 'abc234');
      await tester.tap(find.byKey(const Key('boton_unirse')));
      await tester.pump();

      expect(find.text('ABC234'), findsOneWidget);
      expect(servidor.recibidos.last, {'tipo': 'unirse', 'codigo': 'ABC234'});
      await cerrar(tester);
    });

    testWidgets('un codigo equivocado muestra el error', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byKey(const Key('campo_codigo')), 'ZZZZZZ');
      await tester.tap(find.byKey(const Key('boton_unirse')));
      await tester.pump();

      await llega(tester, {
        'tipo': 'error',
        'error': 'sala_no_existe',
        'mensaje': 'No hay ninguna sala con ese código.',
      });

      expect(find.text('No hay ninguna sala con ese código.'), findsOneWidget);
      await cerrar(tester);
    });
  });

  group('sala de espera', () {
    testWidgets('muestra el codigo y espera al rival', (tester) async {
      await abrir(tester);
      await llega(tester, estadoSala(codigo: 'K7P2QX'));

      expect(find.text('K7P2QX'), findsOneWidget);
      expect(find.text('Esperando a tu rival…'), findsOneWidget);
      expect(find.text('Nivel 1 · 1 de 2 jugadores'), findsOneWidget);

      // El botón nunca está apagado: si falta el rival, explica qué hacer.
      await tester.tap(find.byKey(const Key('boton_empezar')));
      await tester.pump();
      expect(
        find.text(
          'Falta que tu rival se una. Compártele el código para empezar.',
        ),
        findsOneWidget,
      );
      expect(servidor.tipos, isNot(contains('empezar')));
      await cerrar(tester);
    });

    testWidgets('con los dos, el anfitrion puede empezar', (tester) async {
      await abrir(tester);
      await llega(
        tester,
        estadoSala(jugadores: [jugador('ana'), jugador('beto')]),
      );

      await tester.tap(find.byKey(const Key('boton_empezar')));
      await tester.pump();

      expect(servidor.recibidos.last, {'tipo': 'empezar'});
      await cerrar(tester);
    });

    testWidgets('el invitado espera a que el anfitrion empiece', (
      tester,
    ) async {
      await abrir(tester);
      await llega(
        tester,
        estadoSala(
          anfitrion: 'beto',
          jugadores: [jugador('beto'), jugador('ana')],
        ),
      );

      expect(find.byKey(const Key('boton_empezar')), findsNothing);
      expect(
        find.text('Esperando a que beto empiece la partida.'),
        findsOneWidget,
      );
      await cerrar(tester);
    });

    testWidgets('salir de la sala avisa al servidor', (tester) async {
      await abrir(tester);
      await llega(tester, estadoSala());

      await tester.tap(find.byKey(const Key('boton_salir_sala')));
      await tester.pump();

      expect(servidor.recibidos.last, {'tipo': 'salir_sala'});
      await cerrar(tester);
    });
  });

  group('partida', () {
    testWidgets('en la fase de anclas se ponen las anclas propias', (
      tester,
    ) async {
      await abrir(tester);
      await llega(
        tester,
        estadoSala(
          fase: 'anclas',
          jugadores: [jugador('ana'), jugador('beto', listo: true)],
        ),
      );

      expect(find.byType(PantallaAnclas), findsOneWidget);
      expect(find.text('Anclas listas'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('el marcador muestra a los dos con sus puntos', (tester) async {
      await abrir(tester);
      await llega(tester, enJuego());

      expect(find.byType(VistaJuego), findsOneWidget);
      expect(find.text('Ronda 3'), findsOneWidget);
      expect(find.text('ana (tú)'), findsOneWidget);
      expect(find.text('12 puntos'), findsOneWidget);
      expect(find.text('7 puntos'), findsOneWidget);
      expect(find.text('Tirar los dados'), findsNothing);
      await cerrar(tester);
    });

    testWidgets('el reloj de la ronda cuenta hacia atras', (tester) async {
      await abrir(tester);
      await llega(tester, enJuego());
      expect(find.text('90 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));

      expect(find.text('87 s'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('elegir un dado y tocar una casilla manda la jugada', (
      tester,
    ) async {
      await abrir(tester);
      await llega(tester, enJuego());

      await tester.tap(find.byKey(const Key('dado_1')));
      await tester.pump();
      expect(find.text('Toca una casilla resaltada'), findsOneWidget);

      await tester.tapAt(centroDeCelda(tester, 0, 1));
      await tester.pump();

      expect(servidor.recibidos.last['tipo'], 'jugada');
      expect(servidor.recibidos.last['numero'], 3);
      expect(find.text('Esperando a que beto juegue…'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('si el rival se cae se ve cuanto le queda para volver', (
      tester,
    ) async {
      await abrir(tester);
      await llega(
        tester,
        enJuego(
          segundosRonda: null,
          jugadores: [
            jugador('ana', listo: true),
            jugador('beto', listo: true, conectado: false, segundosGracia: 45),
          ],
        ),
      );

      expect(find.byKey(const Key('aviso_rival')), findsOneWidget);
      expect(
        find.text(
          'beto se desconectó. Si no vuelve en 45 s, ganas la partida.',
        ),
        findsOneWidget,
      );
      expect(find.text('Desconectado · 45 s'), findsOneWidget);
      expect(find.text('reloj en pausa'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('rendirse pide confirmacion', (tester) async {
      await abrir(tester);
      await llega(tester, enJuego());

      await tester.tap(find.byKey(const Key('boton_rendirse')));
      await tester.pumpAndSettle();
      expect(find.text('¿Rendirte ante beto?'), findsOneWidget);

      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(servidor.tipos, isNot(contains('rendirse')));

      await tester.tap(find.byKey(const Key('boton_rendirse')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar_rendicion')));
      await tester.pump();

      expect(servidor.recibidos.last, {'tipo': 'rendirse'});
      await cerrar(tester);
    });

    testWidgets('salir con la flecha a media partida pide rendirse', (
      tester,
    ) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SesionBloc(ServidorFalso().cliente()),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SesionBloc>(),
                        child: PantallaEnLinea(
                          cuenta: const Cuenta(usuario: 'ana', token: 't'),
                          abrir: servidor.abrir,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await llega(tester, enJuego());

      await tester.tap(find.byKey(const Key('boton_jugar_local')));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir y rendirte ante beto?'), findsOneWidget);
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaEnLinea), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir y rendirte ante beto?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmar_rendicion')));
      await tester.pumpAndSettle();

      expect(servidor.recibidos.last, {'tipo': 'rendirse'});
      expect(find.byType(PantallaEnLinea), findsNothing);
    });
  });

  group('conexion', () {
    testWidgets('al caerse aparece el aviso y se puede reintentar', (
      tester,
    ) async {
      await abrir(tester);
      await llega(tester, enJuego());

      servidor.actual.caer();
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('banner_conexion')), findsOneWidget);
      expect(find.text('Sin conexión con el servidor'), findsOneWidget);
      expect(find.textContaining('60 s para volver'), findsOneWidget);
      // La partida sigue a la vista mientras reconecta.
      expect(find.byType(VistaJuego), findsOneWidget);

      await tester.tap(find.byKey(const Key('reintentar_ahora')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('banner_conexion')), findsNothing);
      expect(servidor.conexiones, hasLength(2));
      await cerrar(tester);
    });

    testWidgets('abierto en otra ventana ofrece jugar aqui', (tester) async {
      await abrir(tester);

      await llega(tester, {
        'tipo': 'reemplazada',
        'mensaje': 'Abriste el juego en otra ventana.',
      });

      expect(find.text('Abriste el juego en otra ventana.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('jugar_aqui')));
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }

      expect(find.text('Hola, ana'), findsOneWidget);
      await cerrar(tester);
    });
  });

  group('resultado', () {
    Future<void> termina(
      WidgetTester tester,
      String? ganador,
      String motivo,
    ) async {
      await abrir(tester);
      await llega(
        tester,
        estadoSala(
          fase: 'terminada',
          jugadores: [jugador('ana', puntos: 30), jugador('beto', puntos: 25)],
          resultado: {'ganador': ganador, 'motivo': motivo},
        ),
      );
    }

    testWidgets('ganar por puntos', (tester) async {
      await termina(tester, 'ana', 'puntos');

      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(
        find.text('Terminaste con 30 puntos contra 25 de beto.'),
        findsOneWidget,
      );
      await cerrar(tester);
    });

    testWidgets('perder por rendirse', (tester) async {
      await termina(tester, 'beto', 'rendicion');

      expect(find.text('Perdiste'), findsOneWidget);
      expect(find.text('Te rendiste.'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('ganar porque el rival no volvio', (tester) async {
      await termina(tester, 'ana', 'abandono');

      expect(
        find.text('beto se desconectó y no volvió a tiempo.'),
        findsOneWidget,
      );
      await cerrar(tester);
    });

    testWidgets('si los dos se caen la partida se anula', (tester) async {
      await termina(tester, null, 'abandonoAmbos');

      expect(find.text('Partida anulada'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets('volver al lobby sale de la sala', (tester) async {
      await termina(tester, 'ana', 'puntos');

      await tester.tap(find.byKey(const Key('volver_lobby')));
      await tester.pump();

      expect(servidor.recibidos.last, {'tipo': 'salir_sala'});
      await cerrar(tester);
    });
  });

  group('boton de la barra', () {
    testWidgets('jugando sin cuenta pide iniciar sesion', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        JuegoBrilliantApp(
          cliente: ServidorFalso().cliente(),
          abrirConexion: servidor.abrir,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jugar sin cuenta'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_en_linea')));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas una cuenta'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Iniciar sesión'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inicio de sesión'), findsOneWidget);
      expect(servidor.conexiones, isEmpty);
    });

    testWidgets('con cuenta abre el lobby en linea', (tester) async {
      pantallaGrande(tester);
      final cuentas = ServidorFalso()..cuentas['ana'] = 'contrasena123';
      await tester.pumpWidget(
        JuegoBrilliantApp(
          cliente: cuentas.cliente(),
          abrirConexion: servidor.abrir,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campo_usuario')), 'ana');
      await tester.enterText(
        find.byKey(const Key('campo_contrasena')),
        'contrasena123',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_en_linea')));
      await tester.pumpAndSettle();

      expect(find.byType(PantallaEnLinea), findsOneWidget);
      expect(find.text('Hola, ana'), findsOneWidget);
      expect(servidor.recibidos.first['tipo'], 'hola');
      await cerrar(tester);
    });

    testWidgets('la tarjeta sobre los niveles invita a jugar en linea', (
      tester,
    ) async {
      pantallaGrande(tester);
      final cuentas = ServidorFalso()..cuentas['ana'] = 'contrasena123';
      await tester.pumpWidget(
        JuegoBrilliantApp(
          cliente: cuentas.cliente(),
          abrirConexion: servidor.abrir,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campo_usuario')), 'ana');
      await tester.enterText(
        find.byKey(const Key('campo_contrasena')),
        'contrasena123',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(TarjetaEnLinea), findsOneWidget);
      expect(find.byKey(const Key('modo_en_linea')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tarjeta_en_linea')));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaEnLinea), findsOneWidget);

      await tester.tap(find.byKey(const Key('boton_jugar_local')));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaEnLinea), findsNothing);
      expect(find.text('¿Cómo quieres jugar?'), findsOneWidget);
    });

    testWidgets('sin cuenta la tarjeta pide iniciar sesion', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        JuegoBrilliantApp(
          cliente: ServidorFalso().cliente(),
          abrirConexion: servidor.abrir,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jugar sin cuenta'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tarjeta_en_linea')));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas una cuenta'), findsOneWidget);
      expect(servidor.conexiones, isEmpty);
    });
  });

  group('pantallas angostas', () {
    Future<void> abrirAngosta(WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SesionBloc(ServidorFalso().cliente()),
            child: PantallaEnLinea(
              cuenta: const Cuenta(usuario: 'ana', token: 'token-de-ana'),
              abrir: servidor.abrir,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a 375 px la partida cabe y el tablero ocupa el ancho', (
      tester,
    ) async {
      await abrirAngosta(tester);
      await llega(tester, enJuego());

      expect(tester.takeException(), isNull);
      final tablero = tester.getRect(
        find.descendant(
          of: find.byType(TableroInterfaz),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(tablero.width, greaterThan(300));
      await cerrar(tester);
    });

    testWidgets('a 375 px los botones de la barra son iconos con tooltip', (
      tester,
    ) async {
      await abrirAngosta(tester);
      await llega(tester, enJuego());

      final rendirse = tester.widget<IconButton>(
        find.byKey(const Key('boton_rendirse')),
      );
      expect(rendirse.tooltip, 'Rendirse');
      final local = tester.widget<IconButton>(
        find.byKey(const Key('boton_jugar_local')),
      );
      expect(local.tooltip, 'Volver a jugar local');
      await cerrar(tester);
    });
  });

  group('conectando', () {
    testWidgets('mientras conecta el lobby ya se ve, con el estado en linea', (
      tester,
    ) async {
      servidor.caido = true;
      await abrir(tester);

      expect(find.text('Hola, ana'), findsOneWidget);
      expect(find.text('Conectando con el servidor…'), findsOneWidget);
      await cerrar(tester);
    });

    testWidgets(
      'el error del codigo se ve debajo del campo y se va al editar',
      (tester) async {
        await abrir(tester);
        await tester.enterText(find.byKey(const Key('campo_codigo')), 'AB');
        await tester.tap(find.byKey(const Key('boton_unirse')));
        await tester.pump();

        const error = 'Escribe los 6 caracteres del código de la sala.';
        expect(find.text(error), findsOneWidget);
        expect(servidor.tipos, isNot(contains('unirse')));

        await tester.enterText(find.byKey(const Key('campo_codigo')), 'ABC');
        await tester.pump();
        expect(find.text(error), findsNothing);
        await cerrar(tester);
      },
    );
  });

  group('lobby con miniaturas', () {
    testWidgets('el tablero se elige tocando su miniatura', (tester) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('nivel_3')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('boton_crear_sala')));
      await tester.pump();

      expect(servidor.recibidos.last, {'tipo': 'crear_sala', 'nivel': 3});
      await cerrar(tester);
    });
  });
}
