
bool todosSerianDiferentes(List<int> lista, int numero) {
  
  if (lista.contains(numero)) {
    return false;
  }
  
  final sinRepetidos = lista.toSet();
  return sinRepetidos.length == lista.length;
}

