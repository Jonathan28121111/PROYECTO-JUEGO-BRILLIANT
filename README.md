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

```bash
# Terminal 1: el servidor
cd ../servidor_brilliant && dart run bin/servidor.dart

# Terminal 2: el juego
flutter run
```

Por defecto la app busca el servidor en `http://localhost:8080`. Para cambiarlo:

```bash
flutter run --dart-define=SERVIDOR=http://10.0.2.2:8080   # emulador de Android
flutter run --dart-define=SERVIDOR=http://192.168.1.50:8080  # celular en la misma red
```

## Jugar en línea

Con una cuenta, el botón **Jugar en línea** de la barra abre el lobby:

1. Uno **crea una sala** eligiendo el nivel y recibe un **código de 6
   caracteres** para compartir.
2. El otro **se une con el código**. Quien creó la sala pulsa **Empezar**.
3. Cada uno pone sus anclas. Después el servidor tira los dados **para los
   dos a la vez**: cada quien elige su número y lo escribe en su tablero. La
   siguiente tirada sale cuando ambos jugaron (o pasaron).
4. Gana quien tenga más puntos cuando los dos completan su tablero.

**Si se corta la conexión**, la app reintenta sola y muestra un aviso. Tienes
**60 segundos** para volver: el reloj de la ronda se detiene y tu rival ve
cuánto te queda. Al volver (aunque recargues la página) tu tablero se
reconstruye desde el servidor. Si no vuelves a tiempo, tu rival gana por
abandono; si los dos se caen y nadie vuelve, la partida se anula.

Cada ronda dura como máximo 90 segundos; si no juegas, pasas. Si con los dados
no hay ninguna jugada posible, pasas automáticamente. En cualquier momento
puedes **rendirte** (botón de la bandera o al salir de la pantalla), y tu
rival gana.
