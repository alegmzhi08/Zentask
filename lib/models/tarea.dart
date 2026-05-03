// lib/models/tarea.dart

class Tarea {
  final String id;
  final String nombre;
  final String materia;
  final DateTime fechaEntrega;
  final List<String> diasTrabajo;
  final int tiempoSesion;
  final int sesionesPorDia;
  bool completada; // legado — usado en InicioScreen con setState directo

  // ── Campos del sistema de calendario ─────────────────────────────────────
  // Fecha (+ hora opcional) asignada al calendario.
  final DateTime? scheduledDate;
  final String recurrence; // 'none' | 'daily' | 'weekly'
  final List<DateTime> completedDates; // días en que fue marcada como hecha
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> workingDays;

  Tarea({
    required this.id,
    required this.nombre,
    required this.materia,
    required this.fechaEntrega,
    required this.diasTrabajo,
    required this.tiempoSesion,
    required this.sesionesPorDia,
    this.completada = false,
    this.scheduledDate,
    this.recurrence = 'none',
    this.completedDates = const [],
    DateTime? startDate,
    DateTime? endDate,
    List<int>? workingDays,
  }) : startDate = startDate ?? scheduledDate,
       endDate = endDate ?? fechaEntrega,
       workingDays = workingDays ?? _diasTrabajoToWeekdays(diasTrabajo);

  /// Verdadero si esta tarea fue completada en el día exacto de [date].
  bool isCompletedOn(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return completedDates.any(
      (cd) => cd.year == d.year && cd.month == d.month && cd.day == d.day,
    );
  }

  Tarea copyWith({
    String? id,
    String? nombre,
    String? materia,
    DateTime? fechaEntrega,
    List<String>? diasTrabajo,
    int? tiempoSesion,
    int? sesionesPorDia,
    bool? completada,
    DateTime? scheduledDate,
    String? recurrence,
    List<DateTime>? completedDates,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? workingDays,
  }) => Tarea(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    materia: materia ?? this.materia,
    fechaEntrega: fechaEntrega ?? this.fechaEntrega,
    diasTrabajo: diasTrabajo ?? this.diasTrabajo,
    tiempoSesion: tiempoSesion ?? this.tiempoSesion,
    sesionesPorDia: sesionesPorDia ?? this.sesionesPorDia,
    completada: completada ?? this.completada,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    recurrence: recurrence ?? this.recurrence,
    completedDates: completedDates ?? this.completedDates,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    workingDays: workingDays ?? this.workingDays,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'materia': materia,
    'fechaEntrega': fechaEntrega.toIso8601String(),
    'diasTrabajo': diasTrabajo,
    'tiempoSesion': tiempoSesion,
    'sesionesPorDia': sesionesPorDia,
    'completada': completada,
    'scheduledDate': scheduledDate?.toIso8601String(),
    'recurrence': recurrence,
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'workingDays': workingDays,
  };

  factory Tarea.fromMap(Map<String, dynamic> map) => Tarea(
    id: map['id'] as String,
    nombre: map['nombre'] as String,
    materia: map['materia'] as String,
    fechaEntrega: DateTime.parse(map['fechaEntrega'] as String),
    diasTrabajo: List<String>.from(map['diasTrabajo'] as List),
    tiempoSesion: map['tiempoSesion'] as int,
    sesionesPorDia: map['sesionesPorDia'] as int,
    completada: (map['completada'] as bool?) ?? false,
    scheduledDate: map['scheduledDate'] != null
        ? DateTime.parse(map['scheduledDate'] as String)
        : null,
    recurrence: (map['recurrence'] as String?) ?? 'none',
    completedDates: map['completedDates'] != null
        ? (map['completedDates'] as List)
              .map((d) => DateTime.parse(d as String))
              .toList()
        : [],
    startDate: map['startDate'] != null
        ? DateTime.parse(map['startDate'] as String)
        : null,
    endDate: map['endDate'] != null
        ? DateTime.parse(map['endDate'] as String)
        : null,
    workingDays: map['workingDays'] != null
        ? List<int>.from(map['workingDays'] as List)
        : null,
  );

  static List<int> _diasTrabajoToWeekdays(List<String> dias) {
    const byLabel = {
      'Lu': DateTime.monday,
      'Ma': DateTime.tuesday,
      'Mi': DateTime.wednesday,
      'Ju': DateTime.thursday,
      'Vi': DateTime.friday,
      'Sa': DateTime.saturday,
      'Do': DateTime.sunday,
    };

    return dias.map((dia) => byLabel[dia]).whereType<int>().toSet().toList()
      ..sort();
  }
}
