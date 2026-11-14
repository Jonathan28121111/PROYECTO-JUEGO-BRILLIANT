import 'package:flutter/material.dart';

import 'colores.dart';
import 'dado_animado.dart';
import 'panel_reglas.dart';
import 'tipo_zona.dart';

const Color _texto = Color(0xFF111827);
const Color _secundario = Color(0xFF4B5563);
const Color _borde = Color(0xFFE5E7EB);

const TextStyle _cuerpo = TextStyle(fontSize: 16, height: 1.5, color: _texto);

Future<void> abrirComoJugar(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const PantallaComoJugar()));

class BotonComoJugar extends StatelessWidget {
  const BotonComoJugar({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('boton_como_jugar'),
    tooltip: 'Cómo jugar',
    icon: const Icon(Icons.help_outline_rounded),
    onPressed: () => abrirComoJugar(context),
  );
}

class PantallaComoJugar extends StatelessWidget {
  const PantallaComoJugar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo jugar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Llena el tablero con números del 1 al 6. Cada color es una '
                  'zona con su propia regla: cuando completas una zona '
                  'cumpliendo su regla, ganas sus puntos.',
                  style: _cuerpo,
                ),
                SizedBox(height: 24),
                _Paso(
                  numero: 1,
                  titulo: 'Pon tus anclas',
                  texto:
                      'Al empezar, arrastra los números del 1 al 6 a las '
                      'casillas que tienen estrella. Son tu punto de partida. '
                      'Si te equivocas, toca el número para quitarlo.',
                  dibujo: _Ancla(),
                ),
                _Paso(
                  numero: 2,
                  titulo: 'Elige un dado',
                  texto:
                      'Los dados se tiran solos. Toca uno: ese es el número '
                      'que vas a escribir. El otro dado dice dónde puedes '
                      'escribirlo.',
                  dibujo: _Dados(),
                ),
                _Paso(
                  numero: 3,
                  titulo: 'Escríbelo junto al otro número',
                  texto:
                      'La casilla tiene que estar pegada (arriba, abajo, a la '
                      'izquierda o a la derecha) a una casilla que ya tenga el '
                      'número del otro dado, y el número tiene que respetar la '
                      'regla de su zona. El juego te marca las casillas donde '
                      'sí se puede.',
                  dibujo: _Ejemplo(),
                ),
                _Paso(
                  numero: 4,
                  titulo: 'Si no hay dónde',
                  texto:
                      'Si con ninguno de los dos dados hay jugada, se vuelven a '
                      'tirar solos. En línea, pasas esa ronda.',
                ),
                SizedBox(height: 8),
                _Titulo('La regla de cada color'),
                SizedBox(height: 12),
                _Reglas(),
                SizedBox(height: 24),
                _Titulo('Los puntos'),
                SizedBox(height: 8),
                Text(
                  'Cada regla tiene tres números debajo: son los puntos de esa '
                  'zona. Jugando solo te llevas el primero. En línea, quien '
                  'completa la zona primero se lleva el mayor, el siguiente se '
                  'lleva el de en medio, y así. Las zonas completas se ven más '
                  'apagadas y llevan la inicial de quién las completó.',
                  style: _cuerpo,
                ),
                SizedBox(height: 24),
                _Titulo('Jugar en línea'),
                SizedBox(height: 8),
                Text(
                  'Crea una sala y comparte el código, o únete con el código '
                  'de alguien más (de 2 a 5 jugadores). Cada quien da Listo y '
                  'quien creó la sala empieza. Todos juegan con los mismos '
                  'dados, cada quien en su tablero, y puedes ver el tablero '
                  'de los demás tocando su nombre.',
                  style: _cuerpo,
                ),
                SizedBox(height: 8),
                Text(
                  'Gana quien llegue a la meta: 26 puntos con 2 jugadores, 24 '
                  'con 3, 22 con 4 y 20 con 5. Si nadie llega, gana quien '
                  'tenga más puntos cuando todos llenen su tablero.',
                  style: _cuerpo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: const TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: _texto,
    ),
  );
}

