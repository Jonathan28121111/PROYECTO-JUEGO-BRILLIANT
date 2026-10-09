import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tablero_bloc.dart';
import 'package:pruebas_numeros/tipo_zona.dart';

class AzarFijo implements Random {
  final List<int> valores;
  int _indice = 0;

  AzarFijo(this.valores);

  @override
  int nextInt(int max) => valores[_indice++ % valores.length] - 1;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

Future<void> procesar() => Future<void>.delayed(Duration.zero);

/// Una fila de tres casillas de una sola zona, con un 2 ya puesto a la izquierda.
Tablero tableroDePrueba(Tipo tipo) {
  return Tablero(
    [
      [1, 1, 1],
    ],
    {1: tipo},
    [
      [2, null, null],
    ],
  );
}

TableroEnJuego enJuego(TableroBloc bloc) => bloc.state as TableroEnJuego;

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

      bloc.add(NumeroColocado(0, 1));
      await procesar();

      expect(emitidos, isEmpty);
      expect(bloc.state, isA<TableroSinIniciar>());

      await sub.cancel();
      await bloc.close();
    });

    test('tampoco deja tirar los dados antes de empezar', () async {
      final bloc = TableroBloc();
      final emitidos = <TableroState>[];
      final sub = bloc.stream.listen(emitidos.add);

      bloc.add(DadosTirados());
      await procesar();

      expect(emitidos, isEmpty);

      await sub.cancel();
      await bloc.close();
    });

    test('al proporcionar los valores iniciales habilita avanzar', () async {
      final bloc = TableroBloc();

      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(Tipo.verde)));
      await procesar();

      expect(bloc.state, isA<TableroEnJuego>());
      expect(bloc.state.puedeAvanzar, true);

      await bloc.close();
    });

    test('un tablero inicial ya completo y valido queda resuelto', () async {
      final bloc = TableroBloc();

      bloc.add(ValoresInicialesProporcionados(Tablero.nivel1()));
      await procesar();

      expect(bloc.state, isA<TableroResuelto>());

      await bloc.close();
    });
  });

  group('los dados', () {
    test('la tirada queda guardada en el estado', () async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(Tipo.verde)));
      await procesar();

      bloc.add(DadosTirados());
      await procesar();

      expect(enJuego(bloc).dados?.primero, 3);
      expect(enJuego(bloc).dados?.segundo, 2);

      await bloc.close();
    });

    test('solo se puede elegir un numero que haya salido', () async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(Tipo.verde)));
      await procesar();
      bloc.add(DadosTirados());
      await procesar();

      bloc.add(NumeroElegido(5));
      await procesar();
      expect(enJuego(bloc).elegido, null);

      bloc.add(NumeroElegido(3));
      await procesar();
      expect(enJuego(bloc).elegido, 3);

      await bloc.close();
    });
  });

  group('colocar un numero', () {
    Future<TableroBloc> listoParaJugar(Tipo tipo, List<int> tirada) async {
      final bloc = TableroBloc(azar: AzarFijo(tirada));
      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(tipo)));
      await procesar();
      bloc.add(DadosTirados());
      await procesar();
      bloc.add(NumeroElegido(tirada.first));
      await procesar();
      return bloc;
    }

    test('escribe el numero en una casilla valida', () async {
      final bloc = await listoParaJugar(Tipo.verde, [3, 2]);

      bloc.add(NumeroColocado(0, 1));
      await procesar();

      expect(enJuego(bloc).tablero.valores[0][1], 3);

      await bloc.close();
    });

    test('rechaza una casilla que no toca al numero companero', () async {
      final bloc = await listoParaJugar(Tipo.verde, [3, 2]);

      // (0,2) solo toca a (0,1), que está vacía: no hay ningún 2 al lado.
      bloc.add(NumeroColocado(0, 2));
      await procesar();

      expect(enJuego(bloc).tablero.valores[0][2], null);

      await bloc.close();
    });

    test('no pisa una casilla que ya tiene valor', () async {
      final bloc = await listoParaJugar(Tipo.verde, [3, 2]);

      bloc.add(NumeroColocado(0, 0));
      await procesar();

      expect(enJuego(bloc).tablero.valores[0][0], 2);

      await bloc.close();
    });

    test('rechaza un numero que rompe la regla de la zona', () async {
      // Zona roja: todos distintos, y el 2 ya está en el tablero.
      final bloc = await listoParaJugar(Tipo.rojo, [2, 2]);

      bloc.add(NumeroColocado(0, 1));
      await procesar();

      expect(enJuego(bloc).tablero.valores[0][1], null);

      await bloc.close();
    });

    test('no se puede colocar sin haber elegido un numero', () async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(Tipo.verde)));
      await procesar();
      bloc.add(DadosTirados());
      await procesar();

      bloc.add(NumeroColocado(0, 1));
      await procesar();

      expect(enJuego(bloc).tablero.valores[0][1], null);

      await bloc.close();
    });

    test('despues de colocar hay que volver a tirar', () async {
      final bloc = await listoParaJugar(Tipo.verde, [3, 2]);

      bloc.add(NumeroColocado(0, 1));
      await procesar();

      expect(enJuego(bloc).dados, null);
      expect(enJuego(bloc).elegido, null);

      await bloc.close();
    });
  });
    group('cuando se puede volver a tirar', () {
    test('no deja tirar de nuevo si hay jugada pendiente', () async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(Tipo.verde)));
      await procesar();
      bloc.add(DadosTirados());
      await procesar();

      expect(enJuego(bloc).hayJugada, true);
      expect(enJuego(bloc).puedeTirar, false);

      final emitidos = <TableroState>[];
      final sub = bloc.stream.listen(emitidos.add);

      bloc.add(DadosTirados());
      await procesar();

      expect(emitidos, isEmpty);

      await sub.cancel();
      await bloc.close();
    });

    test('deja tirar de nuevo si no hay ninguna jugada', () async {
      // El tablero solo tiene un 2: con 5 y 6 no se puede escribir nada.
      final bloc = TableroBloc(azar: AzarFijo([5, 6]));
      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(Tipo.verde)));
      await procesar();
      bloc.add(DadosTirados());
      await procesar();

      expect(enJuego(bloc).hayJugada, false);
      expect(enJuego(bloc).puedeTirar, true);

      final emitidos = <TableroState>[];
      final sub = bloc.stream.listen(emitidos.add);

      bloc.add(DadosTirados());
      await procesar();

      expect(emitidos, hasLength(1));

      await sub.cancel();
      await bloc.close();
    });

    test('despues de colocar se habilita tirar otra vez', () async {
      final bloc = TableroBloc(azar: AzarFijo([3, 2]));
      bloc.add(ValoresInicialesProporcionados(tableroDePrueba(Tipo.verde)));
      await procesar();
      bloc.add(DadosTirados());
      await procesar();
      bloc.add(NumeroElegido(3));
      await procesar();
      bloc.add(NumeroColocado(0, 1));
      await procesar();

      expect(enJuego(bloc).puedeTirar, true);

      await bloc.close();
    });
  });
}