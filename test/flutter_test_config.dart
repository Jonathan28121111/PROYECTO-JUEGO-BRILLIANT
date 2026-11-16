import 'dart:async';

import 'package:pruebas_numeros/sonidos.dart';

final List<String> sonidosTocados = [];

Future<void> testExecutable(FutureOr<void> Function() pruebas) async {
  Sonidos.reproducir = (archivo) async => sonidosTocados.add(archivo);
  Sonidos.guardar = (_) async {};
  await pruebas();
}
