
enum Tipo {
  rojo,
  amarillo,
  verde,
  azul,
  morado,
  blanco,
  naranja1a3,
  naranja4a6,
}

const Map<Tipo, List<int>> puntosPorTipo = {
  Tipo.rojo: [6, 4, 2],
  Tipo.amarillo: [8, 6, 4],
  Tipo.azul: [7, 5, 3],
  Tipo.morado: [6, 4, 2],
  Tipo.verde: [4, 3, 2],
  Tipo.blanco: [3, 2, 1],
  Tipo.naranja1a3: [6, 4, 2],
  Tipo.naranja4a6: [6, 4, 2],
};

const Map<Tipo, (int, int)> rangoPorTipo = {
  Tipo.naranja1a3: (1, 3),
  Tipo.naranja4a6: (4, 6),
};

class Zona {
  final int id;
  final Tipo tipo;
  final List<int> valores;

  final List<int>? puntosPropios;

  const Zona(this.id, this.tipo, this.valores, {this.puntosPropios});

  List<int> get puntos => puntosPropios ?? puntosPorTipo[tipo]!;

  (int, int) get rango => rangoPorTipo[tipo] ?? (1, 6);

  bool esValida() {
    final (minimo, maximo) = rango;
    for (final n in valores) {
      if (n < minimo || n > maximo) {
        return false;
      }
    }
    switch (tipo) {
      case Tipo.rojo:
      case Tipo.amarillo:
        return valores.toSet().length == valores.length;
      case Tipo.azul:
      case Tipo.blanco:
        return valores.toSet().length <= 1;
      case Tipo.morado:
        return valores.toSet().length <= 2;
      case Tipo.verde:
      case Tipo.naranja1a3:
      case Tipo.naranja4a6:
        return true;
    }
  }

  bool aceptaNumero(int numero) {
    return Zona(id, tipo, [...valores, numero], puntosPropios: puntosPropios)
        .esValida();
  }
}
