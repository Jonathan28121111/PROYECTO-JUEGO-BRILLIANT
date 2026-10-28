import 'package:flutter_test/flutter_test.dart';
import 'package:pruebas_numeros/nivel.dart';
import 'package:pruebas_numeros/pantalla_niveles.dart';
import 'package:pruebas_numeros/tablero_bloc.dart';

import 'ayudas_interfaz.dart';

void main() {
  Future<void> abrir(WidgetTester tester, {TableroBloc? bloc}) async {
    pantallaGrande(tester);
    await tester.pumpWidget(montar(const PantallaNiveles(), bloc: bloc));
    await tester.pumpAndSettle();
  }

  group('como se dibuja', () {
    testWidgets('muestra una tarjeta por nivel oficial', (tester) async {
      await abrir(tester);

      expect(find.byType(TarjetaNivel), findsNWidgets(4));
      for (final nivel in nivelesOficiales) {
        expect(find.text(nivel.nombre), findsOneWidget);
      }
    });

    testWidgets('los cuatro traen su miniatura', (tester) async {
      await abrir(tester);

      expect(find.byType(MiniaturaNivel), findsNWidgets(4));
      expect(find.text('Falta transcribir\nla carta'), findsNothing);
      expect(find.text('No disponible'), findsNothing);
    });

    testWidgets('cada tarjeta dice cuantas zonas tiene su tablero',
        (tester) async {
      await abrir(tester);

      expect(find.text('9 zonas'), findsOneWidget); // nivel 1
      expect(find.text('10 zonas'), findsOneWidget); // nivel 2
      expect(find.text('8 zonas'), findsNWidgets(2)); // niveles 3 y 4
    });
  });

  group('elegir un nivel', () {
    testWidgets('tocar el nivel 1 se lo manda al bloc', (tester) async {
      final bloc = TableroBloc();
      addTearDown(bloc.close);

      await abrir(tester, bloc: bloc);
      expect((bloc.state as TableroSinIniciar).nivel, null);

      await tester.tap(find.text('Nivel 1'));
      await tester.pumpAndSettle();

      expect((bloc.state as TableroSinIniciar).nivel?.numero, 1);
    });

    testWidgets('cualquiera de los cuatro se puede elegir', (tester) async {
      for (final nivel in nivelesOficiales) {
        final bloc = TableroBloc();
        addTearDown(bloc.close);

        await abrir(tester, bloc: bloc);
        await tester.tap(find.text(nivel.nombre));
        await tester.pumpAndSettle();

        expect((bloc.state as TableroSinIniciar).nivel?.numero, nivel.numero,
            reason: 'no se pudo elegir ${nivel.nombre}');
      }
    });

    testWidgets('sigue sin poder avanzar hasta dar los valores iniciales',
        (tester) async {
      final bloc = TableroBloc();
      addTearDown(bloc.close);

      await abrir(tester, bloc: bloc);
      await tester.tap(find.text('Nivel 2'));
      await tester.pumpAndSettle();

      expect(bloc.state.puedeAvanzar, false);
    });
  });
}