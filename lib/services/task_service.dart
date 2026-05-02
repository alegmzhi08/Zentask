// lib/services/task_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tarea.dart';

class TaskService {
  TaskService._();
  static final TaskService instance = TaskService._();
  factory TaskService() => instance;

  static const String _kTareas = 'zt_tareas';

  final ValueNotifier<List<Tarea>> tareas = ValueNotifier([]);

  bool _initialized = false;

  // ── Inicialización ───────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    _load(prefs);
  }

  void _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kTareas);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      tareas.value = list
          .map((e) => Tarea.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      tareas.value = [];
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addTarea(Tarea tarea) async {
    tareas.value = [...tareas.value, tarea];
    await _persist();
  }

  Future<void> updateTarea(Tarea updated) async {
    tareas.value = tareas.value
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
    await _persist();
  }

  Future<void> deleteTarea(String id) async {
    tareas.value = tareas.value.where((t) => t.id != id).toList();
    await _persist();
  }

  // ── Completar en una fecha específica ─────────────────────────────────────

  /// Añade [date] a `completedDates` de la tarea [tareaId].
  /// Para tareas recurrentes esto preserva los días futuros intactos.
  /// Idempotente: si ya está completada ese día, no hace nada.
  Future<void> completarEnFecha(String tareaId, DateTime date) async {
    final idx = tareas.value.indexWhere((t) => t.id == tareaId);
    if (idx == -1) return;
    final tarea = tareas.value[idx];
    final day = DateTime(date.year, date.month, date.day);
    if (tarea.isCompletedOn(day)) return;
    await updateTarea(
      tarea.copyWith(completedDates: [...tarea.completedDates, day]),
    );
  }

  // ── Consulta por fecha ────────────────────────────────────────────────────

  /// Devuelve las tareas que aplican para [date] usando rango + días de trabajo.
  List<Tarea> getTasksForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);

    return tareas.value.where((tarea) {
      final startDate = tarea.startDate;
      final endDate = tarea.endDate;

      if (startDate == null || endDate == null) return false;

      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);

      final isInDateRange = !day.isBefore(startDay) && !day.isAfter(endDay);
      if (!isInDateRange) return false;

      return tarea.workingDays.contains(day.weekday);
    }).toList();
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kTareas,
      jsonEncode(tareas.value.map((t) => t.toMap()).toList()),
    );
  }

  @visibleForTesting
  void debugReset() {
    _initialized = false;
    tareas.value = [];
  }
}
