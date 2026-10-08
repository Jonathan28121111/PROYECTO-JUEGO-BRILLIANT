import 'package:flutter/material.dart';

import 'colores.dart';
import 'tipo_zona.dart';

class Regla {
  final Tipo tipo;
  final String simbolo;
  final String descripcion;
  final List<int> puntos;

  const Regla(this.tipo, this.simbolo, this.descripcion, this.puntos);
}

const List<Regla> reglasIzquierda = [
  Regla(Tipo.rojo, '≠', 'Todos distintos', [6, 4, 2]),
  Regla(Tipo.amarillo, '≠', 'Todos distintos,\ncasillas separadas', [8, 6, 4]),
  Regla(Tipo.azul, '=', 'Todos iguales', [7, 5, 3]),
];

const List<Regla> reglasDerecha = [
  Regla(Tipo.morado, 'XO', 'Solo dos valores', [6, 4, 2]),
  Regla(Tipo.verde, '?', 'Cualquier número', [4, 3, 2]),
];

class PanelReglas extends StatelessWidget {
  final List<Regla> reglas;

  const PanelReglas({super.key, required this.reglas});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final regla in reglas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _TarjetaRegla(regla: regla),
            ),
        ],
      ),
    );
  }
}

class _TarjetaRegla extends StatelessWidget {
  final Regla regla;

  const _TarjetaRegla({required this.regla});

  @override
  Widget build(BuildContext context) {
    final color = colorDe(regla.tipo);

    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            regla.simbolo,
            style: TextStyle(
              fontSize: regla.simbolo.length > 1 ? 17 : 24,
              fontWeight: FontWeight.bold,
              color: colorTextoSobre(color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          regla.descripcion,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, height: 1.2),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final punto in regla.puntos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38, width: 1.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$punto',
                    style: const TextStyle(
                      fontSize: 11,
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