import 'package:flutter/material.dart';

import 'colores.dart';
import 'nivel.dart';
import 'tipo_zona.dart';

class Regla {
  final Tipo tipo;
  final String simbolo;
  final String descripcion;

  const Regla(this.tipo, this.simbolo, this.descripcion);
}

/// La tarjeta que le toca a cada tipo de zona.
const Map<Tipo, Regla> reglaPorTipo = {
  Tipo.rojo: Regla(Tipo.rojo, '≠', 'Todos distintos'),
  Tipo.amarillo: Regla(Tipo.amarillo, '≠', 'Todos distintos'),
  Tipo.azul: Regla(Tipo.azul, '=', 'Todos iguales'),
  Tipo.morado: Regla(Tipo.morado, 'XO', 'Solo dos valores'),
  Tipo.verde: Regla(Tipo.verde, '?', 'Cualquier número'),
  Tipo.blanco: Regla(Tipo.blanco, '=', 'Todos iguales'),
  Tipo.naranja1a3: Regla(Tipo.naranja1a3, '1-3', 'Solo del 1 al 3'),
  Tipo.naranja4a6: Regla(Tipo.naranja4a6, '4-6', 'Solo del 4 al 6'),
};

const List<Regla> reglasIzquierda = [
  Regla(Tipo.rojo, '≠', 'Todos distintos'),
  Regla(Tipo.amarillo, '≠', 'Todos distintos,\ncasillas separadas'),
  Regla(Tipo.azul, '=', 'Todos iguales'),
];

const List<Regla> reglasDerecha = [
  Regla(Tipo.morado, 'XO', 'Solo dos valores'),
  Regla(Tipo.verde, '?', 'Cualquier número'),
];

/// Las reglas que aplican en un nivel, repartidas entre los dos paneles.
(List<Regla>, List<Regla>) reglasDe(Nivel nivel) {
  final reglas = [for (final tipo in nivel.tiposUsados) reglaPorTipo[tipo]!];
  final corte = (reglas.length / 2).ceil();
  return (reglas.sublist(0, corte), reglas.sublist(corte));
}

class PanelReglas extends StatelessWidget {
  final List<Regla> reglas;

  /// Los puntajes del nivel. Si no vienen se usan los de `puntosPorTipo`.
  final Map<Tipo, List<int>> puntos;

  const PanelReglas({
    super.key,
    required this.reglas,
    this.puntos = const {},
  });

  @override
  Widget build(BuildContext context) {
    // El nivel 4 usa siete tipos de zona y no caben cuatro tarjetas grandes
    // en la altura del tablero.
    final compacto = reglas.length >= 4;

    return SingleChildScrollView(
      child: Column(
        children: [
          for (final regla in reglas)
            Padding(
              padding: EdgeInsets.symmetric(vertical: compacto ? 4 : 8),
              child: _TarjetaRegla(
                regla: regla,
                puntos: puntos[regla.tipo] ?? puntosPorTipo[regla.tipo]!,
                compacto: compacto,
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaRegla extends StatelessWidget {
  final Regla regla;
  final List<int> puntos;
  final bool compacto;

  const _TarjetaRegla({
    required this.regla,
    required this.puntos,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorDe(regla.tipo);
    final lado = compacto ? 36.0 : 46.0;
    final ladoPunto = compacto ? 17.0 : 20.0;

    return Column(
      children: [
        Container(
          width: lado,
          height: lado,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            regla.simbolo,
            style: TextStyle(
              fontSize: regla.simbolo.length > 1
                  ? (compacto ? 13 : 17)
                  : (compacto ? 19 : 24),
              fontWeight: FontWeight.bold,
              color: colorTextoSobre(color),
            ),
          ),
        ),
        SizedBox(height: compacto ? 2 : 4),
        Text(
          regla.descripcion,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: compacto ? 9 : 10, height: 1.15),
        ),
        SizedBox(height: compacto ? 2 : 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final punto in puntos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: ladoPunto,
                  height: ladoPunto,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38, width: 1.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$punto',
                    style: TextStyle(
                      fontSize: compacto ? 10 : 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
