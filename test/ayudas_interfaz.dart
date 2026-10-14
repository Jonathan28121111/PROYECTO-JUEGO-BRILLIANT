import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/tablero.dart';
import 'package:pruebas_numeros/tablero_bloc.dart';
import 'package:pruebas_numeros/tablero_interfaz.dart';
import 'package:pruebas_numeros/tipo_zona.dart';


void pantallaGrande(
  WidgetTester tester, {
  Size tamano = const Size(1400, 1100),
}) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget montar(Widget hijo, {TableroBloc? bloc}) {
  final cuerpo = Scaffold(body: hijo);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: bloc == null
        ? BlocProvider<TableroBloc>(
            create: (_) => TableroBloc(),
            child: cuerpo,
          )
        : BlocProvider<TableroBloc>.value(value: bloc, child: cuerpo),
  );
}

Offset centroDeCelda(
  WidgetTester tester,
  int fila,
  int columna, {
  int filas = 7,
  int columnas = 7,
}) {
  final cuadro = tester.getRect(
    find.descendant(
      of: find.byType(TableroInterfaz),
      matching: find.byType(AspectRatio),
    ),
  );
  final ancho = cuadro.width / columnas;
  final alto = cuadro.height / filas;
  return Offset(
    cuadro.left + ancho * (columna + 0.5),
    cuadro.top + alto * (fila + 0.5),
  );
}

Future<void> arrastrarFicha(
  WidgetTester tester,
  int numero,
  int fila,
  int columna, {
  int filas = 7,
  int columnas = 7,
}) async {
  final ficha = find.widgetWithText(Draggable<int>, '$numero');
  final gesto = await tester.startGesture(tester.getCenter(ficha));
  await tester.pump(const Duration(milliseconds: 50));
  await gesto.moveTo(
    centroDeCelda(tester, fila, columna, filas: filas, columnas: columnas),
  );
  await tester.pump();
  await gesto.up();
  await tester.pumpAndSettle();
}

Finder enElTablero(String texto) => find.descendant(
      of: find.byType(TableroInterfaz),
      matching: find.text(texto),
    );

Tablero tableroChico(Tipo tipo) => Tablero(
      [
        [1, 1, 1],
      ],
      {1: tipo},
      [
        [2, null, null],
      ],
    );

class AzarFijo implements Random {
  final List<int> valores;
  int _indice = 0;

  AzarFijo(this.valores);

  @override
  int nextInt(int max) => valores[_indice++ % valores.length] - 1;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
