import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dado_animado.dart';
import 'dados.dart';
import 'nivel.dart';
import 'panel_reglas.dart';
import 'tablero.dart';
import 'tablero_bloc.dart';
import 'tablero_interfaz.dart';

class VistaJuego extends StatelessWidget {
  final Tablero tablero;
  final Dados? dados;
  final int? elegido;
  final List<(int, int)> posibles;
  final bool puedeTirar;
  final bool resuelto;
  final Nivel nivel;

  /// Por defecto las acciones van al [TableroBloc]. En línea las recibe la
  /// partida, que es la que habla con el servidor.
  final void Function(int numero)? alElegir;
  final void Function(int fila, int columna)? alColocar;

  /// En línea los dados los tira el servidor: no hay botón.
  final bool conBotonTirar;

  /// Si se pueden tocar los dados (en línea, no después de haber jugado).
  final bool dadosActivos;

  /// Reemplaza el texto de ayuda de abajo.
  final String? instruccion;

  const VistaJuego({
    super.key,
    required this.tablero,
    this.dados,
    this.elegido,
    this.posibles = const [],
    this.puedeTirar = true,
    this.resuelto = false,
    this.nivel = nivel1,
    this.alElegir,
    this.alColocar,
    this.conBotonTirar = true,
    this.dadosActivos = true,
    this.instruccion,
  });

  String get _instruccion {
    if (instruccion case final texto?) return texto;
    if (resuelto) return '¡Tablero resuelto!';
    if (dados == null) return 'Tira los dados para jugar';
    if (puedeTirar) return 'No hay ninguna jugada: vuelve a tirar';
    if (elegido == null) return 'Elige cuál de los dos números vas a escribir';
    if (posibles.isEmpty) {
      return 'Con ese número no hay jugada: prueba con el otro';
    }
    return 'Toca una casilla resaltada';
  }

  @override
  Widget build(BuildContext context) {
    final tirada = dados;
    final elegir = alElegir ??
        (int n) => context.read<TableroBloc>().add(NumeroElegido(n));
    final colocar = alColocar ??
        (int f, int c) => context.read<TableroBloc>().add(NumeroColocado(f, c));

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
        final altoTablero =
            (restricciones.maxHeight - 250).clamp(220.0, 600.0).toDouble();

        final interfaz = TableroInterfaz(
          tablero: tablero,
          anclas: nivel.anclas,
          numeros: numeros,
          arrastrando: false,
          posibles: posibles,
          alSoltar: (_, _) {},
          alQuitar: (_) {},
          alTocar: (celda) => colocar(celda.$1, celda.$2),
        );
        final (izquierda, derecha) = reglasDe(nivel);

        // En pantallas angostas los paneles a los lados dejaban el tablero
        // diminuto: el tablero va a todo lo ancho y las reglas debajo.
        final angosta = restricciones.maxWidth < 600;

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
                    Expanded(
                      child: Center(
                        child: interfaz,
                      ),
                    ),
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
              const SizedBox(height: 14),
              _Marcador(puntos: tablero.puntos),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DadoAnimado(
                    key: const Key('dado_1'),
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
              if (conBotonTirar) FilledButton(
                onPressed: (resuelto || !puedeTirar)
                    ? null
                    : () => context.read<TableroBloc>().add(DadosTirados()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                      child: PanelReglas(
                        reglas: derecha,
                        puntos: nivel.puntos,
                      ),
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
