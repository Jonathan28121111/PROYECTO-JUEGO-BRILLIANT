import 'package:flutter_bloc/flutter_bloc.dart';

import 'tablero.dart';

sealed class TableroEvent {}

class ValoresInicialesProporcionados extends TableroEvent {
  final Tablero tablero;

  ValoresInicialesProporcionados(this.tablero);
}

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

  TableroEnJuego(this.tablero);

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
  TableroBloc() : super(const TableroSinIniciar()) {
    on<ValoresInicialesProporcionados>((event, emit) {
      emit(_estadoSegun(event.tablero));
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
      emit(_estadoSegun(tablero));
    });
  }

  TableroState _estadoSegun(Tablero tablero) {
    if (tablero.estaCompleto() && tablero.esValido()) {
      return TableroResuelto(tablero);
    }
    return TableroEnJuego(tablero);
  }
}