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
