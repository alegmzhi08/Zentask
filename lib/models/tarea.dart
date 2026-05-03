class Tarea {
  final String id;
  final String nombre;
  final String materia;
  final DateTime fechaEntrega;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> diasTrabajo;
  final int tiempoSesion;
  final int sesionesPorDia;
  bool completada;
  final String uid;

  Tarea({
    required this.id,
    required this.nombre,
    required this.materia,
    required this.fechaEntrega,
    this.startDate,
    this.endDate,
    required this.diasTrabajo,
    required this.tiempoSesion,
    required this.sesionesPorDia,
    this.completada = false,
    required this.uid,
  });

  // Convierte la tarea a un mapa para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'materia': materia,
      'fechaEntrega': fechaEntrega.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'diasTrabajo': diasTrabajo.join(','),
      'tiempoSesion': tiempoSesion,
      'sesionesPorDia': sesionesPorDia,
      'completada': completada ? 1 : 0,
      'uid': uid,
    };
  }

  // Convierte un mapa de SQLite a una Tarea
  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'],
      nombre: map['nombre'],
      materia: map['materia'],
      fechaEntrega: DateTime.parse(map['fechaEntrega']),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : null,
      diasTrabajo: (map['diasTrabajo'] as String).isEmpty
          ? []
          : (map['diasTrabajo'] as String).split(','),
      tiempoSesion: map['tiempoSesion'],
      sesionesPorDia: map['sesionesPorDia'],
      completada: map['completada'] == 1,
      uid: map['uid'],
    );
  }
}