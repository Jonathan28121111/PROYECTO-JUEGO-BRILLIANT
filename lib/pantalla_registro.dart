import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'estilo_acceso.dart';
import 'sesion_bloc.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();

  /// Solo se muestran los errores del bloc que vengan de un registro hecho
  /// desde esta pantalla, no los que quedaron del inicio de sesión.
  bool _intento = false;
  String? _errorLocal;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _crear() {
    if (_contrasena.text != _confirmar.text) {
      setState(() {
        _intento = false;
        _errorLocal = 'Las contraseñas no coinciden.';
      });
      return;
    }
    setState(() {
      _intento = true;
      _errorLocal = null;
    });
    context.read<SesionBloc>().add(
      Registrarse(_usuario.text.trim(), _contrasena.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<SesionBloc>().state;
    final cargando = estado is SinSesion && estado.cargando;
    final error =
        _errorLocal ?? (_intento && estado is SinSesion ? estado.error : null);

    return BlocListener<SesionBloc, SesionState>(
      // Con la cuenta creada, la app de abajo ya cambió al juego.
      listenWhen: (_, ahora) => ahora is ConCuenta,
      listener: (context, _) => Navigator.of(context).pop(),
      child: MarcoAcceso(
        encabezado: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextButton.icon(
              key: const Key('volver_inicio'),
              onPressed: cargando ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Gris.secundario,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Volver'),
            ),
          ),
        ),
        titulo: 'Crea tu cuenta',
        subtitulo: 'Elige un usuario y una contraseña para guardar tu progreso.',
        children: [
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('registro_usuario'),
                  controller: _usuario,
                  enabled: !cargando,
                  autocorrect: false,
                  autofocus: true,
                  autofillHints: const [AutofillHints.newUsername],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    helperText: 'De 3 a 20 caracteres: letras, números, . - _',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('registro_contrasena'),
                  controller: _contrasena,
                  enabled: !cargando,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    helperText: 'Al menos 8 caracteres',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('registro_confirmar'),
                  controller: _confirmar,
                  enabled: !cargando,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _crear(),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            MensajeError(error),
          ],
          const SizedBox(height: 24),
          if (cargando)
            const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            FilledButton(
              key: const Key('boton_crear'),
              onPressed: _crear,
              child: const Text('Crear cuenta'),
            ),
          const SizedBox(height: 16),
          EnlacePie(
            pregunta: '¿Ya tienes cuenta?',
            accion: 'Iniciar sesión',
            alTocar: cargando ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
