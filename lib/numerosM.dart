bool cabenSoloDosValores(List<int> lista, int numero) {
  final valores = {...lista, numero};
  return valores.length <= 2;
}