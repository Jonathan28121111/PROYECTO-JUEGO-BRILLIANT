import 'tipo_zona.dart';

class Nivel {
  final int numero;
  final String nombre;
  final List<List<int>> zonasPorCelda;
  final Map<int, Tipo> coloresPorZona;
  final Map<Tipo, List<int>> puntos;
  final List<(int, int)> anclas;

  const Nivel({
    required this.numero,
    required this.nombre,
    required this.zonasPorCelda,
    required this.coloresPorZona,
    required this.anclas,
    this.puntos = const {},
  });

  bool get disponible => zonasPorCelda.isNotEmpty;

  int get filas => zonasPorCelda.length;
  int get columnas => zonasPorCelda.isEmpty ? 0 : zonasPorCelda.first.length;

  List<int> puntosDe(Tipo tipo) => puntos[tipo] ?? puntosPorTipo[tipo]!;

  List<Tipo> get tiposUsados {
    final usados = coloresPorZona.values.toSet();
    return Tipo.values.where(usados.contains).toList();
  }
}

const Nivel nivel1 = Nivel(
  numero: 1,
  nombre: 'Nivel 1',
  zonasPorCelda: [
    [1, 2, 3, 4, 4, 4, 1],
    [2, 2, 3, 3, 4, 4, 6],
    [2, 7, 7, 3, 4, 6, 6],
    [2, 7, 8, 1, 6, 6, 6],
    [2, 7, 8, 8, 10, 10, 11],
    [7, 7, 8, 10, 10, 11, 11],
    [1, 8, 8, 10, 10, 11, 1],
  ],
  coloresPorZona: {
    1: Tipo.amarillo,
    2: Tipo.verde,
    3: Tipo.azul,
    4: Tipo.morado,
    6: Tipo.verde,
    7: Tipo.rojo,
    8: Tipo.morado,
    10: Tipo.rojo,
    11: Tipo.azul,
  },
  puntos: {
    Tipo.amarillo: [8, 6, 4],
    Tipo.verde: [4, 3, 2],
    Tipo.azul: [7, 5, 3],
    Tipo.morado: [6, 4, 2],
    Tipo.rojo: [6, 4, 2],
  },
  anclas: [(0, 2), (1, 5), (3, 1), (3, 4), (5, 2), (6, 4)],
);

const Nivel nivel2 = Nivel(
  numero: 2,
  nombre: 'Nivel 2',
  zonasPorCelda: [
    [2, 2, 2, 10, 3, 3, 3],
    [2, 1, 4, 4, 4, 1, 3],
    [2, 5, 5, 4, 4, 6, 3],
    [5, 5, 5, 1, 6, 6, 6],
    [8, 5, 7, 7, 6, 6, 9],
    [8, 1, 7, 7, 7, 1, 9],
    [8, 8, 8, 10, 9, 9, 9],
  ],
  coloresPorZona: {
    1: Tipo.amarillo,
    2: Tipo.morado,
    3: Tipo.verde,
    4: Tipo.azul,
    5: Tipo.rojo,
    6: Tipo.rojo,
    7: Tipo.azul,
    8: Tipo.verde,
    9: Tipo.morado,
    10: Tipo.blanco,
  },
  puntos: {
    Tipo.amarillo: [6, 4, 2],
    Tipo.morado: [6, 4, 2],
    Tipo.verde: [4, 3, 2],
    Tipo.azul: [7, 5, 3],
    Tipo.rojo: [6, 4, 2],
    Tipo.blanco: [3, 2, 1],
  },
  anclas: [(0, 4), (2, 0), (3, 2), (4, 5), (5, 1), (6, 4)],
);

const Nivel nivel3 = Nivel(
  numero: 3,
  nombre: 'Nivel 3',
  zonasPorCelda: [
    [1, 1, 2, 3, 2, 1, 1],
    [3, 1, 2, 2, 2, 1, 3],
    [4, 4, 4, 2, 5, 5, 5],
    [4, 4, 4, 3, 5, 5, 5],
    [7, 6, 6, 6, 6, 6, 7],
    [7, 7, 7, 7, 7, 7, 7],
    [8, 8, 8, 3, 8, 8, 8],
  ],
  coloresPorZona: {
    1: Tipo.amarillo,
    2: Tipo.morado,
    3: Tipo.blanco,
    4: Tipo.rojo,
    5: Tipo.rojo,
    6: Tipo.azul,
    7: Tipo.verde,
    8: Tipo.morado,
  },
  puntos: {
    Tipo.amarillo: [7, 5, 3],
    Tipo.morado: [7, 5, 3],
    Tipo.blanco: [8, 6, 4],
    Tipo.rojo: [6, 4, 2],
    Tipo.azul: [7, 5, 3],
    Tipo.verde: [8, 6, 4],
  },
  anclas: [(1, 2), (1, 5), (3, 3), (4, 1), (4, 6), (6, 2)],
);

const Nivel nivel4 = Nivel(
  numero: 4,
  nombre: 'Nivel 4',
  zonasPorCelda: [
    [1, 1, 1, 1, 1, 1, 1],
    [2, 3, 4, 5, 4, 7, 2],
    [3, 3, 6, 6, 6, 7, 7],
    [2, 5, 4, 6, 4, 5, 2],
    [3, 3, 6, 6, 6, 7, 7],
    [2, 3, 4, 5, 4, 7, 2],
    [8, 8, 8, 8, 8, 8, 8],
  ],
  coloresPorZona: {
    1: Tipo.naranja4a6,
    2: Tipo.amarillo,
    3: Tipo.rojo,
    4: Tipo.azul,
    5: Tipo.verde,
    6: Tipo.morado,
    7: Tipo.rojo,
    8: Tipo.naranja1a3,
  },
  puntos: {
    Tipo.naranja4a6: [6, 4, 2],
    Tipo.naranja1a3: [6, 4, 2],
    Tipo.amarillo: [8, 6, 4],
    Tipo.rojo: [6, 4, 2],
    Tipo.azul: [8, 6, 4],
    Tipo.verde: [3, 2, 1],
    Tipo.morado: [7, 5, 3],
  },
  anclas: [(0, 4), (2, 2), (2, 5), (3, 0), (5, 4), (6, 1)],
);

const List<Nivel> nivelesOficiales = [nivel1, nivel2, nivel3, nivel4];
