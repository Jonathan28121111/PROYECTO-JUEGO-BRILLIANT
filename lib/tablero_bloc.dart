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

class NumeroElegido extends TableroEvent {
  final int numero;

  NumeroElegido(this.numero);
}

class NumeroColocado extends TableroEvent {
  final int fila;
  final int columna;

  NumeroColocado(this.fila, this.columna);
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
  final int? elegido;

  TableroEnJuego(this.tablero, {this.dados, this.elegido});

  @override
  bool get puedeAvanzar => true;

  /// Dónde se puede escribir con la tirada y el número elegidos.
  List<(int, int)> get posibles {
    final tirada = dados;
    final numero = elegido;
    if (tirada == null || numero == null) {
      return const [];
    }
    return tablero.celdasPosibles(numero, tirada.companeroDe(numero));
  }

  /// ¿Queda alguna jugada con esta tirada, usando cualquiera de los dos dados?
  bool get hayJugada {
    final tirada = dados;
    if (tirada == null) {
      return false;
    }
    return tablero.celdasPosibles(tirada.primero, tirada.segundo).isNotEmpty ||
        tablero.celdasPosibles(tirada.segundo, tirada.primero).isNotEmpty;
  }

  /// Solo se puede tirar si todavía no tiraste, o si con lo que salió no hay
  /// forma de jugar.
  bool get puedeTirar => dados == null || !hayJugada;
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
      final actual = state;
      // Sin valores iniciales no se avanza: tampoco se tira.
      if (actual is! TableroEnJuego) {
        return;
      }
      // Si hay jugada pendiente, primero hay que colocar.
      if (!actual.puedeTirar) {
        return;
      }
      emit(TableroEnJuego(actual.tablero, dados: Dados.tirar(_azar)));
    });

    on<NumeroElegido>((event, emit) {
      final actual = state;
      if (actual is! TableroEnJuego) {
        return;
      }
      final dados = actual.dados;
      if (dados == null || !dados.contiene(event.numero)) {
        return;
      }
      emit(TableroEnJuego(
        actual.tablero,
        dados: dados,
        elegido: event.numero,
      ));
    });

    on<NumeroColocado>((event, emit) {
      final actual = state;
      if (actual is! TableroEnJuego) {
        return;
      }

      final elegido = actual.elegido;
      if (elegido == null) {
        return;
      }
      if (!actual.posibles.contains((event.fila, event.columna))) {
        return;
      }

      actual.tablero.valores[event.fila][event.columna] = elegido;
      emit(_estadoSegun(actual.tablero));
    });
  }

  TableroState _estadoSegun(Tablero tablero) {
    if (tablero.estaCompleto() && tablero.esValido()) {
      return TableroResuelto(tablero);
    }
    return TableroEnJuego(tablero);
  }
}