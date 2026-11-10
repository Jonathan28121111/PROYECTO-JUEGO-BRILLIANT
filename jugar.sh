#!/usr/bin/env bash
# Arranca el servidor y el juego para jugar en la red local (mismo Wi-Fi).
#
#   ./jugar.sh              compila si cambió el código o la IP y sirve el juego
#   ./jugar.sh --compilar   fuerza a compilar de nuevo
#
# El juego se compila en modo release: va mucho más fluido que con
# `flutter run`, que es modo depuración. Se apaga todo con Ctrl+C.

set -euo pipefail
cd "$(dirname "$0")"

PUERTO_JUEGO="${PUERTO_JUEGO:-5050}"
PUERTO_SERVIDOR="${PUERTO_SERVIDOR:-8080}"
CARPETA_SERVIDOR="${CARPETA_SERVIDOR:-../servidor_brilliant}"

escuchando() { lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }

# La IP de esta compu en el Wi-Fi (macOS primero, luego Linux).
IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null ||
  hostname -I 2>/dev/null | awk '{print $1}' || true)"
if [[ -z "$IP" ]]; then
  echo "No encontré tu IP en la red; solo se podrá jugar en esta compu."
  IP="localhost"
fi
DIRECCION_SERVIDOR="http://$IP:$PUERTO_SERVIDOR"

if escuchando "$PUERTO_JUEGO"; then
  echo "El puerto $PUERTO_JUEGO ya está ocupado (¿quedó abierto un 'flutter run'?)."
  echo "Ciérralo con 'q' en su terminal, o usa otro: PUERTO_JUEGO=5051 ./jugar.sh"
  exit 1
fi

PID_SERVIDOR=""
apagar() {
  echo
  if [[ -n "$PID_SERVIDOR" ]]; then
    echo "Apagando el servidor..."
    kill "$PID_SERVIDOR" 2>/dev/null || true
  fi
}
trap apagar EXIT

# 1. El servidor: se usa el que ya esté corriendo o se arranca uno.
if escuchando "$PUERTO_SERVIDOR"; then
  echo "✓ El servidor ya estaba corriendo en el puerto $PUERTO_SERVIDOR."
else
  if [[ ! -d "$CARPETA_SERVIDOR" ]]; then
    echo "No encuentro el servidor en $CARPETA_SERVIDOR."
    echo "Indica dónde está: CARPETA_SERVIDOR=/ruta/al/servidor ./jugar.sh"
    exit 1
  fi
  echo "Arrancando el servidor..."
  (cd "$CARPETA_SERVIDOR" && dart pub get >/dev/null &&
    exec dart run bin/servidor.dart --puerto "$PUERTO_SERVIDOR") &
  PID_SERVIDOR=$!
  for _ in $(seq 1 30); do
    escuchando "$PUERTO_SERVIDOR" && break
    sleep 1
  done
  escuchando "$PUERTO_SERVIDOR" || { echo "El servidor no arrancó."; exit 1; }
  echo "✓ Servidor listo en el puerto $PUERTO_SERVIDOR."
fi

# 2. El juego: se compila si se pide, si cambió la IP o si hay código más
#    nuevo que la última compilación.
MARCA="build/web/.servidor"
motivo=""
if [[ "${1:-}" == "--compilar" ]]; then
  motivo="lo pediste con --compilar"
elif [[ ! -f "$MARCA" ]]; then
  motivo="no había ninguna compilación"
elif [[ "$(cat "$MARCA")" != "$DIRECCION_SERVIDOR" ]]; then
  motivo="cambió la dirección del servidor"
elif [[ -n "$(find lib web pubspec.yaml pubspec.lock -newer "$MARCA" -print -quit)" ]]; then
  motivo="cambió el código"
fi

if [[ -n "$motivo" ]]; then
  echo "Compilando el juego en modo release ($motivo)..."
  flutter build web --release --dart-define=SERVIDOR="$DIRECCION_SERVIDOR"
  echo "$DIRECCION_SERVIDOR" >"$MARCA"
else
  echo "✓ El juego compilado ya está al día."
fi

echo
echo "============================================================"
echo "  En esta compu:       http://localhost:$PUERTO_JUEGO"
echo "  En otra compu/cel:   http://$IP:$PUERTO_JUEGO"
echo "  (tienen que estar en el mismo Wi-Fi)"
echo "  Ctrl+C para apagar todo."
echo "============================================================"
echo

# Servidor de archivos: le pide al navegador no guardar copias (así una
# compilación nueva se ve con solo recargar) y manda comprimido lo que se
# comprime bien (el juego baja de ~2.7 MB a ~0.8 MB).
python3 - "$PUERTO_JUEGO" build/web <<'PY'
import functools, gzip, http.server, os, sys

COMPRIMIBLES = (".js", ".json", ".html", ".css", ".wasm", ".symbols", ".otf", ".ttf")
comprimidos = {}  # ruta -> (fecha de modificación, bytes en gzip)

class Servidor(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_GET(self):
        ruta = self.translate_path(self.path)
        if os.path.isdir(ruta):
            ruta = os.path.join(ruta, "index.html")
        acepta = "gzip" in self.headers.get("Accept-Encoding", "")
        if not (acepta and ruta.endswith(COMPRIMIBLES) and os.path.isfile(ruta)):
            return super().do_GET()
        fecha = os.path.getmtime(ruta)
        guardado = comprimidos.get(ruta)
        if guardado is None or guardado[0] != fecha:
            with open(ruta, "rb") as archivo:
                guardado = (fecha, gzip.compress(archivo.read(), 6))
            comprimidos[ruta] = guardado
        cuerpo = guardado[1]
        self.send_response(200)
        self.send_header("Content-Type", self.guess_type(ruta))
        self.send_header("Content-Encoding", "gzip")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)

    def log_message(self, formato, *argumentos):
        pass  # sin una línea por cada archivo pedido

puerto, carpeta = int(sys.argv[1]), sys.argv[2]
manejador = functools.partial(Servidor, directory=carpeta)
http.server.ThreadingHTTPServer(("0.0.0.0", puerto), manejador).serve_forever()
PY
