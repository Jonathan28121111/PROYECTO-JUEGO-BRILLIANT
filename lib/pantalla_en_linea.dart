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
import 'pantalla_niveles.dart';
import 'partida_bloc.dart';
import 'sala_en_linea.dart';
import 'sesion_bloc.dart';
import 'vista_juego.dart';

// ---------------------------------------------------------------------------
// Estilo: un solo acento (el primario del tema), grises neutros, rojo solo
// para lo destructivo. Pesos 400/500/600. Espacios de 4 en 4.

const Color _texto = Color(0xFF111827);
const Color _secundario = Color(0xFF6B7280);
const Color _borde = Color(0xFFE5E7EB);
const Color _fondoSuave = Color(0xFFF9FAFB);
const Color _rojo = Color(0xFFB91C1C);
const Color _verde = Color(0xFF15803D);

const TextStyle _tituloPagina = TextStyle(
  fontSize: 24,
  height: 1.25,
  fontWeight: FontWeight.w600,
  color: _texto,
);
const TextStyle _tituloSeccion = TextStyle(
  fontSize: 18,
  height: 1.25,
  fontWeight: FontWeight.w600,
  color: _texto,
);
const TextStyle _cuerpo = TextStyle(fontSize: 16, height: 1.5, color: _texto);
const TextStyle _apoyo = TextStyle(
  fontSize: 14,
  height: 1.5,
  color: _secundario,
);
const TextStyle _etiqueta = TextStyle(
  fontSize: 14,
  height: 1.5,
  fontWeight: FontWeight.w500,
  color: _texto,
);

/// Ancho a partir del cual hay espacio para botones con texto en la barra.
const double _anchoAmplio = 600;

bool _esAngosto(BuildContext context) =>
    MediaQuery.sizeOf(context).width < _anchoAmplio;

/// Cómo se abre la conexión con el servidor de partidas. Las pruebas la
/// cambian por una falsa.
class FabricaConexion {
  final AbrirConexion abrir;

  const FabricaConexion(this.abrir);
}

// ---------------------------------------------------------------------------
// Entrada desde la portada

/// El botón de la barra para entrar al modo en línea. En pantallas angostas
/// se queda en ícono, con su tooltip.
class BotonEnLinea extends StatelessWidget {
  const BotonEnLinea({super.key});

  @override
  Widget build(BuildContext context) {
    if (_esAngosto(context)) {
      return IconButton(
        key: const Key('boton_en_linea'),
        tooltip: 'Jugar en línea',
        icon: const Icon(Icons.groups_outlined),
        onPressed: () => abrirModoEnLinea(context),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.tonalIcon(
        key: const Key('boton_en_linea'),
        icon: const Icon(Icons.groups_outlined, size: 20),
        label: const Text('Jugar en línea'),
        onPressed: () => abrirModoEnLinea(context),
      ),
    );
  }
}

/// La tarjeta del modo en línea en la portada, junto a "Jugar solo".
class TarjetaEnLinea extends StatelessWidget {
  const TarjetaEnLinea({super.key});

