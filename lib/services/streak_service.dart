// lib/services/streak_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona las rachas diarias de actividad del usuario.
/// Persiste en SharedPreferences para sobrevivir reinicios de la app.
class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();
  factory StreakService() => instance;

  static const String _kCount = 'zt_streak_count';
  static const String _kDate = 'zt_last_activity';
  static const int umbralMultiplicador = 5;

  final ValueNotifier<int> streak = ValueNotifier(0);
  bool _initialized = false;

  /// Devuelve 2 si la racha alcanzó el umbral, 1 en caso contrario.
  int get multiplier => streak.value >= umbralMultiplicador ? 2 : 1;

  bool get estaActiva => streak.value > 0;

  /// Carga el estado persistido. Idempotente — llámala en initState de cada screen.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getInt(_kCount) ?? 0;
    final ultimaFechaStr = prefs.getString(_kDate);

    if (ultimaFechaStr == null) {
      streak.value = 0;
      return;
    }

    final ultimaFecha = DateTime.parse(ultimaFechaStr);
    final hoy = _soloFecha(DateTime.now());
    final diferencia = hoy.difference(_soloFecha(ultimaFecha)).inDays;

    if (diferencia <= 1) {
      // Racha vigente: última actividad fue hoy o ayer
      streak.value = guardado;
    } else {
      // Racha rota — limpiar para que el siguiente registro empiece en 1
      streak.value = 0;
      await prefs.remove(_kCount);
      await prefs.remove(_kDate);
    }
  }

  /// Registra actividad del día actual y recalcula la racha.
  /// Llamar cada vez que el usuario complete una tarea.
  Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = _soloFecha(DateTime.now());
    final ultimaFechaStr = prefs.getString(_kDate);

    int nuevaRacha;

    if (ultimaFechaStr == null) {
      // Primera vez
      nuevaRacha = 1;
    } else {
      final ultimaFecha = _soloFecha(DateTime.parse(ultimaFechaStr));
      final diferencia = hoy.difference(ultimaFecha).inDays;

      if (diferencia == 0) {
        // Ya se registró actividad hoy — no cambiar
        return;
      } else if (diferencia == 1) {
        // Ayer completó una tarea → incrementar
        nuevaRacha = (prefs.getInt(_kCount) ?? 0) + 1;
      } else {
        // Gap de 2+ días → reiniciar
        nuevaRacha = 1;
      }
    }

    streak.value = nuevaRacha;
    await prefs.setInt(_kCount, nuevaRacha);
    await prefs.setString(_kDate, hoy.toIso8601String().substring(0, 10));
    // TODO: sincronizar con Firestore:
    // await FirebaseFirestore.instance
    //   .collection('usuarios').doc(uid)
    //   .update({'racha': nuevaRacha, 'ultimaActividad': Timestamp.fromDate(hoy)});
  }

  /// Normaliza un DateTime a medianoche para comparar solo la fecha.
  DateTime _soloFecha(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