class _Paso extends StatelessWidget {
  final int numero;
  final String titulo;
  final String texto;
  final Widget? dibujo;

  const _Paso({
    required this.numero,
    required this.titulo,
    required this.texto,
    this.dibujo,
  });

  @override
  Widget build(BuildContext context) {
    final dibujo = this.dibujo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _texto,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$numero',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _Titulo(titulo)),
              ],
            ),
            const SizedBox(height: 8),
            Text(texto, style: _cuerpo.copyWith(color: _secundario)),
            if (dibujo != null) ...[
              const SizedBox(height: 12),
              Center(child: dibujo),
            ],
          ],
        ),
      ),
    );
  }
}

class _Casilla extends StatelessWidget {
  final Tipo tipo;
  final String? numero;
  final bool estrella;
  final bool marcada;

  const _Casilla(
    this.tipo, {
    this.numero,
    this.estrella = false,
    this.marcada = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorDe(tipo);
    final texto = colorTextoSobre(color);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Stack(
        children: [
          if (estrella)
            Positioned(
              left: 3,
              bottom: 3,
              child: Icon(Icons.star, size: 14, color: texto),
            ),
          if (numero != null)
            Center(
              child: Text(
                numero!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: texto,
                ),
              ),
            ),
          if (marcada)
            Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(color: texto, width: 3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _Ancla extends StatelessWidget {
  const _Ancla();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '3',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_forward_rounded, color: _secundario),
        ),
        const _Casilla(Tipo.azul, estrella: true),
      ],
    );
  }
}

class _Dados extends StatelessWidget {
  const _Dados();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DadoAnimado(valor: 3, seleccionado: true, tamano: 48),
      SizedBox(width: 12),
      DadoAnimado(valor: 5, tamano: 48),
    ],
  );
}

class _Ejemplo extends StatelessWidget {
  const _Ejemplo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Casilla(Tipo.verde),
                  _Casilla(Tipo.verde, marcada: true),
                  _Casilla(Tipo.rojo),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Casilla(Tipo.verde, marcada: true),
                  _Casilla(Tipo.azul, numero: '5', estrella: true),
                  _Casilla(Tipo.rojo, marcada: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Salieron 3 y 5. Elegiste el 3, así que va pegado al 5.',
          textAlign: TextAlign.center,
          style: _cuerpo.copyWith(fontSize: 14, color: _secundario),
        ),
      ],
    );
  }
}

class _Reglas extends StatelessWidget {
  const _Reglas();

  @override
  Widget build(BuildContext context) {
    const tipos = [
      Tipo.rojo,
      Tipo.amarillo,
      Tipo.azul,
      Tipo.morado,
      Tipo.verde,
      Tipo.blanco,
      Tipo.naranja1a3,
      Tipo.naranja4a6,
    ];
    const explicacion = {
      Tipo.rojo: 'Ningún número se repite en la zona.',
      Tipo.amarillo:
          'Ningún número se repite, aunque las casillas estén '
          'separadas.',
      Tipo.azul: 'Todas las casillas llevan el mismo número.',
      Tipo.morado: 'Solo se pueden usar dos números distintos.',
      Tipo.verde: 'Cualquier número sirve.',
      Tipo.blanco: 'Todas llevan el mismo número.',
      Tipo.naranja1a3: 'Solo números del 1 al 3.',
      Tipo.naranja4a6: 'Solo números del 4 al 6.',
    };
    return Column(
      children: [
        for (final tipo in tipos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorDe(tipo),
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reglaPorTipo[tipo]!.simbolo,
                    style: TextStyle(
                      fontSize: reglaPorTipo[tipo]!.simbolo.length > 1
                          ? 13
                          : 20,
                      fontWeight: FontWeight.bold,
                      color: colorTextoSobre(colorDe(tipo)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${nombreZona(tipo)[0].toUpperCase()}'
                    '${nombreZona(tipo).substring(1)}: ${explicacion[tipo]}',
                    style: _cuerpo.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
