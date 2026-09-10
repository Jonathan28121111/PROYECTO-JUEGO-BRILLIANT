enum Tipo { rojo, amarillo, verde, azul, morado }

class Zona {
  final int id;
  final Tipo tipo;
  final List<int> valores;

  const Zona(this.id, this.tipo, this.valores);

  bool esValida() {
    for (final n in valores) {
      if (n < 1 || n > 6) {
        return false;
      }
    }
    switch (tipo) {
      case Tipo.rojo:
      case Tipo.amarillo:
        return valores.toSet().length == valores.length;
      case Tipo.azul:
        return valores.toSet().length <= 1;
      case Tipo.morado:
        return valores.toSet().length <= 2;
      case Tipo.verde:
        return true;
    }
  }

  bool aceptaNumero(int numero) {
    return Zona(id, tipo, [...valores, numero]).esValida();
  }
}