  @override
  Widget build(BuildContext context) {
    final conCuenta = context.watch<SesionBloc>().state is ConCuenta;

    return TarjetaModo(
      key: const Key('modo_en_linea'),
      claveBoton: const Key('tarjeta_en_linea'),
      ilustracion: const _Duelo(),
      titulo: 'Jugar en línea',
      descripcion: conCuenta
          ? 'Crea una sala y comparte el código, o únete a la de un amigo. '
                'Los dos juegan con los mismos dados.'
          : 'Inicia sesión para crear una sala o unirte a la de un amigo.',
      accion: conCuenta ? 'Jugar en línea' : 'Iniciar sesión para jugar',
      iconoAccion: conCuenta
          ? Icons.arrow_forward_rounded
          : Icons.login_rounded,
      alTocar: () => abrirModoEnLinea(context),
    );
  }
}

/// Dos jugadores frente a frente: la ilustración del modo en línea.
class _Duelo extends StatelessWidget {
  const _Duelo();

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AvatarUsuario(tamano: 56),
        const SizedBox(width: 16),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _borde),
          ),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primario,
            ),
          ),
        ),
        const SizedBox(width: 16),
        AvatarUsuario(tamano: 56, color: primario),
      ],
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
            autofocus: true,
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Seguir sin cuenta'),
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
    final rival = sala?.rival(context.read<PartidaBloc>().usuario)?.usuario;

    // maybePop respeta la confirmación si hay partida en curso.
    void volverALocal() => Navigator.of(context).maybePop();

    return MultiBlocListener(
      listeners: [
        BlocListener<PartidaBloc, PartidaState>(
          listenWhen: (antes, ahora) =>
              ahora.numeroAviso != antes.numeroAviso && ahora.aviso != null,
          listener: (context, estado) =>
              _avisar(context, estado.aviso!, error: estado.avisoEsError),
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
          if (await confirmarRendicion(context, saliendo: true, rival: rival)) {
            bloc.add(Rendirse());
            navegador.pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Jugar en línea'),
            actions: [
              if (_esAngosto(context))
                IconButton(
                  key: const Key('boton_jugar_local'),
                  tooltip: 'Volver a jugar local',
                  icon: const Icon(Icons.person_outline_rounded),
                  onPressed: volverALocal,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    key: const Key('boton_jugar_local'),
                    icon: const Icon(Icons.person_outline_rounded, size: 20),
                    label: const Text('Jugar local'),
                    onPressed: volverALocal,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              const BannerConexion(),
              Expanded(child: _cuerpo(estado)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(PartidaState estado) {
    if (estado.conexion == EstadoConexion.expulsado) {
      return _Expulsado(motivo: estado.motivoExpulsion ?? '');
    }
    final sala = estado.sala;
    if (sala == null) return const Lobby();
    return switch (sala.fase) {
      FaseSala.espera => SalaDeEspera(sala: sala),
      FaseSala.anclas => _FaseAnclas(sala: sala),
      FaseSala.juego => PartidaEnCurso(sala: sala),
      FaseSala.terminada => ResultadoPartida(sala: sala),
    };
  }
}

void _avisar(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? _rojo : const Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Confirmación de rendirse: nombra al rival, el botón dice lo que hace y el
/// foco empieza en "Seguir jugando" para no rendirse por accidente.
Future<bool> confirmarRendicion(
  BuildContext context, {
  bool saliendo = false,
  String? rival,
}) async {
  final contra = rival == null ? '' : ' ante $rival';
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      icon: const Icon(Icons.flag_outlined, color: _rojo, size: 32),
      title: Text(saliendo ? '¿Salir y rendirte$contra?' : '¿Rendirte$contra?'),
      content: Text(
        saliendo
            ? 'La partida sigue en curso. Si sales, ${rival ?? 'tu rival'} '
                  'gana la partida.'
            : '${rival ?? 'Tu rival'} gana la partida. No se puede deshacer.',
      ),
      actions: [
        TextButton(
          autofocus: true,
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
    const naranja = Color(0xFF9A3412);

    return Container(
      key: const Key('banner_conexion'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        border: Border(bottom: BorderSide(color: Color(0xFFFED7AA))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 20, color: naranja),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sin conexión con el servidor',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: naranja,
                  ),
                ),
                Text(
                  [
                    if (espera != null && espera > 0)
                      'Reintentando en $espera '
                          '${espera == 1 ? 'segundo' : 'segundos'}.'
                    else
                      'Reconectando…',
                    if (enPartida) 'Tienes 60 s para volver a la partida.',
                  ].join(' '),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: naranja,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: const Key('reintentar_ahora'),
            onPressed: () => context.read<PartidaBloc>().add(ReintentarAhora()),
            child: const Text('Reintentar ahora'),
          ),
        ],
      ),
    );
  }
}

class _Expulsado extends StatelessWidget {
  final String motivo;

  const _Expulsado({required this.motivo});

  @override
  Widget build(BuildContext context) {
    final sesionVencida = motivo.contains('sesión');
    return _Columna(
      ancho: 480,
      centrada: true,
      children: [
        Icon(
          sesionVencida ? Icons.lock_clock_outlined : Icons.devices_outlined,
          size: 40,
          color: _secundario,
        ),
        const SizedBox(height: 16),
        Text(motivo, textAlign: TextAlign.center, style: _cuerpo),
        const SizedBox(height: 24),
        if (sesionVencida)
          FilledButton(
            onPressed: () => context.read<SesionBloc>().add(CerrarSesion()),
            child: const Text('Iniciar sesión'),
          )
        else
          FilledButton(
            key: const Key('jugar_aqui'),
            onPressed: () => context.read<PartidaBloc>().add(ReintentarAhora()),
            child: const Text('Jugar en esta ventana'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lobby: dos tarjetas con el mismo estilo que la portada, una para crear
// la sala y otra para unirse con el código.

class Lobby extends StatefulWidget {
  const Lobby({super.key});

  @override
  State<Lobby> createState() => _LobbyState();
}

enum _Pedido { crear, unirse }

class _LobbyState extends State<Lobby> {
  final _codigo = TextEditingController();
  late int _nivel = nivelesOficiales.firstWhere((n) => n.disponible).numero;
  _Pedido? _pedido;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _crear() {
    if (context.read<PartidaBloc>().state.cargando) return;
    setState(() => _pedido = _Pedido.crear);
    context.read<PartidaBloc>().add(CrearSala(_nivel));
  }

  void _unirse() {
    if (context.read<PartidaBloc>().state.cargando) return;
    setState(() => _pedido = _Pedido.unirse);
    context.read<PartidaBloc>().add(UnirseSala(_codigo.text));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<PartidaBloc>();
    final estado = bloc.state;
    bool ocupado(_Pedido pedido) => estado.cargando && _pedido == pedido;

    _PanelLobby crear({required bool estirar}) => _PanelLobby(
      estirar: estirar,
      icono: Icons.add_rounded,
      titulo: 'Crear sala',
      descripcion:
          'Elige el tablero. Te damos un código para invitar a tu '
          'rival.',
      contenido: [
        const Text('Tablero', style: _etiqueta),
        const SizedBox(height: 8),
        _SelectorNivel(
          elegido: _nivel,
          alElegir: (n) => setState(() => _nivel = n),
        ),
      ],
      boton: FilledButton(
        key: const Key('boton_crear_sala'),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: _crear,
        child: ocupado(_Pedido.crear)
            ? const _Girando(claro: true)
            : const Text('Crear sala'),
      ),
    );

    _PanelLobby unirse({required bool estirar}) => _PanelLobby(
      estirar: estirar,
      icono: Icons.login_rounded,
      titulo: 'Unirse a una sala',
      descripcion: 'Escribe el código de 6 caracteres que te compartieron.',
      contenido: [
        TextField(
          key: const Key('campo_codigo'),
          controller: _codigo,
          maxLength: 6,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            _Mayusculas(),
          ],
          style: const TextStyle(
            fontSize: 24,
            height: 1.25,
            letterSpacing: 8,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
          onChanged: (_) => context.read<PartidaBloc>().add(CorregirCodigo()),
          onSubmitted: (_) => _unirse(),
          decoration: InputDecoration(
            labelText: 'Código de la sala',
            hintText: 'K7P2QX',
            counterText: '',
            errorText: estado.errorCodigo,
            errorMaxLines: 2,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
          ),
        ),
      ],
      boton: FilledButton(
        key: const Key('boton_unirse'),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: _unirse,
        child: ocupado(_Pedido.unirse)
            ? const _Girando(claro: true)
            : const Text('Unirse a la sala'),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${bloc.usuario}',
                style: _tituloPagina.copyWith(fontSize: 28, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea una sala e invita a alguien con el código, o únete a '
                'la sala de otra persona.',
                style: _cuerpo.copyWith(color: _secundario),
              ),
              if (!estado.conectado) ...[
                const SizedBox(height: 12),
                const _Estado(
                  icono: _Girando(),
                  texto: 'Conectando con el servidor…',
                ),
              ],
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, espacio) => espacio.maxWidth < 640
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          crear(estirar: false),
                          const SizedBox(height: 16),
                          unirse(estirar: false),
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: crear(estirar: true)),
                            const SizedBox(width: 24),
                            Expanded(child: unirse(estirar: true)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelLobby extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final List<Widget> contenido;
  final Widget boton;

  /// Lado a lado las dos tarjetas miden lo mismo y el botón baja al fondo.
  final bool estirar;

  const _PanelLobby({
    this.estirar = false,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.contenido,
    required this.boton,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colores.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icono, color: colores.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(titulo, style: _tituloSeccion.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(descripcion, style: _apoyo),
          const SizedBox(height: 24),
          ...contenido,
          const SizedBox(height: 24),
          if (estirar) const Spacer(),
          boton,
        ],
      ),
    );
  }
}

/// Los tableros como miniaturas que se tocan para elegir.
class _SelectorNivel extends StatelessWidget {
  final int elegido;
  final ValueChanged<int> alElegir;

  const _SelectorNivel({required this.elegido, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final (i, nivel) in nivelesOficiales.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: elegido == nivel.numero,
              button: true,
              label: nivel.nombre,
              excludeSemantics: true,
              child: Material(
                color: elegido == nivel.numero
                    ? colores.primaryContainer.withValues(alpha: 0.5)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: elegido == nivel.numero ? colores.primary : _borde,
                    width: elegido == nivel.numero ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  key: Key('nivel_${nivel.numero}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: nivel.disponible ? () => alElegir(nivel.numero) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        MiniaturaNivel(nivel: nivel),
                        const SizedBox(height: 8),
                        Text(
                          nivel.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: elegido == nivel.numero
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _texto,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
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

// ---------------------------------------------------------------------------
// Sala de espera — patrón Detail / Record: nombre, metadatos, acciones y
// secciones sin tarjetas alrededor.

class SalaDeEspera extends StatelessWidget {
  final SalaEnLinea sala;

  const SalaDeEspera({super.key, required this.sala});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<PartidaBloc>();
    final soyAnfitrion = sala.esAnfitrion(bloc.usuario);
    final completa = sala.jugadores.length >= 2;

    final empezar = FilledButton(
      key: const Key('boton_empezar'),
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: () {
        if (!completa) {
          _avisar(
            context,
            'Falta que tu rival se una. Compártele el código para empezar.',
          );
          return;
        }
        context.read<PartidaBloc>().add(EmpezarPartida());
      },
      child: const Text('Empezar partida'),
    );
    final salir = OutlinedButton(
      key: const Key('boton_salir_sala'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: () => context.read<PartidaBloc>().add(SalirSala()),
      child: const Text('Salir de la sala'),
    );

    return _Columna(
      ancho: 640,
      children: [
        const Text('Sala de espera', style: _tituloPagina),
        const SizedBox(height: 4),
        Text(
          '${sala.datosNivel.nombre} · ${sala.jugadores.length} de 2 '
          'jugadores',
          style: _apoyo,
        ),
        const SizedBox(height: 24),

        const Text('Código de invitación', style: _etiqueta),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          decoration: BoxDecoration(
            color: _fondoSuave,
            border: Border.all(color: _borde),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  sala.codigo,
                  key: const Key('codigo_sala'),
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                    color: _texto,
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
        const Text('Compártelo con tu rival para que se una.', style: _apoyo),
        const SizedBox(height: 32),

        const Text('Jugadores', style: _etiqueta),
        const SizedBox(height: 8),
        _Lista(
          filas: [
            for (final jugador in sala.jugadores)
              _FilaJugador(
                nombre: jugador.usuario,
                esTu:
                    jugador.usuario.toLowerCase() == bloc.usuario.toLowerCase(),
                anfitrion: sala.esAnfitrion(jugador.usuario),
              ),
            if (!completa)
              const _Estado(icono: _Girando(), texto: 'Esperando a tu rival…'),
          ],
        ),
        const SizedBox(height: 32),

        if (soyAnfitrion)
          _Acciones(principal: empezar, secundaria: salir)
        else ...[
          Text(
            'Esperando a que ${sala.anfitrion} empiece la partida.',
            style: _apoyo,
          ),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: salir),
        ],
      ],
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
    return Row(
      children: [
        const AvatarUsuario(tamano: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: nombre,
              children: [
                if (esTu)
                  const TextSpan(
                    text: '  (tú)',
                    style: TextStyle(color: _secundario),
                  ),
              ],
            ),
            style: _cuerpo.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        if (anfitrion) const Text('Anfitrión', style: _apoyo),
      ],
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
    final angosto = _esAngosto(context);

    Future<void> rendirse() async {
      final partida = context.read<PartidaBloc>();
      if (await confirmarRendicion(context, rival: rival?.usuario)) {
        partida.add(Rendirse());
      }
    }

    final centro = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sala.fase == FaseSala.juego ? 'Ronda ${sala.ronda}' : 'Anclas',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
        if (sala.fase == FaseSala.juego)
          CuentaRegresiva(
            key: ValueKey(sala),
            segundos: sala.segundosRonda,
            builder: (s) => Text(
              s == null ? 'reloj en pausa' : '$s s',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: s != null && s <= 10 ? _rojo : _secundario,
              ),
            ),
          ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: angosto ? 12 : 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borde)),
      ),
      child: Row(
        children: [
          if (yo != null)
            Expanded(
              child: _TarjetaJugador(
                jugador: yo,
                sala: sala,
                esTu: true,
                compacta: angosto,
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: angosto ? 8 : 16),
            child: centro,
          ),
          if (rival != null)
            Expanded(
              child: _TarjetaJugador(
                jugador: rival,
                sala: sala,
                esTu: false,
                compacta: angosto,
              ),
            ),
          SizedBox(width: angosto ? 4 : 16),
          if (angosto)
            IconButton(
              key: const Key('boton_rendirse'),
              tooltip: 'Rendirse',
              color: _rojo,
              icon: const Icon(Icons.flag_outlined),
              onPressed: rendirse,
            )
          else
            TextButton.icon(
              key: const Key('boton_rendirse'),
              style: TextButton.styleFrom(
                foregroundColor: _rojo,
                minimumSize: const Size(0, 48),
              ),
              icon: const Icon(Icons.flag_outlined, size: 20),
              label: const Text('Rendirse'),
              onPressed: rendirse,
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
  final bool compacta;

  const _TarjetaJugador({
    required this.jugador,
    required this.sala,
    required this.esTu,
    required this.compacta,
  });

  @override
  Widget build(BuildContext context) {
    final alineacion = esTu ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final datos = Column(
      crossAxisAlignment: alineacion,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          esTu ? '${jugador.usuario} (tú)' : jugador.usuario,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
        Text(
          '${jugador.puntos} ${jugador.puntos == 1 ? 'punto' : 'puntos'}',
          key: Key('puntos_${jugador.usuario}'),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 1.5, color: _texto),
        ),
        _EstadoJugador(jugador: jugador, sala: sala),
      ],
    );
    if (compacta) return datos;

    return Row(
      mainAxisAlignment: esTu ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (esTu) ...[
          const AvatarUsuario(tamano: 40),
          const SizedBox(width: 12),
        ],
        Flexible(child: datos),
        if (!esTu) ...[
          const SizedBox(width: 12),
          const AvatarUsuario(tamano: 40),
        ],
      ],
    );
  }
}

/// Lo que está haciendo un jugador: un punto de color y el texto. El color
/// nunca va solo, siempre con palabras.
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
        builder: (s) => _Punto(
          texto: s == null ? 'Desconectado' : 'Desconectado · $s s',
          color: _rojo,
        ),
      );
    }
    final (texto, listo) = switch (sala.fase) {
      FaseSala.anclas =>
        jugador.listo ? ('Anclas listas', true) : ('Poniendo anclas…', false),
      _ when jugador.terminado => ('Terminó', true),
      _ when jugador.jugoRonda => ('Ya jugó', true),
      _ => ('Pensando…', false),
    };
    return _Punto(texto: texto, color: listo ? _verde : _secundario);
  }
}

class _Punto extends StatelessWidget {
  final String texto;
  final Color color;

  const _Punto({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
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
              ? _Columna(
                  ancho: 480,
                  centrada: true,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: _verde,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tus anclas están listas',
                      textAlign: TextAlign.center,
                      style: _tituloSeccion,
                    ),
                    const SizedBox(height: 8),
                    _Estado(
                      icono: const _Girando(),
                      texto:
                          'Esperando a que ${rival?.usuario ?? 'tu rival'} '
                          'ponga las suyas…',
                    ),
                  ],
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
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(bottom: BorderSide(color: Color(0xFFFECACA))),
      ),
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
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: _rojo,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resultado — patrón Detail / Record.

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
      MotivoFinal.empate => (Icons.handshake_outlined, _secundario, 'Empate'),
      MotivoFinal.abandonoAmbos => (
        Icons.cloud_off_outlined,
        _secundario,
        'Partida anulada',
      ),
      _ when gane => (
        Icons.emoji_events_outlined,
        const Color(0xFFB45309),
        '¡Ganaste!',
      ),
      _ => (Icons.flag_outlined, _secundario, 'Perdiste'),
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

    return _Columna(
      ancho: 480,
      children: [
        Icon(icono, size: 40, color: color),
        const SizedBox(height: 16),
        Text(
          titulo,
          key: const Key('titulo_resultado'),
          style: _tituloPagina.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(detalle, style: _cuerpo.copyWith(color: _secundario)),
        const SizedBox(height: 24),
        _Lista(
          filas: [
            for (final j in sala.jugadores)
              Row(
                children: [
                  const AvatarUsuario(tamano: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      j.usuario,
                      style: _cuerpo.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (resultado?.ganador?.toLowerCase() ==
                      j.usuario.toLowerCase()) ...[
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 20,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${j.puntos} pts',
                    style: _cuerpo.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 32),
        _Acciones(
          principal: FilledButton(
            key: const Key('volver_lobby'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => context.read<PartidaBloc>().add(SalirSala()),
            child: const Text('Volver al lobby'),
          ),
          secundaria: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Jugar local'),
          ),
        ),
      ],
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
  Widget build(BuildContext context) =>
      RepaintBoundary(child: widget.builder(_restantes));
}

/// Superficie L1: borde de 1px y filas separadas por líneas finas.
class _Lista extends StatelessWidget {
  final List<Widget> filas;

  const _Lista({required this.filas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borde),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _borde),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: filas[i],
            ),
          ],
        ],
      ),
    );
  }
}

/// Acción principal y secundaria: en fila en pantallas anchas, apiladas en
/// las angostas.
class _Acciones extends StatelessWidget {
  final Widget principal;
  final Widget secundaria;

  const _Acciones({required this.principal, required this.secundaria});

  @override
  Widget build(BuildContext context) {
    if (_esAngosto(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [principal, const SizedBox(height: 12), secundaria],
      );
    }
    return Row(children: [principal, const SizedBox(width: 12), secundaria]);
  }
}

/// Un estado en línea: ícono pequeño y texto secundario.
class _Estado extends StatelessWidget {
  final Widget icono;
  final String texto;

  const _Estado({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(dimension: 16, child: icono),
        const SizedBox(width: 8),
        Flexible(child: Text(texto, style: _apoyo)),
      ],
    );
  }
}

class _Girando extends StatelessWidget {
  final bool claro;

  const _Girando({this.claro = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: claro ? Colors.white : null,
      ),
    );
  }
}

/// Columna de contenido con ancho máximo y margen de 16 px.
class _Columna extends StatelessWidget {
  final double ancho;
  final bool centrada;
  final List<Widget> children;

  const _Columna({
    required this.ancho,
    required this.children,
    this.centrada = false,
  });

  @override
  Widget build(BuildContext context) {
    final columna = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ancho),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centrada
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
      child: centrada
          ? Center(child: columna)
          : Align(alignment: Alignment.topCenter, child: columna),
    );
  }
}
