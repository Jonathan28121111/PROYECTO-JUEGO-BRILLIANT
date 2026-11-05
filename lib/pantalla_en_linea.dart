import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'avatar_usuario.dart';
import 'cliente_cuentas.dart';
import 'conexion_juego.dart';
import 'dados.dart';
import 'nivel.dart';
import 'pantalla_anclas.dart';
import 'partida_bloc.dart';
import 'sala_en_linea.dart';
import 'sesion_bloc.dart';
import 'vista_juego.dart';

const Color _rojo = Color(0xFFB91C1C);
const Color _gris = Color(0xFF6B7280);
const Color _borde = Color(0xFFE5E7EB);

/// Cómo se abre la conexión con el servidor de partidas. Las pruebas la
/// cambian por una falsa.
class FabricaConexion {
  final AbrirConexion abrir;

  const FabricaConexion(this.abrir);
}

/// El botón de la barra para entrar al modo en línea.
class BotonEnLinea extends StatelessWidget {
  const BotonEnLinea({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.icon(
        key: const Key('boton_en_linea'),
        icon: const Icon(Icons.groups_outlined, size: 20),
        label: const Text('Jugar en línea'),
        onPressed: () => abrirModoEnLinea(context),
      ),
    );
  }
}

/// La invitación a jugar en línea que aparece arriba de los niveles.
class TarjetaEnLinea extends StatelessWidget {
  const TarjetaEnLinea({super.key});

  @override
  Widget build(BuildContext context) {
    final conCuenta = context.watch<SesionBloc>().state is ConCuenta;
    final colores = Theme.of(context).colorScheme;

    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Juega en línea contra otra persona',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          conCuenta
              ? 'Crea una sala y comparte el código, o únete con el código '
                    'de tu amigo.'
              : 'Inicia sesión con tu cuenta para crear una sala o unirte '
                    'a la de un amigo.',
          style: const TextStyle(fontSize: 14, color: _gris, height: 1.35),
        ),
      ],
    );
    final boton = FilledButton.icon(
      key: const Key('tarjeta_en_linea'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
      label: Text(conCuenta ? 'Jugar en línea' : 'Iniciar sesión'),
      onPressed: () => abrirModoEnLinea(context),
    );
    final icono = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colores.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.groups_rounded, color: colores.onPrimary, size: 28),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colores.primaryContainer.withValues(alpha: 0.35),
          border: Border.all(color: colores.primary.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, espacio) => espacio.maxWidth < 560
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        icono,
                        const SizedBox(width: 14),
                        Expanded(child: textos),
                      ],
                    ),
                    const SizedBox(height: 16),
                    boton,
                  ],
                )
              : Row(
                  children: [
                    icono,
                    const SizedBox(width: 16),
                    Expanded(child: textos),
                    const SizedBox(width: 16),
                    boton,
                  ],
                ),
        ),
      ),
    );
  }
}

