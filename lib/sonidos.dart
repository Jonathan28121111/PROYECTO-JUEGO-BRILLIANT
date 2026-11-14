import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'almacen_servidor_io.dart'
    if (dart.library.js_interop) 'almacen_servidor_web.dart'
    as almacen;

enum Sonido {
  tirarDados(['tirar_dados']),
  colocar(['colocar_1', 'colocar_2', 'colocar_3']),
  zonaCompletada(['zona_completada']),
  zonaRival(['zona_rival']),
  error(['error']),
  listo(['listo']),
  click(['click']),
  ganar(['ganar']),
  perder(['perder']),
  tic(['tic']);

  final List<String> archivos;

  const Sonido(this.archivos);
}

abstract final class Sonidos {
  static final ValueNotifier<bool> activos = ValueNotifier(true);

  static final Random _azar = Random();
  static bool _contextoListo = false;
  static final Map<String, Future<AudioPool>> _pools = {};

  static Future<void> Function(String archivo) reproducir = _reproducir;
  static Future<void> Function(bool activos) guardar = (valor) =>
      almacen.guardarPreferencia('sonido', valor ? 'si' : 'no');

  static Future<void> cargar() async {
    activos.value = await almacen.leerPreferencia('sonido') != 'no';
    try {
      await _prepararContexto();
      for (final sonido in Sonido.values) {
        for (final archivo in sonido.archivos) {
          _pool('sonidos/$archivo.m4a').ignore();
        }
      }
    } catch (error) {
      debugPrint('No se pudieron preparar los sonidos: $error');
    }
  }

  static Future<void> cambiar(bool valor) async {
    activos.value = valor;
    await guardar(valor);
  }

  static void tocar(Sonido sonido, {Duration retraso = Duration.zero}) {
    if (retraso > Duration.zero) {
      Timer(retraso, () => tocar(sonido));
      return;
    }
    if (!activos.value) return;
    final archivo = sonido.archivos[_azar.nextInt(sonido.archivos.length)];
    reproducir('sonidos/$archivo.m4a').catchError((Object error) {
      debugPrint('Sonido $archivo no se pudo tocar: $error');
    });
  }

  static Future<void> _prepararContexto() async {
    if (_contextoListo) return;
    _contextoListo = true;
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(respectSilence: false, stayAwake: false).build(),
    );
  }

  static Future<AudioPool> _pool(String archivo) => _pools.putIfAbsent(
    archivo,
    () => AudioPool.createFromAsset(path: archivo, maxPlayers: 4),
  );

  static Future<void> _reproducir(String archivo) async {
    await _prepararContexto();
    final pool = await _pool(archivo);
    await pool.start();
  }
}
