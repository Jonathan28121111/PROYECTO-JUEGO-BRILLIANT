import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'avatar_usuario.dart';
import 'estilo_acceso.dart';
import 'pantalla_registro.dart';
import 'servidor.dart';
import 'sonidos.dart';
import 'sesion_bloc.dart';

class PantallaCuenta extends StatefulWidget {
  const PantallaCuenta({super.key});

  @override
  State<PantallaCuenta> createState() => _PantallaCuentaState();
}

class _PantallaCuentaState extends State<PantallaCuenta> {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();

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
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PantallaRegistro()));
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
        if (error != null) ...[const SizedBox(height: 16), MensajeError(error)],
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
        const SizedBox(height: 8),
        const EnlaceServidor(),
      ],
    );
  }
}

class EnlaceServidor extends StatelessWidget {
  const EnlaceServidor({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: servidorActual,
      builder: (context, direccion, _) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Servidor: ${mostrarServidor(direccion)}',
            key: const Key('texto_servidor'),
            style: const TextStyle(fontSize: 13, color: Gris.secundario),
          ),
          TextButton(
            key: const Key('cambiar_servidor'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const DialogoServidor(),
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

class DialogoServidor extends StatefulWidget {
  final Future<bool> Function(String direccion) probar;

  const DialogoServidor({super.key, this.probar = servidorResponde});

  @override
  State<DialogoServidor> createState() => _DialogoServidorState();
}

class _DialogoServidorState extends State<DialogoServidor> {
  late final _campo = TextEditingController(
    text: Uri.tryParse(servidorActual.value)?.host ?? '',
  );
  bool _probando = false;
  String? _error;
  String? _sinRespuesta;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _guardar({bool aunSinRespuesta = false}) async {
    final direccion = normalizarServidor(_campo.text);
    if (direccion == null) {
      setState(() => _error = 'Escribe una dirección como 192.168.0.170.');
      return;
    }
    if (!aunSinRespuesta) {
      setState(() {
        _probando = true;
        _error = null;
      });
      final responde = await widget.probar(direccion);
      if (!mounted) return;
      if (!responde) {
        setState(() {
          _probando = false;
          _sinRespuesta = direccion;
          _error =
              'No encontré el servidor en ${mostrarServidor(direccion)}. '
              'Revisa que la Mac esté prendida, con el servidor corriendo y '
              'en la misma red.';
        });
        return;
      }
    }
    await guardarServidor(direccion);
    if (!mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensajero.showSnackBar(
      SnackBar(content: Text('Servidor: ${mostrarServidor(direccion)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mismo = _sinRespuesta == normalizarServidor(_campo.text);
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Dirección del servidor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Es la IP de la Mac donde corre el servidor. jugar.sh la muestra '
            'al arrancar.',
            style: TextStyle(fontSize: 14, color: Gris.secundario),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('campo_servidor'),
            controller: _campo,
            enabled: !_probando,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _guardar(),
            decoration: const InputDecoration(
              labelText: 'Dirección',
              hintText: '192.168.0.170',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            MensajeError(error),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _probando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_error != null && mismo)
          TextButton(
            key: const Key('guardar_igual'),
            onPressed: () => _guardar(aunSinRespuesta: true),
            child: const Text('Guardar igual'),
          ),
        FilledButton(
          key: const Key('guardar_servidor'),
          onPressed: _probando ? null : _guardar,
          child: Text(_probando ? 'Probando…' : 'Probar y guardar'),
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
        onSelected: (opcion) {
          if (opcion == 'salir') {
            context.read<SesionBloc>().add(CerrarSesion());
          } else if (opcion == 'sonido') {
            Sonidos.cambiar(!Sonidos.activos.value);
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
            valor: 'sonido',
            icono: Sonidos.activos.value
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined,
            texto: Sonidos.activos.value
                ? 'Silenciar sonidos'
                : 'Activar sonidos',
          ),
          _opcion(
            valor: 'salir',
            icono: conCuenta ? Icons.logout_rounded : Icons.login_rounded,
            texto: conCuenta ? 'Cerrar sesión' : 'Iniciar sesión',
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
