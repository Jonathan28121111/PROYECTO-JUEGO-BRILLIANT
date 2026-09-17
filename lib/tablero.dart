import 'tipo_zona.dart';

class Tablero {
  final List<List<Tipo>> tipos;
  final List<List<int>> zonasPorCelda;
  final List<List<int?>> valores;

  Tablero(this.tipos, this.zonasPorCelda, this.valores);

  factory Tablero.nivel1() {
    const r = Tipo.rojo;
    const a = Tipo.amarillo;
    const v = Tipo.verde;
    const z = Tipo.azul;
    const m = Tipo.morado;

    return Tablero(
      [
        [a, v, z, m, m, m, a],
        [v, v, z, z, m, m, v],
        [v, r, r, z, m, v, v],
        [v, r, m, a, v, v, v],
        [v, r, m, m, r, r, z],
        [r, r, m, r, r, z, z],
        [a, m, m, r, r, z, a],
      ],
      [
        [1, 2, 3, 4, 4, 4, 1],
        [2, 2, 3, 3, 4, 4, 6],
        [2, 7, 7, 3, 4, 6, 6],
        [2, 7, 8, 1, 6, 6, 6],
        [2, 7, 8, 8, 10, 10, 11],
        [7, 7, 8, 10, 10, 11, 11],
        [1, 8, 8, 10, 10, 11, 1],
      ],
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

  Zona zona(int id) {
    Tipo? tipo;
    final encontrados = <int>[];
    for (var fila = 0; fila < zonasPorCelda.length; fila++) {
      for (var columna = 0; columna < zonasPorCelda[fila].length; columna++) {
        if (zonasPorCelda[fila][columna] == id) {
          tipo ??= tipos[fila][columna];
          final valor = valores[fila][columna];
          if (valor != null) {
            encontrados.add(valor);
          }
        }
      }
    }
    if (tipo == null) {
      throw ArgumentError('No existe la zona $id');
    }
    return Zona(id, tipo, encontrados);
  }

  List<Zona> zonas() {
    final ids = <int>{};
    for (final fila in zonasPorCelda) {
      ids.addAll(fila);
    }
    final lista = ids.toList()..sort();
    return lista.map(zona).toList();
  }

  List<int> valoresDe(Tipo tipo) {
    final resultado = <int>[];
    for (var fila = 0; fila < tipos.length; fila++) {
      for (var columna = 0; columna < tipos[fila].length; columna++) {
        if (tipos[fila][columna] == tipo) {
          final valor = valores[fila][columna];
          if (valor != null) {
            resultado.add(valor);
          }
        }
      }
    }
    return resultado;
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