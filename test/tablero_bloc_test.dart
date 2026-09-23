import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tablero_bloc.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

Tablero tableroAMedias() {
  return Tablero(
    [
      [Tipo.rojo, Tipo.rojo],
    ],
    [
      [1, 1],
    ],
    [
      [1, null],
    ],
  );
}

void main() {
  group('la puerta de los valores iniciales', () {
    test('arranca sin iniciar y sin permitir avanzar', () async {
      final bloc = TableroBloc();

      expect(bloc.state, isA<TableroSinIniciar>());
      expect(bloc.state.puedeAvanzar, false);

      await bloc.close();
    });

    test('ignora una jugada mientras no haya valores iniciales', () async {
      final bloc = TableroBloc();
      final emitidos = <TableroState>[];
      final sub = bloc.stream.listen(emitidos.add);

      bloc.add(NumeroColocado(0, 1, 2));
      await Future<void>.delayed(Duration.zero);

      expect(emitidos, isEmpty);
      expect(bloc.state, isA<TableroSinIniciar>());
      expect(bloc.state.puedeAvanzar, false);

      await sub.cancel();
      await bloc.close();
    });

    test('al proporcionar los valores iniciales habilita avanzar', () async {
      final bloc = TableroBloc();

      bloc.add(ValoresInicialesProporcionados(tableroAMedias()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<TableroEnJuego>());
      expect(bloc.state.puedeAvanzar, true);

      await bloc.close();
    });
  });

  group('jugadas una vez iniciado', () {
    test('acepta un número que respeta la regla de la zona', () async {
      final bloc = TableroBloc();
      bloc.add(ValoresInicialesProporcionados(tableroAMedias()));
      await Future<void>.delayed(Duration.zero);

      bloc.add(NumeroColocado(0, 1, 2));
      await Future<void>.delayed(Duration.zero);

      final estado = bloc.state;
      expect(estado, isA<TableroResuelto>());
      expect((estado as TableroResuelto).tablero.valores[0][1], 2);

      await bloc.close();
    });

    test('rechaza un número que rompe la regla de la zona', () async {
      final bloc = TableroBloc();
      bloc.add(ValoresInicialesProporcionados(tableroAMedias()));
      await Future<void>.delayed(Duration.zero);

      bloc.add(NumeroColocado(0, 1, 1));
      await Future<void>.delayed(Duration.zero);

      final estado = bloc.state;
      expect(estado, isA<TableroEnJuego>());
      expect((estado as TableroEnJuego).tablero.valores[0][1], null);

      await bloc.close();
    });

    test('no pisa una celda que ya tiene valor', () async {
      final bloc = TableroBloc();
      bloc.add(ValoresInicialesProporcionados(tableroAMedias()));
      await Future<void>.delayed(Duration.zero);

      bloc.add(NumeroColocado(0, 0, 4));
      await Future<void>.delayed(Duration.zero);

      final estado = bloc.state;
      expect(estado, isA<TableroEnJuego>());
      expect((estado as TableroEnJuego).tablero.valores[0][0], 1);

      await bloc.close();
    });

    test('un tablero inicial ya completo y válido queda resuelto', () async {
      final bloc = TableroBloc();

      bloc.add(ValoresInicialesProporcionados(Tablero.nivel1()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<TableroResuelto>());
      expect(bloc.state.puedeAvanzar, true);

      await bloc.close();
    });
  });
}