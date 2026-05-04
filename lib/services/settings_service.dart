// lib/services/settings_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();
  factory SettingsService() => instance;

  // ── Límites y defaults ───────────────────────────────────────────────────
  static const int defaultPomodoroDuration = 25;
  static const int defaultBreakDuration = 5;
  static const int minPomodoroDuration = 5;
  static const int maxPomodoroDuration = 90;
  static const int minBreakDuration = 1;
  static const int maxBreakDuration = 30;

  static const String _kPomodoro = 'zt_pomodoro_duration';
  static const String _kBreak = 'zt_break_duration';

  // ── State reactivo ───────────────────────────────────────────────────────
  final ValueNotifier<int> pomodoroDuration =
      ValueNotifier<int>(defaultPomodoroDuration);
  final ValueNotifier<int> breakDuration =
      ValueNotifier<int>(defaultBreakDuration);

  bool _initialized = false;

  static Future<void> init() => instance._init();

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final savedPomodoro = prefs.getInt(_kPomodoro);
    final savedBreak = prefs.getInt(_kBreak);
    // Solo actualiza (y dispara listeners) si el valor guardado difiere del default
    if (savedPomodoro != null) pomodoroDuration.value = savedPomodoro;
    if (savedBreak != null) breakDuration.value = savedBreak;
  }

  Future<void> setPomodoroDuration(int minutes) async {
    final clamped =
        minutes.clamp(minPomodoroDuration, maxPomodoroDuration);
    pomodoroDuration.value = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPomodoro, clamped);
    // TODO: sincronizar con Firestore cuando haya auth:
    // await userDoc.update({'pomodoroMinutes': clamped});
  }

  Future<void> setBreakDuration(int minutes) async {
    final clamped = minutes.clamp(minBreakDuration, maxBreakDuration);
    breakDuration.value = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBreak, clamped);
  }
}
