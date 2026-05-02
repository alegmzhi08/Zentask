import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/tarea.dart';
import 'package:zentask/services/task_service.dart';

void main() {
  setUp(() {
    TaskService.instance.debugReset();
  });

  test('getTasksForDate muestra tareas dentro del rango y workingDays', () {
    final tarea = Tarea(
      id: 'range-task',
      nombre: 'Estudiar cálculo',
      materia: 'Cálculo III',
      fechaEntrega: DateTime(2026, 5, 10),
      diasTrabajo: const [],
      tiempoSesion: 25,
      sesionesPorDia: 1,
      startDate: DateTime(2026, 5, 4),
      endDate: DateTime(2026, 5, 10),
      workingDays: const [DateTime.monday, DateTime.wednesday],
    );

    TaskService.instance.tareas.value = [tarea];

    expect(
      TaskService.instance.getTasksForDate(DateTime(2026, 5, 4)),
      contains(tarea),
    );
    expect(
      TaskService.instance.getTasksForDate(DateTime(2026, 5, 6)),
      contains(tarea),
    );
    expect(TaskService.instance.getTasksForDate(DateTime(2026, 5, 5)), isEmpty);
    expect(
      TaskService.instance.getTasksForDate(DateTime(2026, 5, 11)),
      isEmpty,
    );
  });

  test('getTasksForDate no muestra tareas sin startDate', () {
    final tarea = Tarea(
      id: 'undated-task',
      nombre: 'Leer',
      materia: 'Historia',
      fechaEntrega: DateTime(2026, 5, 10),
      diasTrabajo: const ['Lu'],
      tiempoSesion: 25,
      sesionesPorDia: 1,
    );

    TaskService.instance.tareas.value = [tarea];

    expect(TaskService.instance.getTasksForDate(DateTime(2026, 5, 4)), isEmpty);
  });
}
