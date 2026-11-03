import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'avatar_usuario.dart';
import 'estilo_acceso.dart';
import 'pantalla_registro.dart';
import 'sesion_bloc.dart';

class PantallaCuenta extends StatefulWidget {
  const PantallaCuenta({super.key});

  @override
  State<PantallaCuenta> createState() => _PantallaCuentaState();
}

class _PantallaCuentaState extends State<PantallaCuenta> {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();

  /// El error del bloc es compartido con el registro: solo se muestra aquí
  /// si lo provocó un intento de inicio de sesión desde esta pantalla.
  bool _intento = false;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _entrar() {
    setState(() => _intento = true);
    context.read<SesionBloc>().add(
      IniciarSesion(_usuario.text.trim(), _contrasena.text),
    );
  }

  void _abrirRegistro() {
    setState(() => _intento = false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaRegistro()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<SesionBloc>().state;
    final cargando = estado is SinSesion && estado.cargando;
    final error = _intento && estado is SinSesion ? estado.error : null;

    return MarcoAcceso(
      icono: const AvatarUsuario(tamano: 88),
      titulo: 'Inicio de sesión',
      subtitulo: 'Ingresa con tu usuario y contraseña para continuar.',
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('campo_usuario'),
                controller: _usuario,
                enabled: !cargando,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('campo_contrasena'),
                controller: _contrasena,
                enabled: !cargando,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _entrar(),
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
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
          FilledButton(onPressed: _entrar, child: const Text('Entrar')),
        const SizedBox(height: 20),
        const _Separador(),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: cargando
              ? null
              : () => context.read<SesionBloc>().add(JugarSinCuenta()),
          child: const Text('Jugar sin cuenta'),
        ),
        const SizedBox(height: 16),
        EnlacePie(
          pregunta: '¿No tienes cuenta?',
          accion: 'Crear cuenta',
          alTocar: cargando ? null : _abrirRegistro,
        ),
      ],
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Gris.bordeSuave)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: TextStyle(fontSize: 13, color: Gris.secundario),
          ),
        ),
        Expanded(child: Divider(color: Gris.bordeSuave)),
      ],
    );
  }
}

class MenuCuenta extends StatelessWidget {
  const MenuCuenta({super.key});

  static const Color _rojo = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<SesionBloc>().state;
    final conCuenta = estado is ConCuenta;
    final nombre = switch (estado) {
      ConCuenta(:final cuenta) => cuenta.usuario,
      _ => 'Invitado',
    };

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PopupMenuButton<String>(
        key: const Key('menu_cuenta'),
        tooltip: 'Cuenta',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x33000000),
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        onSelected: (opcion) async {
          final bloc = context.read<SesionBloc>();
          switch (opcion) {
            case 'salir':
              bloc.add(CerrarSesion());
            case 'borrar':
              final contrasena = await pedirContrasena(context);
              if (contrasena != null) {
                bloc.add(BorrarCuenta(contrasena));
              }
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            enabled: false,
            height: 72,
            child: Row(
              children: [
                const AvatarUsuario(tamano: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conCuenta
                            ? 'Sesión iniciada'
                            : 'Tu progreso no se guarda',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          _opcion(
            valor: 'salir',
            icono: conCuenta ? Icons.logout_rounded : Icons.login_rounded,
            texto: conCuenta ? 'Cerrar sesión' : 'Iniciar sesión',
          ),
          if (conCuenta)
            _opcion(
              valor: 'borrar',
              icono: Icons.delete_outline_rounded,
              texto: 'Borrar cuenta',
              color: _rojo,
            ),
        ],
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: AvatarUsuario(tamano: 34),
        ),
      ),
    );
  }

  PopupMenuItem<String> _opcion({
    required String valor,
    required IconData icono,
    required String texto,
    Color color = const Color(0xFF374151),
  }) {
    return PopupMenuItem(
      value: valor,
      height: 48,
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> pedirContrasena(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const DialogoContrasena(),
);

class DialogoContrasena extends StatefulWidget {
  const DialogoContrasena({super.key});

  @override
  State<DialogoContrasena> createState() => _DialogoContrasenaState();
}

class _DialogoContrasenaState extends State<DialogoContrasena> {
  final _campo = TextEditingController();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: MenuCuenta._rojo,
        size: 32,
      ),
      title: const Text('Borrar cuenta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Esto no se puede deshacer. Escribe tu contraseña:'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_confirmar'),
            controller: _campo,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: MenuCuenta._rojo),
          onPressed: () => Navigator.pop(context, _campo.text),
          child: const Text('Borrar'),
        ),
      ],
    );
  }
}