Future<void> abrirModoEnLinea(BuildContext context) async {
  final sesion = context.read<SesionBloc>();
  final estado = sesion.state;
  if (estado is! ConCuenta) {
    final entrar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.lock_outline_rounded),
        title: const Text('Necesitas una cuenta'),
        content: const Text(
          'Para jugar en línea inicia sesión o crea una cuenta. Así el '
          'servidor te reconoce si se corta la conexión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
    if (entrar == true) sesion.add(CerrarSesion());
    return;
  }

  final fabrica = context.read<FabricaConexion?>();
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: sesion,
        child: PantallaEnLinea(cuenta: estado.cuenta, abrir: fabrica?.abrir),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Pantalla raíz

class PantallaEnLinea extends StatelessWidget {
  final Cuenta cuenta;
  final AbrirConexion? abrir;
  final List<Duration>? esperas;

  const PantallaEnLinea({
    super.key,
    required this.cuenta,
    this.abrir,
    this.esperas,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartidaBloc(
        usuario: cuenta.usuario,
        token: cuenta.token,
        abrir: abrir,
        esperas:
            esperas ??
            const [
              Duration(seconds: 1),
              Duration(seconds: 2),
              Duration(seconds: 4),
              Duration(seconds: 8),
            ],
      )..add(Conectar()),
      child: const _Contenido(),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido();

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<PartidaBloc>().state;
    final sala = estado.sala;
    final enCurso =
        sala != null &&
        (sala.fase == FaseSala.anclas || sala.fase == FaseSala.juego) &&
        estado.conexion != EstadoConexion.expulsado;

    return MultiBlocListener(
      listeners: [
        BlocListener<PartidaBloc, PartidaState>(
          listenWhen: (antes, ahora) =>
              ahora.numeroAviso != antes.numeroAviso && ahora.aviso != null,
          listener: (context, estado) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(estado.aviso!),
                  backgroundColor: estado.avisoEsError
                      ? _rojo
                      : const Color(0xFF1F2937),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },
        ),
        BlocListener<SesionBloc, SesionState>(
          listenWhen: (_, ahora) => ahora is! ConCuenta,
          listener: (context, _) => Navigator.of(context).maybePop(),
        ),
      ],
      child: PopScope(
        canPop: !enCurso,
        onPopInvokedWithResult: (salio, _) async {
          if (salio) return;
          final navegador = Navigator.of(context);
          final bloc = context.read<PartidaBloc>();
          if (await confirmarRendicion(context, saliendo: true)) {
            bloc.add(Rendirse());
            navegador.pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Jugar en línea'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  key: const Key('boton_jugar_local'),
                  icon: const Icon(Icons.person_outline_rounded, size: 20),
                  label: const Text('Jugar local'),
                  // maybePop respeta la confirmación si hay partida en curso.
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const BannerConexion(),
              Expanded(child: _cuerpo(context, estado)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, PartidaState estado) {
    if (estado.conexion == EstadoConexion.expulsado) {
      return _Expulsado(motivo: estado.motivoExpulsion ?? '');
    }
    final sala = estado.sala;
    if (sala == null) {
      if (estado.conexion == EstadoConexion.conectando &&
          estado.intentos == 0) {
        return const _Cargando(texto: 'Conectando con el servidor…');
      }
      return const Lobby();
    }
    return switch (sala.fase) {
      FaseSala.espera => SalaDeEspera(sala: sala),
      FaseSala.anclas => _FaseAnclas(sala: sala),
      FaseSala.juego => PartidaEnCurso(sala: sala),
      FaseSala.terminada => ResultadoPartida(sala: sala),
    };
  }
}

Future<bool> confirmarRendicion(
  BuildContext context, {
  bool saliendo = false,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      icon: const Icon(Icons.flag_outlined, color: _rojo, size: 32),
      title: Text(saliendo ? '¿Salir de la partida?' : '¿Rendirte?'),
      content: Text(
        saliendo
            ? 'La partida sigue en curso. Si sales, te rindes y tu rival gana.'
            : 'Tu rival gana la partida. Esto no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contexto, false),
          child: const Text('Seguir jugando'),
        ),
        FilledButton(
          key: const Key('confirmar_rendicion'),
          style: FilledButton.styleFrom(backgroundColor: _rojo),
          onPressed: () => Navigator.pop(contexto, true),
          child: Text(saliendo ? 'Rendirme y salir' : 'Rendirme'),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}

// ---------------------------------------------------------------------------
// Conexión

class BannerConexion extends StatelessWidget {
  const BannerConexion({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<PartidaBloc>().state;
    if (estado.conexion != EstadoConexion.reconectando) {
      return const SizedBox.shrink();
    }

    final espera = estado.segundosParaReintentar;
    final enPartida =
        estado.sala != null &&
        estado.sala!.fase != FaseSala.espera &&
        estado.sala!.fase != FaseSala.terminada;

    return Material(
      key: const Key('banner_conexion'),
      color: const Color(0xFFFFF7ED),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFFED7AA))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFC2410C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin conexión con el servidor',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                  Text(
                    [
                      if (espera != null && espera > 0)
                        _CuentaTexto.reintento(espera)
                      else
                        'Reconectando…',
                      if (enPartida) 'Tienes 60 s para volver a la partida.',
                    ].join(' '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const Key('reintentar_ahora'),
              onPressed: () =>
                  context.read<PartidaBloc>().add(ReintentarAhora()),
              child: const Text('Reintentar ahora'),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _CuentaTexto {
  static String reintento(int segundos) =>
      'Reintentando en $segundos ${segundos == 1 ? 'segundo' : 'segundos'}.';
}

class _Expulsado extends StatelessWidget {
  final String motivo;

  const _Expulsado({required this.motivo});

  @override
  Widget build(BuildContext context) {
    final sesionVencida = motivo.contains('sesión');
    return _Centrado(
      child: _Tarjeta(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sesionVencida
                  ? Icons.lock_clock_outlined
                  : Icons.devices_outlined,
              size: 40,
              color: _gris,
            ),
            const SizedBox(height: 12),
            Text(
              motivo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (sesionVencida)
              FilledButton(
                onPressed: () => context.read<SesionBloc>().add(CerrarSesion()),
                child: const Text('Iniciar sesión'),
              )
            else
              FilledButton(
                key: const Key('jugar_aqui'),
                onPressed: () =>
                    context.read<PartidaBloc>().add(ReintentarAhora()),
                child: const Text('Jugar en esta ventana'),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lobby

class Lobby extends StatefulWidget {
  const Lobby({super.key});

  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  final _codigo = TextEditingController();
  late int _nivel = nivelesOficiales.firstWhere((n) => n.disponible).numero;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _unirse() => context.read<PartidaBloc>().add(UnirseSala(_codigo.text));

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<PartidaBloc>();
    final estado = bloc.state;
    final listo = estado.conectado && !estado.cargando;

    return _Centrado(
      ancho: 760,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hola, ${bloc.usuario}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Crea una sala e invita a alguien con el código, o únete a la '
            'sala de otra persona.',
            style: TextStyle(fontSize: 15, color: _gris),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _TarjetaAccion(
                icono: Icons.add_circle_outline,
                titulo: 'Crear sala',
                descripcion:
                    'Elige el tablero. Los dos juegan el mismo nivel '
                    'con los mismos dados.',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final nivel in nivelesOficiales)
                        ChoiceChip(
                          key: Key('nivel_${nivel.numero}'),
                          label: Text(nivel.nombre),
                          selected: _nivel == nivel.numero,
                          onSelected: nivel.disponible
                              ? (_) => setState(() => _nivel = nivel.numero)
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('boton_crear_sala'),
                    onPressed: listo
                        ? () =>
                              context.read<PartidaBloc>().add(CrearSala(_nivel))
                        : null,
                    child: const Text('Crear sala'),
                  ),
                ],
              ),
              _TarjetaAccion(
                icono: Icons.login_rounded,
                titulo: 'Unirse con código',
                descripcion:
                    'Escribe el código de 6 caracteres que te '
                    'compartieron.',
                children: [
                  TextField(
                    key: const Key('campo_codigo'),
                    controller: _codigo,
                    enabled: estado.conectado,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                      _Mayusculas(),
                    ],
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    onSubmitted: (_) => _unirse(),
                    decoration: const InputDecoration(
                      hintText: 'ABC123',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    key: const Key('boton_unirse'),
                    onPressed: listo ? _unirse : null,
                    child: const Text('Unirse'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antes,
    TextEditingValue ahora,
  ) => ahora.copyWith(text: ahora.text.toUpperCase());
}

class _TarjetaAccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final List<Widget> children;

  const _TarjetaAccion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360, minWidth: 280),
      child: _Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icono, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(descripcion, style: const TextStyle(color: _gris)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sala de espera

class SalaDeEspera extends StatelessWidget {
  final SalaEnLinea sala;

  const SalaDeEspera({super.key, required this.sala});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<PartidaBloc>();
    final soyAnfitrion = sala.esAnfitrion(bloc.usuario);
    final completa = sala.jugadores.length >= 2;

    return _Centrado(
      ancho: 480,
      child: _Tarjeta(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sala de espera',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(sala.datosNivel.nombre, style: const TextStyle(color: _gris)),
            const SizedBox(height: 20),
            const Text(
              'CÓDIGO DE INVITACIÓN',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: _gris,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: _borde),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      sala.codigo,
                      key: const Key('codigo_sala'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      final mensajero = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: sala.codigo));
                      mensajero.showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compártelo con tu rival para que se una.',
              style: TextStyle(fontSize: 13, color: _gris),
            ),
            const SizedBox(height: 20),
            for (final jugador in sala.jugadores)
              _FilaJugador(
                nombre: jugador.usuario,
                esTu:
                    jugador.usuario.toLowerCase() == bloc.usuario.toLowerCase(),
                anfitrion: sala.esAnfitrion(jugador.usuario),
              ),
            if (!completa)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Esperando a tu rival…',
                      style: TextStyle(color: _gris),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (soyAnfitrion)
              FilledButton(
                key: const Key('boton_empezar'),
                onPressed: completa && bloc.state.conectado
                    ? () => context.read<PartidaBloc>().add(EmpezarPartida())
                    : null,
                child: Text(completa ? 'Empezar partida' : 'Falta tu rival'),
              )
            else
              Text(
                'Esperando a que ${sala.anfitrion} empiece la partida.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _gris),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('boton_salir_sala'),
              onPressed: () => context.read<PartidaBloc>().add(SalirSala()),
              child: const Text('Salir de la sala'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaJugador extends StatelessWidget {
  final String nombre;
  final bool esTu;
  final bool anfitrion;

  const _FilaJugador({
    required this.nombre,
    required this.esTu,
    required this.anfitrion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const AvatarUsuario(tamano: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              esTu ? '$nombre (tú)' : nombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (anfitrion) const _Etiqueta(texto: 'Anfitrión'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partida

/// Los dos jugadores con sus puntos y lo que están haciendo.
class Marcadores extends StatelessWidget {
  final SalaEnLinea sala;

  const Marcadores({super.key, required this.sala});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<PartidaBloc>();
    final yo = sala.yo(bloc.usuario);
    final rival = sala.rival(bloc.usuario);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borde)),
      ),
      child: Row(
        children: [
          if (yo != null)
            Expanded(
              child: _TarjetaJugador(jugador: yo, sala: sala, esTu: true),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sala.fase == FaseSala.juego)
                  Text(
                    'Ronda ${sala.ronda}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                else
                  const Text(
                    'Anclas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                if (sala.fase == FaseSala.juego)
                  CuentaRegresiva(
                    key: ValueKey(sala),
                    segundos: sala.segundosRonda,
                    builder: (s) => Text(
                      s == null ? 'reloj en pausa' : '$s s',
                      style: TextStyle(
                        fontSize: 12,
                        color: s != null && s <= 10 ? _rojo : _gris,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (rival != null)
            Expanded(
              child: _TarjetaJugador(jugador: rival, sala: sala, esTu: false),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            key: const Key('boton_rendirse'),
            style: TextButton.styleFrom(foregroundColor: _rojo),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Rendirse'),
            onPressed: () async {
              final partida = context.read<PartidaBloc>();
              if (await confirmarRendicion(context)) partida.add(Rendirse());
            },
          ),
        ],
      ),
    );
  }
}

class _TarjetaJugador extends StatelessWidget {
  final JugadorEnLinea jugador;
  final SalaEnLinea sala;
  final bool esTu;

  const _TarjetaJugador({
    required this.jugador,
    required this.sala,
    required this.esTu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: esTu ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (esTu) ...[
          const AvatarUsuario(tamano: 36),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: esTu
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                esTu ? '${jugador.usuario} (tú)' : jugador.usuario,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${jugador.puntos} ${jugador.puntos == 1 ? 'punto' : 'puntos'}',
                key: Key('puntos_${jugador.usuario}'),
                style: const TextStyle(fontSize: 13, color: _gris),
              ),
              const SizedBox(height: 4),
              _EstadoJugador(jugador: jugador, sala: sala),
            ],
          ),
        ),
        if (!esTu) ...[
          const SizedBox(width: 10),
          const AvatarUsuario(tamano: 36),
        ],
      ],
    );
  }
}

class _EstadoJugador extends StatelessWidget {
  final JugadorEnLinea jugador;
  final SalaEnLinea sala;

  const _EstadoJugador({required this.jugador, required this.sala});

  @override
  Widget build(BuildContext context) {
    if (!jugador.conectado) {
      return CuentaRegresiva(
        key: ValueKey((sala, jugador.usuario)),
        segundos: jugador.segundosGracia,
        builder: (s) => _Etiqueta(
          texto: s == null ? 'Desconectado' : 'Desconectado · $s s',
          color: _rojo,
          fondo: const Color(0xFFFEF2F2),
          icono: Icons.wifi_off_rounded,
        ),
      );
    }
    final (texto, verde) = switch (sala.fase) {
      FaseSala.anclas =>
        jugador.listo ? ('Anclas listas', true) : ('Poniendo anclas…', false),
      _ when jugador.terminado => ('Terminó', true),
      _ when jugador.jugoRonda => ('Ya jugó', true),
      _ => ('Pensando…', false),
    };
    return _Etiqueta(
      texto: texto,
      color: verde ? const Color(0xFF15803D) : _gris,
      fondo: verde ? const Color(0xFFF0FDF4) : const Color(0xFFF3F4F6),
    );
  }
}

class _FaseAnclas extends StatelessWidget {
  final SalaEnLinea sala;

  const _FaseAnclas({required this.sala});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<PartidaBloc>().state;
    final bloc = context.read<PartidaBloc>();
    final yo = sala.yo(bloc.usuario);
    final rival = sala.rival(bloc.usuario);
    final enviadas = estado.anclasEnviadas || (yo?.listo ?? false);

    return Column(
      children: [
        Marcadores(sala: sala),
        Expanded(
          child: enviadas
              ? _Cargando(
                  texto:
                      'Tus anclas están listas. Esperando a que '
                      '${rival?.usuario ?? 'tu rival'} ponga las suyas…',
                )
              : PantallaAnclas(
                  key: ValueKey(sala.codigo),
                  nivel: sala.datosNivel,
                  alTerminar: (tablero) => bloc.add(EnviarAnclas(tablero)),
                ),
        ),
      ],
    );
  }
}

class PartidaEnCurso extends StatefulWidget {
  final SalaEnLinea sala;

  const PartidaEnCurso({super.key, required this.sala});

  @override
  State<PartidaEnCurso> createState() => _PartidaEnCursoState();
}

class _PartidaEnCursoState extends State<PartidaEnCurso> {
  int? _elegido;

  // El servidor manda un estado nuevo con cada cambio. Los dados solo deben
  // rodar cuando cambia la ronda, no cada vez que llega un mensaje.
  int _ronda = -1;
  Dados? _dados;

  @override
  void didUpdateWidget(PartidaEnCurso viejo) {
    super.didUpdateWidget(viejo);
    if (widget.sala.ronda != _ronda) _elegido = null;
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<PartidaBloc>().state;
    final bloc = context.read<PartidaBloc>();
    final sala = widget.sala;
    final yo = sala.yo(bloc.usuario);
    final rival = sala.rival(bloc.usuario);
    final nivel = sala.datosNivel;

    if (sala.ronda != _ronda) {
      _ronda = sala.ronda;
      _dados = sala.dados;
    }
    final dados = _dados;

    final tablero = tableroCon(nivel, estado.casillas);
    final yaJugue = (yo?.yaJugo ?? false) || estado.pendiente != null;
    final elegido = yaJugue ? null : _elegido;
    final posibles = elegido == null || dados == null
        ? const <(int, int)>[]
        : tablero.celdasPosibles(elegido, dados.companeroDe(elegido));

    final nombreRival = rival?.usuario ?? 'tu rival';
    final String instruccion;
    if (estado.pendiente != null && !estado.conectado) {
      instruccion = 'Sin conexión: tu jugada se enviará al reconectar.';
    } else if (yo?.terminado ?? false) {
      instruccion =
          'Terminaste tu tablero. Esperando a que $nombreRival '
          'termine el suyo…';
    } else if (yaJugue) {
      instruccion = rival != null && !rival.conectado
          ? '$nombreRival se desconectó. Esperando a que vuelva…'
          : 'Esperando a que $nombreRival juegue…';
    } else if (elegido == null) {
      instruccion = 'Elige cuál de los dos números vas a escribir';
    } else if (posibles.isEmpty) {
      instruccion = 'Con ese número no hay jugada: prueba con el otro';
    } else {
      instruccion = 'Toca una casilla resaltada';
    }

    return Column(
      children: [
        Marcadores(sala: sala),
        if (rival != null && !rival.conectado)
          _AvisoRival(sala: sala, rival: rival),
        Expanded(
          child: VistaJuego(
            tablero: tablero,
            dados: dados,
            elegido: elegido,
            posibles: posibles,
            puedeTirar: false,
            nivel: nivel,
            conBotonTirar: false,
            dadosActivos: !yaJugue,
            instruccion: instruccion,
            alElegir: (n) => setState(() => _elegido = n),
            alColocar: (fila, columna) {
              final numero = _elegido;
              if (numero == null) return;
              bloc.add(ColocarNumero(fila, columna, numero));
              setState(() => _elegido = null);
            },
          ),
        ),
      ],
    );
  }
}

class _AvisoRival extends StatelessWidget {
  final SalaEnLinea sala;
  final JugadorEnLinea rival;

  const _AvisoRival({required this.sala, required this.rival});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('aviso_rival'),
      width: double.infinity,
      color: const Color(0xFFFEF2F2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CuentaRegresiva(
        key: ValueKey(sala),
        segundos: rival.segundosGracia,
        builder: (s) => Text(
          s == null
              ? '${rival.usuario} se desconectó.'
              : '${rival.usuario} se desconectó. Si no vuelve en $s s, '
                    'ganas la partida.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _rojo, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resultado

class ResultadoPartida extends StatelessWidget {
  final SalaEnLinea sala;

  const ResultadoPartida({super.key, required this.sala});

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<PartidaBloc>().usuario;
    final resultado = sala.resultado;
    final yo = sala.yo(usuario);
    final rival = sala.rival(usuario);
    final nombreRival = rival?.usuario ?? 'Tu rival';
    final gane = resultado?.ganador?.toLowerCase() == usuario.toLowerCase();
    final motivo = resultado?.motivo ?? MotivoFinal.empate;

    final (IconData icono, Color color, String titulo) = switch (motivo) {
      MotivoFinal.empate => (Icons.handshake_outlined, _gris, 'Empate'),
      MotivoFinal.abandonoAmbos => (
        Icons.cloud_off_outlined,
        _gris,
        'Partida anulada',
      ),
      _ when gane => (
        Icons.emoji_events_outlined,
        const Color(0xFFCA8A04),
        '¡Ganaste!',
      ),
      _ => (Icons.sentiment_dissatisfied_outlined, _gris, 'Perdiste'),
    };

    final detalle = switch (motivo) {
      MotivoFinal.puntos =>
        'Terminaste con ${yo?.puntos ?? 0} puntos contra '
            '${rival?.puntos ?? 0} de $nombreRival.',
      MotivoFinal.empate => 'Los dos terminaron con ${yo?.puntos ?? 0} puntos.',
      MotivoFinal.rendicion =>
        gane ? '$nombreRival se rindió.' : 'Te rendiste.',
      MotivoFinal.abandono =>
        gane
            ? '$nombreRival se desconectó y no volvió a tiempo.'
            : 'Te desconectaste y no volviste a tiempo.',
      MotivoFinal.abandonoAmbos =>
        'Los dos se desconectaron y nadie volvió a tiempo.',
    };

    return _Centrado(
      ancho: 440,
      child: _Tarjeta(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: color),
            const SizedBox(height: 12),
            Text(
              titulo,
              key: const Key('titulo_resultado'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: _gris),
            ),
            const SizedBox(height: 20),
            for (final j in sala.jugadores)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const AvatarUsuario(tamano: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        j.usuario,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (resultado?.ganador?.toLowerCase() ==
                        j.usuario.toLowerCase())
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.emoji_events,
                          size: 18,
                          color: Color(0xFFCA8A04),
                        ),
                      ),
                    Text(
                      '${j.puntos} pts',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('volver_lobby'),
                onPressed: () => context.read<PartidaBloc>().add(SalirSala()),
                child: const Text('Volver al lobby'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Piezas comunes

/// Cuenta hacia atrás desde [segundos] de a un segundo.
class CuentaRegresiva extends StatefulWidget {
  final int? segundos;
  final Widget Function(int? restantes) builder;

  const CuentaRegresiva({
    super.key,
    required this.segundos,
    required this.builder,
  });

  @override
  State<CuentaRegresiva> createState() => _CuentaRegresivaState();
}

class _CuentaRegresivaState extends State<CuentaRegresiva> {
  int? _restantes;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _empezar();
  }

  @override
  void didUpdateWidget(CuentaRegresiva viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.segundos != widget.segundos) _empezar();
  }

  void _empezar() {
    _reloj?.cancel();
    _restantes = widget.segundos;
    if (_restantes == null) return;
    _reloj = Timer.periodic(const Duration(seconds: 1), (reloj) {
      final quedan = (_restantes ?? 0) - 1;
      setState(() => _restantes = quedan < 0 ? 0 : quedan);
      if (quedan <= 0) reloj.cancel();
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_restantes);
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;
  final IconData? icono;

  const _Etiqueta({
    required this.texto,
    this.color = _gris,
    this.fondo = const Color(0xFFF3F4F6),
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Widget child;

  const _Tarjeta({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Centrado extends StatelessWidget {
  final Widget child;
  final double ancho;

  const _Centrado({required this.child, this.ancho = 420});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ancho),
          child: child,
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  final String texto;

  const _Cargando({required this.texto});

  @override
  Widget build(BuildContext context) {
    return _Centrado(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _gris, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
