import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'dados.dart';
import 'tablero.dart';

sealed class TableroEvent {}

class ValoresInicialesProporcionados extends TableroEvent {
  final Tablero tablero;

  ValoresInicialesProporcionados(this.tablero);
}

class DadosTirados extends TableroEvent {}

class NumeroColocado extends TableroEvent {
  final int fila;
  final int columna;
  final int numero;

  NumeroColocado(this.fila, this.columna, this.numero);
}

sealed class TableroState {
  const TableroState();

  bool get puedeAvanzar => false;
}

class TableroSinIniciar extends TableroState {
  const TableroSinIniciar();
}

class TableroEnJuego extends TableroState {
  final Tablero tablero;
  final Dados? dados;

  TableroEnJuego(this.tablero, {this.dados});

  @override
  bool get puedeAvanzar => true;
}

class TableroResuelto extends TableroState {
  final Tablero tablero;

  TableroResuelto(this.tablero);

  @override
  bool get puedeAvanzar => true;
}

class TableroBloc extends Bloc<TableroEvent, TableroState> {
  final Random _azar;

  TableroBloc({Random? azar})
      : _azar = azar ?? Random(),
        super(const TableroSinIniciar()) {
    on<ValoresInicialesProporcionados>((event, emit) {
      emit(_estadoSegun(event.tablero));
    });

    on<DadosTirados>((event, emit) {
      final estadoActual = state;
      // Sin valores iniciales no se avanza: tampoco se tira.
      if (estadoActual is! TableroEnJuego) {
        return;
      }
      emit(TableroEnJuego(estadoActual.tablero, dados: Dados.tirar(_azar)));
    });

    on<NumeroColocado>((event, emit) {
      final estadoActual = state;
      // Sin valores iniciales no se avanza: la jugada se descarta.
      if (estadoActual is! TableroEnJuego) {
        return;
      }

      final tablero = estadoActual.tablero;
      if (tablero.valores[event.fila][event.columna] != null) {
        return;
      }

      final idZona = tablero.zonasPorCelda[event.fila][event.columna];
      if (!tablero.zona(idZona).aceptaNumero(event.numero)) {
        return;
      }

      tablero.valores[event.fila][event.columna] = event.numero;
      emit(_estadoSegun(tablero, estadoActual.dados));
    });
  }

  TableroState _estadoSegun(Tablero tablero, [Dados? dados]) {
    if (tablero.estaCompleto() && tablero.esValido()) {
      return TableroResuelto(tablero);
    }
    return TableroEnJuego(tablero, dados: dados);
  }
}