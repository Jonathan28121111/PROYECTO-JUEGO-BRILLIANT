import 'dart:math';

class Dados {
  final int primero;
  final int segundo;

  const Dados(this.primero, this.segundo);

  factory Dados.tirar(Random azar) =>
      Dados(azar.nextInt(6) + 1, azar.nextInt(6) + 1);
}