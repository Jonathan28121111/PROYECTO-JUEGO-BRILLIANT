import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cliente_cuentas.dart';
import 'conexion_juego.dart';
import 'pantalla_cuenta.dart';
import 'pantalla_en_linea.dart';
import 'pantalla_juego.dart';
import 'sesion_bloc.dart';

void main() {
  runApp(const JuegoBrilliantApp());
}

class JuegoBrilliantApp extends StatelessWidget {
  final ClienteCuentas? cliente;

  /// Cómo abrir la conexión de las partidas en línea (las pruebas la falsean).
  final AbrirConexion? abrirConexion;

  const JuegoBrilliantApp({super.key, this.cliente, this.abrirConexion});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => FabricaConexion(abrirConexion ?? abrirWebSocket),
      child: BlocProvider(
        create: (_) => SesionBloc(cliente ?? ClienteCuentas()),
        child: MaterialApp(
          title: 'Juego Brilliant',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          home: BlocConsumer<SesionBloc, SesionState>(
            listenWhen: (_, ahora) => ahora is ConCuenta && ahora.error != null,
            listener: (context, estado) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text((estado as ConCuenta).error!)),
              );
            },
            buildWhen: (antes, ahora) => antes.runtimeType != ahora.runtimeType,
            builder: (context, estado) => switch (estado) {
              SinSesion() => const PantallaCuenta(),
              ConCuenta() || Invitado() => const PantallaJuego(
                acciones: [BotonEnLinea(), MenuCuenta()],
              ),
            },
          ),
        ),
      ),
    );
  }
}
