enum Region { rojo, amarillo, verde, azul, morado }

const List<List<Region>> tablero = [
  [Region.amarillo, Region.verde, Region.azul, Region.morado, Region.morado, Region.morado, Region.amarillo],
  [Region.verde, Region.verde, Region.azul, Region.azul, Region.morado, Region.morado, Region.verde],
  [Region.verde, Region.rojo, Region.rojo, Region.azul, Region.morado, Region.verde, Region.verde],
  [Region.verde, Region.rojo, Region.morado, Region.amarillo, Region.verde, Region.verde, Region.verde],
  [Region.verde, Region.rojo, Region.morado, Region.morado, Region.rojo, Region.rojo, Region.azul],
  [Region.rojo, Region.rojo, Region.morado, Region.rojo, Region.rojo, Region.azul, Region.azul],
  [Region.amarillo, Region.morado, Region.morado, Region.rojo, Region.rojo, Region.azul, Region.amarillo],
];

const List<List<int?>> valores = [
  [1, 5, 2, 6, 3, 6, 5],
  [2, 5, 2, 2, 3, 6, 2],
  [3, 2, 3, 2, 3, 2, 4],
  [6, 1, 4, 3, 3, 3, 6],
  [1, 4, 1, 4, 1, 2, 4],
  [5, 6, 4, 3, 4, 4, 4],
  [2, 1, 1, 6, 5, 4, 6],
];

List<int> valoresDe(Region region) {
  final resultado = <int>[];
  for (var fila = 0; fila < tablero.length; fila++) {
    for (var columna = 0; columna < tablero[fila].length; columna++) {
      if (tablero[fila][columna] == region) {
        final valor = valores[fila][columna];
        if (valor != null) {
          resultado.add(valor);
        }
      }
    }
  }
  return resultado;
}