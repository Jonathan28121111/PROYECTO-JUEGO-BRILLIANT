import 'package:flutter/material.dart';

import 'tablero.dart';
import 'tablero_interfaz.dart';

const Color verdePastel = Color(0xFFA5D6A7);
const Color verdePastelClaro = Color(0xFFEAF7EA);
const Color verdeTexto = Color(0xFF1B3D1E);

class PantallaAnclas extends StatefulWidget {
  const PantallaAnclas({super.key});

  @override
  State<PantallaAnclas> createState() => _PantallaAnclasState();
}

class _PantallaAnclasState extends State<PantallaAnclas> {
  final Tablero tablero = Tablero.nivel1Inicial();
  final Map<(int, int), int> numeros = {};
  bool arrastrando = false;

  int get total => Tablero.anclasNivel1.length;
  bool get completo => numeros.length == total;

  void _soltar((int, int) celda, int numero) {
    setState(() {
      numeros.removeWhere((_, puesto) => puesto == numero);
      numeros[celda] = numero;
    });
  }

  void _quitar((int, int) celda) {
    setState(() => numeros.remove(celda));
  }

  @override
  Widget build(BuildContext context) {
    final usados = numeros.values.toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Juego Brilliant')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: TableroInterfaz(
                  tablero: tablero,
                  anclas: Tablero.anclasNivel1,
                  numeros: numeros,
                  arrastrando: arrastrando,
                  alSoltar: _soltar,
                  alQuitar: _quitar,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var n = 1; n <= 6; n++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: usados.contains(n)
                        ? const _Hueco()
                        : _Ficha(
                            numero: n,
                            alEmpezar: () =>
                                setState(() => arrastrando = true),
                            alTerminar: () =>
                                setState(() => arrastrando = false),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _BotonProgreso(
              puestos: numeros.length,
              total: total,
              alTocar: completo
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.white,
                          content: Text(
                            'Números ancla listos',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonProgreso extends StatelessWidget {
  final int puestos;
  final int total;
  final VoidCallback? alTocar;

  const _BotonProgreso({
    required this.puestos,
    required this.total,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final completo = puestos == total;

    return Container(
      width: 300,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: verdePastelClaro),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: puestos / total),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: valor,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: completo ? const Color(0xFF43A047) : verdePastel,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: alTocar,
                child: Center(
                  child: Text(
                    completo
                        ? '¡Listo! Empezar a jugar'
                        : '$puestos de $total colocados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: completo ? Colors.white : verdeTexto,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  final int numero;
  final VoidCallback alEmpezar;
  final VoidCallback alTerminar;

  const _Ficha({
    required this.numero,
    required this.alEmpezar,
    required this.alTerminar,
  });

  @override
  Widget build(BuildContext context) {
    final cuerpo = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$numero',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );

    return Draggable<int>(
      data: numero,
      onDragStarted: alEmpezar,
      onDragEnd: (_) => alTerminar(),
      feedback: Material(color: Colors.transparent, child: cuerpo),
      childWhenDragging: Opacity(opacity: 0.3, child: cuerpo),
      child: cuerpo,
    );
  }
}

class _Hueco extends StatelessWidget {
  const _Hueco();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}