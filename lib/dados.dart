import 'dart:math';

class Dados {
  final int primero;
  final int segundo;

  const Dados(this.primero, this.segundo);

  factory Dados.tirar(Random azar) =>
      Dados(azar.nextInt(6) + 1, azar.nextInt(6) + 1);

  bool contiene(int numero) => numero == primero || numero == segundo;

  int companeroDe(int elegido) {
    if (elegido == primero) return segundo;
    if (elegido == segundo) return primero;
    throw ArgumentError('$elegido no salió en esta tirada');
  }
}