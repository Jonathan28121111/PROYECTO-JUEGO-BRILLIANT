bool todosSerianIguales(List<int> lista, int numero) {
  for (final n in lista) {
    if (n != numero) {
      return false;
    }
  }
  return true;
}

bool cualquierNumeroEsValido(List<int> lista, int numero) {
  return numero >= 1 && numero <= 6;
}