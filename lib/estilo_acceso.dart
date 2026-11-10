import 'package:flutter/material.dart';

abstract final class Gris {
  static const Color tinta = Color(0xFF111827);
  static const Color boton = Color(0xFF1F2937);
  static const Color texto = Color(0xFF374151);
  static const Color secundario = Color(0xFF6B7280);
  static const Color borde = Color(0xFFD1D5DB);
  static const Color bordeSuave = Color(0xFFE5E7EB);
  static const Color relleno = Color(0xFFF9FAFB);
  static const Color error = Color(0xFFB91C1C);
  static const Color fondoError = Color(0xFFFEF2F2);
  static const Color bordeError = Color(0xFFFECACA);
}

class TemaAcceso extends StatelessWidget {
  final Widget child;

  const TemaAcceso({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final redondeado = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const alto = Size.fromHeight(48);
    const textoBoton = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Gris.boton,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          primary: Gris.boton,
          surface: Colors.white,
          onSurface: Gris.tinta,
          error: Gris.error,
        ),
        scaffoldBackgroundColor: Colors.white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Gris.tinta,
          selectionColor: Gris.bordeSuave,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Gris.secundario),
          floatingLabelStyle: const TextStyle(color: Gris.tinta),
          helperStyle: const TextStyle(color: Gris.secundario, fontSize: 12),
          prefixIconColor: Gris.secundario,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: borde(Gris.borde),
          enabledBorder: borde(Gris.borde),
          disabledBorder: borde(Gris.bordeSuave),
          focusedBorder: borde(Gris.tinta, 1.5),
          errorBorder: borde(Gris.error),
          focusedErrorBorder: borde(Gris.error, 1.5),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Gris.boton,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Gris.bordeSuave,
            disabledForegroundColor: Gris.secundario,
            minimumSize: alto,
            shape: redondeado,
            textStyle: textoBoton,
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Gris.texto,
            minimumSize: alto,
            shape: redondeado,
            side: const BorderSide(color: Gris.borde),
            textStyle: textoBoton,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Gris.tinta,
            shape: redondeado,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Gris.boton,
        ),
      ),
      child: child,
    );
  }
}

class MarcoAcceso extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<Widget> children;
  final Widget? encabezado;

  final Widget? icono;

  const MarcoAcceso({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.children,
    this.encabezado,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return TemaAcceso(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Marca(),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Gris.bordeSuave),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F111827),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ?encabezado,
                          if (icono case final icono?) ...[
                            Center(child: icono),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            titulo,
                            textAlign: icono == null
                                ? TextAlign.start
                                : TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Gris.tinta,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitulo,
                            textAlign: icono == null
                                ? TextAlign.start
                                : TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Gris.secundario,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ...children,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Gris.boton,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Juego Brilliant',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Gris.tinta,
          ),
        ),
      ],
    );
  }
}

class MensajeError extends StatelessWidget {
  final String texto;

  const MensajeError(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Gris.fondoError,
        border: Border.all(color: Gris.bordeError),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Gris.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: Gris.error),
            ),
          ),
        ],
      ),
    );
  }
}

class EnlacePie extends StatelessWidget {
  final String pregunta;
  final String accion;
  final VoidCallback? alTocar;

  const EnlacePie({
    super.key,
    required this.pregunta,
    required this.accion,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          pregunta,
          style: const TextStyle(fontSize: 14, color: Gris.secundario),
        ),
        TextButton(onPressed: alTocar, child: Text(accion)),
      ],
    );
  }
}
