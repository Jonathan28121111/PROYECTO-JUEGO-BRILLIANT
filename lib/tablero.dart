import 'tipo_zona.dart';

class Tablero {
  final List<List<int>> zonasPorCelda;
  final Map<int, Tipo> coloresPorZona;
  final List<List<int?>> valores;

  Tablero(this.zonasPorCelda, this.coloresPorZona, this.valores);

  static const List<(int, int)> anclasNivel1 = [
    (0, 2), (1, 5), (3, 1), (3, 4), (5, 2), (6, 4),
  ];

  Tipo tipoDe(int fila, int columna) =>
      coloresPorZona[zonasPorCelda[fila][columna]]!;

  factory Tablero.nivel1() {
    return Tablero(
      [
        [1, 2, 3, 4, 4, 4, 1],
        [2, 2, 3, 3, 4, 4, 6],
        [2, 7, 7, 3, 4, 6, 6],
        [2, 7, 8, 1, 6, 6, 6],
        [2, 7, 8, 8, 10, 10, 11],
        [7, 7, 8, 10, 10, 11, 11],
        [1, 8, 8, 10, 10, 11, 1],
      ],
      {
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
      [
        [1, 5, 2, 6, 3, 6, 5],
        [2, 5, 2, 2, 3, 6, 2],
        [3, 2, 3, 2, 3, 2, 4],
        [6, 1, 4, 3, 3, 3, 6],
        [1, 4, 1, 4, 1, 2, 4],
        [5, 6, 4, 3, 4, 4, 4],
        [2, 1, 1, 6, 5, 4, 6],
      ],
    );
  }

  factory Tablero.nivel1Inicial() {
    final completo = Tablero.nivel1();
    return Tablero(
      completo.zonasPorCelda,
      completo.coloresPorZona,
      <List<int?>>[
        for (final fila in completo.valores) <int?>[for (final _ in fila) null],
      ],
    );
  }

  Zona zona(int id) {
    final tipo = coloresPorZona[id];
    if (tipo == null) {
      throw ArgumentError('No existe la zona $id');
    }

    final encontrados = <int>[];
    for (var fila = 0; fila < zonasPorCelda.length; fila++) {
      for (var columna = 0; columna < zonasPorCelda[fila].length; columna++) {
        if (zonasPorCelda[fila][columna] == id) {
          final valor = valores[fila][columna];
          if (valor != null) {
            encontrados.add(valor);
          }
        }
      }
    }
    return Zona(id, tipo, encontrados);
  }

  List<Zona> zonas() {
    final ids = coloresPorZona.keys.toList()..sort();
    return ids.map(zona).toList();
  }

  bool estaCompleto() {
    for (final fila in valores) {
      for (final valor in fila) {
        if (valor == null) {
          return false;
        }
      }
    }
    return true;
  }

  bool esValido() {
    return zonas().every((z) => z.esValida());
  }
}