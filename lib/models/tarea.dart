class Tarea {
  final String id;
  final String nombre;
  final String materia;
  final DateTime fechaEntrega;
  final List<String> diasTrabajo;
  final int tiempoSesion;
  final int sesionesPorDia;
  bool completada;

  Tarea({
    required this.id,
    required this.nombre,
    required this.materia,
    required this.fechaEntrega,
    required this.diasTrabajo,
    required this.tiempoSesion,
    required this.sesionesPorDia,
    this.completada = false,
  });
}