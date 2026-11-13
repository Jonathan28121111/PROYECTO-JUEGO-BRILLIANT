import 'package:flutter_bloc/flutter_bloc.dart';

import 'cliente_cuentas.dart';

sealed class SesionEvent {}

class Registrarse extends SesionEvent {
  final String usuario;
  final String contrasena;

  Registrarse(this.usuario, this.contrasena);
}

class IniciarSesion extends SesionEvent {
  final String usuario;
  final String contrasena;

  IniciarSesion(this.usuario, this.contrasena);
}

class JugarSinCuenta extends SesionEvent {}

class CerrarSesion extends SesionEvent {}

sealed class SesionState {
  const SesionState();
}

class SinSesion extends SesionState {
  final bool cargando;
  final String? error;

  const SinSesion({this.cargando = false, this.error});
}

class ConCuenta extends SesionState {
  final Cuenta cuenta;
  final bool cargando;
  final String? error;

  const ConCuenta(this.cuenta, {this.cargando = false, this.error});
}

class Invitado extends SesionState {
  const Invitado();
}

class SesionBloc extends Bloc<SesionEvent, SesionState> {
  final ClienteCuentas cliente;

  SesionBloc(this.cliente) : super(const SinSesion()) {
    on<Registrarse>(
      (e, emit) =>
          _entrar(emit, () => cliente.registrar(e.usuario, e.contrasena)),
    );
    on<IniciarSesion>(
      (e, emit) =>
          _entrar(emit, () => cliente.iniciarSesion(e.usuario, e.contrasena)),
    );
    on<JugarSinCuenta>((_, emit) => emit(const Invitado()));
    on<CerrarSesion>(_alCerrarSesion);
  }

  Future<void> _entrar(
    Emitter<SesionState> emit,
    Future<Cuenta> Function() pedir,
  ) async {
    if (state case SinSesion(cargando: true)) {
      return;
    }
    emit(const SinSesion(cargando: true));
    try {
      emit(ConCuenta(await pedir()));
    } on ErrorCuenta catch (error) {
      emit(SinSesion(error: error.mensaje));
    }
  }

  Future<void> _alCerrarSesion(
    CerrarSesion evento,
    Emitter<SesionState> emit,
  ) async {
    if (state case ConCuenta(:final cuenta)) {
      await cliente
          .cerrarSesion(cuenta.token)
          .catchError((_) {}, test: (error) => error is ErrorCuenta);
    }
    emit(const SinSesion());
  }
}
