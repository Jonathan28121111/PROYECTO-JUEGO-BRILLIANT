import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'dados.dart';
import 'nivel.dart';
import 'tablero.dart';

sealed class TableroEvent {}

class ValoresInicialesProporcionados extends TableroEvent {
  final Tablero tablero;

  ValoresInicialesProporcionados(this.tablero);
}

class NivelElegido extends TableroEvent {
  final Nivel nivel;

  NivelElegido(this.nivel);
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
  final Nivel? nivel;

  const TableroSinIniciar([this.nivel]);
}

class TableroEnJuego extends TableroState {
  final Tablero tablero;
  final Dados? dados;
  final int? elegido;
  final Nivel nivel;

  TableroEnJuego(this.tablero, {this.dados, this.elegido, this.nivel = nivel1});

  @override
  bool get puedeAvanzar => true;

  List<(int, int)> get posibles {
    final tirada = dados;
    final numero = elegido;
    if (tirada == null || numero == null) {
      return const [];
    }
    return tablero.celdasPosibles(numero, tirada.companeroDe(numero));
  }

  bool get hayJugada {
    final tirada = dados;
    if (tirada == null) {
      return false;
    }
    return tablero.celdasPosibles(tirada.primero, tirada.segundo).isNotEmpty ||
        tablero.celdasPosibles(tirada.segundo, tirada.primero).isNotEmpty;
  }

  bool get puedeTirar => dados == null || !hayJugada;
}

class TableroResuelto extends TableroState {
  final Tablero tablero;
  final Nivel nivel;

  TableroResuelto(this.tablero, {this.nivel = nivel1});

  @override
  bool get puedeAvanzar => true;
}

class TableroBloc extends Bloc<TableroEvent, TableroState> {
  final Random _azar;
  Nivel _nivel = nivel1;

  TableroBloc({Random? azar})
      : _azar = azar ?? Random(),
        super(const TableroSinIniciar()) {
    on<NivelElegido>((event, emit) {
      if (state is! TableroSinIniciar) {
        return;
      }
      _nivel = event.nivel;
      emit(TableroSinIniciar(event.nivel));
    });

    on<ValoresInicialesProporcionados>((event, emit) {
      emit(_estadoSegun(event.tablero));
    });

    on<DadosTirados>((event, emit) {
      final actual = state;
      if (actual is! TableroEnJuego) {
        return;
      }
      if (!actual.puedeTirar) {
        return;
      }
      emit(TableroEnJuego(
        actual.tablero,
        dados: Dados.tirar(_azar),
        nivel: _nivel,
      ));
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
        nivel: _nivel,
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
      return TableroResuelto(tablero, nivel: _nivel);
    }
    return TableroEnJuego(tablero, nivel: _nivel);
  }
}