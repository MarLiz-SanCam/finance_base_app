/// Se lanza al intentar eliminar un registro que sigue referenciado por
/// otras filas (violación de llave foránea), por ejemplo una cuenta o
/// categoría con transacciones/obligaciones asociadas.
class RegistroEnUsoException implements Exception {
  RegistroEnUsoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
