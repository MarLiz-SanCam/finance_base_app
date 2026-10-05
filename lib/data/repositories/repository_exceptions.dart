/// Se lanza al intentar cargar a una cuenta de crédito un monto mayor a su
/// crédito disponible (límite + saldo).
class CreditoInsuficienteException implements Exception {
  CreditoInsuficienteException(
    this.mensaje, {
    required this.disponibleCentavos,
  });

  final String mensaje;
  final int disponibleCentavos;

  @override
  String toString() => mensaje;
}

/// Se lanza al intentar eliminar un registro que sigue referenciado por
/// otras filas (violación de llave foránea), por ejemplo una cuenta o
/// categoría con transacciones/obligaciones asociadas.
class RegistroEnUsoException implements Exception {
  RegistroEnUsoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
