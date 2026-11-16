import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dado_animado.dart';
import 'dados.dart';
import 'nivel.dart';
import 'panel_reglas.dart';
import 'tablero.dart';
import 'tablero_bloc.dart';
import 'tablero_interfaz.dart';
import 'sonidos.dart';

String textoDeJugada(Dados? dados, int? elegido, bool hayDonde) {
  if (dados == null) {
    return 'Tirando los dados…';
  }
  if (elegido == null) {
    return 'Toca uno de los dos dados: ese es el número que vas a escribir.';
  }
  if (!hayDonde) {
    return 'El $elegido no cabe en ningún lado. Toca el otro dado.';
  }
  final otro = dados.companeroDe(elegido);
  return 'Escribe el $elegido en una casilla marcada, pegada a un $otro.';
}

class VistaJuego extends StatelessWidget {
  final Tablero tablero;
  final Dados? dados;
  final int? elegido;
  final List<(int, int)> posibles;
  final bool puedeTirar;
  final bool resuelto;
  final bool sinJugadas;
  final VoidCallback? alSalir;
  final VoidCallback? alJugarOtraVez;
  final Nivel nivel;

  final void Function(int numero)? alElegir;
  final void Function(int fila, int columna)? alColocar;

  final bool conBotonTirar;

  final bool dadosActivos;

  final String? instruccion;

  final int? puntos;

  final Map<(int, int), List<MarcaZona>> marcas;

  final Set<int>? zonasApagadas;

  const VistaJuego({
    super.key,
    required this.tablero,
    this.dados,
    this.elegido,
    this.posibles = const [],
    this.puedeTirar = true,
    this.resuelto = false,
    this.sinJugadas = false,
    this.alSalir,
    this.alJugarOtraVez,
    this.nivel = nivel1,
    this.alElegir,
    this.alColocar,
    this.conBotonTirar = true,
    this.dadosActivos = true,
    this.instruccion,
    this.puntos,
    this.marcas = const {},
    this.zonasApagadas,
  });

  String get _instruccion {
    if (instruccion case final texto?) return texto;
    if (resuelto && sinJugadas) {
      return 'Ya no queda ninguna jugada posible. Terminaste con '
          '${puntos ?? tablero.puntos} puntos.';
    }
    if (resuelto) {
      return '¡Tablero resuelto! Terminaste con '
          '${puntos ?? tablero.puntos} puntos.';
    }
    if (dados == null) return 'Tirando los dados…';
    if (puedeTirar) return 'Con estos dados no hay jugada: se tiran de nuevo…';
    return textoDeJugada(dados, elegido, posibles.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final tirada = dados;
    final elegirSinSonido =
        alElegir ??
        (int n) => context.read<TableroBloc>().add(NumeroElegido(n));
    final colocarSinSonido =
        alColocar ??
        (int f, int c) => context.read<TableroBloc>().add(NumeroColocado(f, c));
    void elegir(int n) => elegirSinSonido(n);

    void colocar(int f, int c) {
      Sonidos.tocar(Sonido.colocar);
      colocarSinSonido(f, c);
    }

    final numeros = <(int, int), int>{};
    for (var fila = 0; fila < tablero.valores.length; fila++) {
      for (var columna = 0; columna < tablero.valores[fila].length; columna++) {
        final valor = tablero.valores[fila][columna];
        if (valor != null) {
          numeros[(fila, columna)] = valor;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final altoTablero = (restricciones.maxHeight - 250)
            .clamp(220.0, 600.0)
            .toDouble();

        final interfaz = TableroInterfaz(
          tablero: tablero,
          anclas: nivel.anclas,
          numeros: numeros,
          arrastrando: false,
          posibles: posibles,
          alSoltar: (_, _) {},
          alQuitar: (_) {},
          alTocar: (celda) => colocar(celda.$1, celda.$2),
          marcas: marcas,
          zonasApagadas:
              zonasApagadas ??
              {for (final zona in tablero.zonasCompletas()) zona.id},
        );
        final (izquierda, derecha) = reglasDe(nivel);

        final angosta = restricciones.maxWidth < 600;

        final controles = <Widget>[
          const SizedBox(height: 14),
          _Marcador(puntos: puntos ?? tablero.puntos),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DadoAnimado(
                key: const Key('dado_1'),
                sonarAlRodar: true,
                valor: tirada?.primero,
                tirada: tirada,
                seleccionado: tirada != null && elegido == tirada.primero,
                alTocar: tirada == null || !dadosActivos
                    ? null
                    : () => elegir(tirada.primero),
              ),
              const SizedBox(width: 18),
              DadoAnimado(
                key: const Key('dado_2'),
                valor: tirada?.segundo,
                tirada: tirada,
                seleccionado: tirada != null && elegido == tirada.segundo,
                alTocar: tirada == null || !dadosActivos
                    ? null
                    : () => elegir(tirada.segundo),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (conBotonTirar)
            FilledButton(
              onPressed: (resuelto || !puedeTirar)
                  ? null
                  : () => context.read<TableroBloc>().add(DadosTirados()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: const Text(
                'Tirar los dados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            _instruccion,
            key: const Key('instruccion'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (resuelto && (alSalir != null || alJugarOtraVez != null)) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (alSalir != null)
                  FilledButton.icon(
                    key: const Key('boton_salir_final'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: alSalir,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Salir a los tableros'),
                  ),
                if (alJugarOtraVez != null)
                  OutlinedButton.icon(
                    key: const Key('boton_otra_vez'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: alJugarOtraVez,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Jugar otra vez'),
                  ),
              ],
            ),
          ],
        ];

        if (!angosta && restricciones.maxHeight < 500) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: PanelReglas(reglas: izquierda, puntos: nivel.puntos),
                ),
                SizedBox(
                  width: 130,
                  child: PanelReglas(reglas: derecha, puntos: nivel.puntos),
                ),
                const SizedBox(width: 8),
                Expanded(child: Center(child: interfaz)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: controles,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (angosta) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: interfaz,
                ),
              ] else
                SizedBox(
                  height: altoTablero,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: PanelReglas(
                          reglas: izquierda,
                          puntos: nivel.puntos,
                        ),
                      ),
                      Expanded(child: Center(child: interfaz)),
                      SizedBox(
                        width: 140,
                        child: PanelReglas(
                          reglas: derecha,
                          puntos: nivel.puntos,
                        ),
                      ),
                    ],
                  ),
                ),
              ...controles,
              if (angosta) ...[
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PanelReglas(
                        reglas: izquierda,
                        puntos: nivel.puntos,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PanelReglas(reglas: derecha, puntos: nivel.puntos),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Marcador extends StatelessWidget {
  final int puntos;

  const _Marcador({required this.puntos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$puntos',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            puntos == 1 ? 'punto' : 'puntos',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
