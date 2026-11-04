import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/sesion_bloc.dart';

import 'servidor_falso.dart';

void main() {
  late ServidorFalso servidor;
  late SesionBloc bloc;

  setUp(() {
    servidor = ServidorFalso();
    bloc = SesionBloc(servidor.cliente());
  });

  tearDown(() => bloc.close());

  Future<SesionState> despues(SesionEvent evento) async {
    final siguientes = bloc.stream
        .where((e) => !(e is SinSesion && e.cargando))
        .where((e) => !(e is ConCuenta && e.cargando))
        .first;
    bloc.add(evento);
    return siguientes;
  }

  test('empieza sin sesion', () {
    expect(bloc.state, isA<SinSesion>());
  });

  test('registrarse deja la sesion iniciada', () async {
    final estado = await despues(Registrarse('jonathan', 'contrasena123'));

    expect(estado, isA<ConCuenta>());
    expect((estado as ConCuenta).cuenta.usuario, 'jonathan');
  });

  test('pasa por cargando mientras espera al servidor', () async {
    final estados = bloc.stream.take(2).toList();

    bloc.add(Registrarse('jonathan', 'contrasena123'));

    final lista = await estados;
    expect(lista.first, isA<SinSesion>());
    expect((lista.first as SinSesion).cargando, isTrue);
    expect(lista.last, isA<ConCuenta>());
  });

  test('iniciar sesion con la contrasena mala muestra el error', () async {
    servidor.cuentas['jonathan'] = 'contrasena123';

    final estado = await despues(IniciarSesion('jonathan', 'equivocada'));

    expect(estado, isA<SinSesion>());
    expect((estado as SinSesion).error, contains('incorrectos'));
  });

  test('sin red muestra que no hay conexion', () async {
    servidor.caido = true;

    final estado = await despues(IniciarSesion('jonathan', 'contrasena123'));

    expect((estado as SinSesion).error, contains('conectar'));
  });

  test('jugar sin cuenta entra como invitado', () async {
    expect(await despues(JugarSinCuenta()), isA<Invitado>());
  });

  test('cerrar sesion avisa al servidor y vuelve al inicio', () async {
    await despues(Registrarse('jonathan', 'contrasena123'));

    final estado = await despues(CerrarSesion());

    expect(estado, isA<SinSesion>());
    expect(servidor.sesiones, isEmpty);
  });

  test('cerrar sesion sin red igual vuelve al inicio', () async {
    await despues(Registrarse('jonathan', 'contrasena123'));
    servidor.caido = true;

    expect(await despues(CerrarSesion()), isA<SinSesion>());
  });

  test('un invitado puede volver a la pantalla de cuenta', () async {
    await despues(JugarSinCuenta());

    expect(await despues(CerrarSesion()), isA<SinSesion>());
  });

  test('borrar la cuenta con la contrasena correcta', () async {
    await despues(Registrarse('jonathan', 'contrasena123'));

    final estado = await despues(BorrarCuenta('contrasena123'));

    expect(estado, isA<SinSesion>());
    expect(servidor.cuentas, isEmpty);
  });

  test('borrar con la contrasena mala sigue dentro con el error', () async {
    await despues(Registrarse('jonathan', 'contrasena123'));

    final estado = await despues(BorrarCuenta('equivocada'));

    expect(estado, isA<ConCuenta>());
    expect((estado as ConCuenta).error, contains('no coincide'));
    expect(servidor.cuentas, contains('jonathan'));
  });
}
