import 'dart:io';

File? _archivo(String nombre) {
  final casa = Platform.environment['HOME'];
  if (casa == null || casa.isEmpty) return null;
  if (Platform.isIOS || Platform.isMacOS) {
    return File(
      '$casa/Library/Application Support/juego_brilliant_$nombre.txt',
    );
  }
  return File('$casa/.juego_brilliant_$nombre');
}

Future<String?> leerPreferencia(String nombre) async {
  try {
    final archivo = _archivo(nombre);
    if (archivo == null || !await archivo.exists()) return null;
    final texto = (await archivo.readAsString()).trim();
    return texto.isEmpty ? null : texto;
  } on FileSystemException {
    return null;
  }
}

Future<void> guardarPreferencia(String nombre, String valor) async {
  try {
    final archivo = _archivo(nombre);
    if (archivo == null) return;
    await archivo.parent.create(recursive: true);
    await archivo.writeAsString(valor);
  } on FileSystemException {
    return;
  }
}
