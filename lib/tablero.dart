import 'nivel.dart';
import 'tipo_zona.dart';

const int hueco = 0;

class Tablero {
  final List<List<int>> zonasPorCelda;
  final Map<int, Tipo> coloresPorZona;
  final List<List<int?>> valores;

  final Map<Tipo, List<int>> puntosPorZona;

  Tablero(
    this.zonasPorCelda,
    this.coloresPorZona,
    this.valores, {
    this.puntosPorZona = const {},
  });

  static const List<(int, int)> anclasNivel1 = [
    (0, 2), (1, 5), (3, 1), (3, 4), (5, 2), (6, 4),
  ];

  factory Tablero.deNivel(Nivel nivel) {
    return Tablero(
      nivel.zonasPorCelda,
      nivel.coloresPorZona,
      <List<int?>>[
        for (final fila in nivel.zonasPorCelda) <int?>[for (final _ in fila) null],
      ],
      puntosPorZona: nivel.puntos,
    );
  }

  bool esHueco(int fila, int columna) => zonasPorCelda[fila][columna] == hueco;

  Tipo tipoDe(int fila, int columna) =>
      coloresPorZona[zonasPorCelda[fila][columna]]!;

  factory Tablero.nivel1() {
    return Tablero(
      nivel1.zonasPorCelda,
      nivel1.coloresPorZona,
      [
        [1, 5, 2, 6, 3, 6, 5],
        [2, 5, 2, 2, 3, 6, 2],
        [3, 2, 3, 2, 3, 2, 4],
        [6, 1, 4, 3, 3, 3, 6],
        [1, 4, 1, 4, 1, 2, 4],
        [5, 6, 4, 3, 4, 4, 4],
        [2, 1, 1, 6, 5, 4, 6],
      ],
      puntosPorZona: nivel1.puntos,
    );
  }

  factory Tablero.nivel1Inicial() => Tablero.deNivel(nivel1);

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
    return Zona(id, tipo, encontrados, puntosPropios: puntosPorZona[tipo]);
  }

  List<Zona> zonas() {
    final ids = coloresPorZona.keys.toList()..sort();
    return ids.map(zona).toList();
  }

  bool tieneVecinoCon(int fila, int columna, int numero) {
    const vecinas = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final (desplazaFila, desplazaColumna) in vecinas) {
      final f = fila + desplazaFila;
      final c = columna + desplazaColumna;
      if (f < 0 || f >= valores.length) continue;
      if (c < 0 || c >= valores[f].length) continue;
      if (valores[f][c] == numero) return true;
    }
    return false;
  }

  List<(int, int)> celdasPosibles(int numero, int companero) {
    final posibles = <(int, int)>[];
    for (var fila = 0; fila < valores.length; fila++) {
      for (var columna = 0; columna < valores[fila].length; columna++) {
        if (esHueco(fila, columna)) continue;
        if (valores[fila][columna] != null) continue;
        if (!tieneVecinoCon(fila, columna, companero)) continue;
        if (!zona(zonasPorCelda[fila][columna]).aceptaNumero(numero)) continue;
        posibles.add((fila, columna));
      }
    }
    return posibles;
  }

  bool zonaCompleta(int id) {
    for (var fila = 0; fila < zonasPorCelda.length; fila++) {
      for (var columna = 0; columna < zonasPorCelda[fila].length; columna++) {
        if (zonasPorCelda[fila][columna] == id &&
            valores[fila][columna] == null) {
          return false;
        }
      }
    }
    return true;
  }

  List<Zona> zonasCompletas() =>
      zonas().where((z) => zonaCompleta(z.id) && z.esValida()).toList();

  int get puntos =>
      zonasCompletas().fold(0, (suma, zona) => suma + zona.puntos.first);

  bool estaCompleto() {
    for (var fila = 0; fila < valores.length; fila++) {
      for (var columna = 0; columna < valores[fila].length; columna++) {
        if (esHueco(fila, columna)) continue;
        if (valores[fila][columna] == null) {
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
