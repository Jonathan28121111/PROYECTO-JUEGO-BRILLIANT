# Juego Brilliant proyecto escolar

Juego de lógica sobre un tablero de 7×7. Cada casilla lleva un número del 1 al 6
y pertenece a una zona de color, y cada color exige algo distinto de los números
que hay dentro.

## Reglas

- **Rojo** y **amarillo**: todos los números distintos entre sí
- **Azul**: todos los números iguales
- **Morado**: como máximo dos valores distintos
- **Verde**: acepta cualquier número del 1 al 6

Ganás cuando el tablero queda completo y todas las zonas cumplen su regla.

## Cuentas

El juego pide entrar o crear una cuenta al abrirse; también se puede **jugar
sin cuenta**. Las cuentas y las partidas en línea viven en el servidor, que
está en su propio repositorio: `servidor_brilliant` (carpeta hermana de esta).

La forma fácil de jugar, también con otra persona en el mismo Wi-Fi, es un
solo comando:

```bash
./jugar.sh
```

Arranca el servidor (si no estaba corriendo), compila el juego en modo
release apuntando a la IP de tu compu y lo sirve. Muestra las dos
direcciones: la tuya (`http://localhost:5050`) y la que abre la otra persona
(`http://<tu-ip>:5050`). Tras cambiar código, `./jugar.sh --compilar`.

Para programar con recarga en caliente (va más lento, es modo depuración):

```bash
# Terminal 1: el servidor
cd ../servidor_brilliant && dart run bin/servidor.dart

# Terminal 2: el juego
flutter run -d chrome
```

Por defecto la app busca el servidor en `http://localhost:8080`. Para cambiarlo:

```bash
flutter run --dart-define=SERVIDOR=http://10.0.2.2:8080   # emulador de Android
flutter run --dart-define=SERVIDOR=http://192.168.1.50:8080  # celular en la misma red
```

## Jugar en línea

Con una cuenta, la tarjeta **Jugar en línea** de la portada abre el lobby.
Una sala admite **de 2 a 5 jugadores**.

1. Uno **crea una sala** eligiendo el nivel y recibe un **código de 6
   caracteres** para compartir.
2. Los demás **se unen con el código**. Quien creó la sala pulsa **Empezar**
   cuando hay al menos dos.
3. Cada uno pone sus anclas. Después el servidor tira los dados **para todos
   a la vez**: cada quien elige su número y lo escribe en su tablero. La
   siguiente tirada sale cuando todos jugaron (o pasaron).
4. La partida se acaba al cerrar la ronda en que alguien llega a la **meta de
   puntos**, o cuando todos completan su tablero. Gana quien tenga más puntos;
   si empatan en el primer lugar, es empate.

| Jugadores | 2  | 3  | 4  | 5  |
|-----------|----|----|----|----|
| Meta      | 26 | 24 | 22 | 20 |

Son las marcas de la línea de puntos de las tarjetas. La meta se fija al
empezar la partida.

Cuando alguien completa una zona sale un aviso, por ejemplo *"beto completó
una zona roja (+6)"*. Cada jugador tiene un color (el punto junto a su nombre
en el marcador) y en tu tablero cada zona completada lleva una bolita con la
inicial y el color de quien la completó, en el orden en que llegaron. Así se
sabe quién ya se llevó el puntaje mayor de cada zona.

**Si se corta la conexión**, la app reintenta sola y muestra un aviso. Tienes
**10 segundos** para volver: el reloj de la ronda se detiene y los demás ven
cuánto te queda. Al volver (aunque recargues la página) tu tablero se
reconstruye desde el servidor. Si no vuelves a tiempo, quedas fuera de la
partida; si solo queda un jugador, gana por abandono, y si nadie vuelve, la
partida se anula.

Cada ronda dura como máximo 90 segundos; si no juegas, pasas. Si con los dados
no hay ninguna jugada posible, pasas automáticamente. En cualquier momento
puedes **rendirte** (botón de la bandera o al salir de la pantalla): quedas
fuera y los demás siguen; si solo queda uno, gana.

## En el iPhone

Necesitas **Xcode** (gratis en la App Store) y tu Apple ID.

1. Instala Xcode, ábrelo una vez y acepta lo que pida instalar.
2. En Xcode, en **Settings → Accounts**, agrega tu Apple ID.
3. Conecta el iPhone por cable. En el iPhone, activa **Configuración →
   Privacidad y seguridad → Modo de desarrollador** y reinícialo.
4. Abre `ios/Runner.xcworkspace` en Xcode, elige el target **Runner** →
   **Signing & Capabilities** y en **Team** pon tu Apple ID.
5. Con la compu y el iPhone en el mismo Wi-Fi:

   ```bash
   ./jugar.sh --iphone
   ```

   Arranca el servidor e instala el juego apuntando a la IP de tu compu.
6. La primera vez, en el iPhone ve a **Configuración → General → VPN y
   gestión de dispositivos** y confía en tu Apple ID. Al abrir el juego,
   acepta el permiso de **red local**.

Con una cuenta gratuita de Apple la app deja de abrir a los **7 días**; para
renovarla, vuelve a correr `./jugar.sh --iphone`. Las cuentas y las partidas
en línea funcionan mientras la compu tenga el servidor prendido.
