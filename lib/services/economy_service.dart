// lib/services/economy_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_transaction.dart';
import '../models/economy_stats.dart';

// ── DailyQuestState ───────────────────────────────────────────────────────────

class DailyQuestState {
  const DailyQuestState({
    required this.dateKey,
    required this.completedTasksToday,
    required this.focusMinutesToday,
    required this.rewardClaimed,
  });

  final String dateKey;
  final int completedTasksToday;
  final int focusMinutesToday;
  final bool rewardClaimed;

  bool get isReadyToClaim =>
      !rewardClaimed &&
      (completedTasksToday >= EconomyService.dailyQuestTaskGoal ||
          focusMinutesToday >= EconomyService.dailyQuestFocusGoalMinutes);

  DailyQuestState copyWith({
    String? dateKey,
    int? completedTasksToday,
    int? focusMinutesToday,
    bool? rewardClaimed,
  }) =>
      DailyQuestState(
        dateKey: dateKey ?? this.dateKey,
        completedTasksToday: completedTasksToday ?? this.completedTasksToday,
        focusMinutesToday: focusMinutesToday ?? this.focusMinutesToday,
        rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      );
}

// ── EconomyService ────────────────────────────────────────────────────────────

class EconomyService {
  EconomyService._internal();
  static final EconomyService instance = EconomyService._internal();
  factory EconomyService() => instance;

  // ── Constantes de negocio ────────────────────────────────────────────────
  static const int coinsPerTask = 50;
  static const int coinsPerFocusMinute = 1;
  static const int dailyQuestReward = 75;
  static const int dailyQuestTaskGoal = 2;
  static const int dailyQuestFocusGoalMinutes = 25;
  static const int maxTransactions = 100;

  // Aliases para retrocompatibilidad
  static const int porSesionPomodoro = dailyQuestFocusGoalMinutes;
  static const int porTareaCompletada = coinsPerTask;

  // ── Keys SharedPreferences ───────────────────────────────────────────────
  static const _kZenCoins              = 'zenCoins';
  static const _kDailyQuestDateKey     = 'dailyQuestDateKey';
  static const _kDailyQuestTasks       = 'dailyQuestCompletedTasks';
  static const _kDailyQuestFocus       = 'dailyQuestFocusMinutes';
  static const _kDailyQuestClaimed     = 'dailyQuestClaimedDateKey';
  static const _kTransactions          = 'zt_transactions';
  static const _kStatsTasks            = 'zt_stats_tasks';
  static const _kStatsFocusMin         = 'zt_stats_focus_min';
  static const _kStatsCoinsEarned      = 'zt_stats_coins_earned';
  static const _kStatsCoinsSpent       = 'zt_stats_coins_spent';
  static const _kStatsQuests           = 'zt_stats_quests';

  // ── State reactivo ───────────────────────────────────────────────────────
  final ValueNotifier<int> balance = ValueNotifier<int>(0);

  final ValueNotifier<DailyQuestState> dailyQuest =
      ValueNotifier<DailyQuestState>(DailyQuestState(
        dateKey: _dateKeyFor(DateTime.now()),
        completedTasksToday: 0,
        focusMinutesToday: 0,
        rewardClaimed: false,
      ));

  /// Lista de transacciones (más reciente primero, máx. 100).
  final ValueNotifier<List<CoinTransaction>> transactions =
      ValueNotifier<List<CoinTransaction>>([]);

  // ── Acumulados de por vida ────────────────────────────────────────────────
  int _statsTasks = 0;
  int _statsFocusMinutes = 0;
  int _statsCoinsEarned = 0;
  int _statsCoinsSpent = 0;
  int _statsQuests = 0;

  // ── Internos ─────────────────────────────────────────────────────────────
  SharedPreferences? _prefs;
  bool _initialized = false;
  DateTime Function() _now = DateTime.now;

  // ── Inicialización ───────────────────────────────────────────────────────

  static Future<void> init() => instance._init();

  Future<void> _init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _initialized = true;

    balance.value = prefs.getInt(_kZenCoins) ?? 0;
    _loadStats(prefs);
    _loadTransactions(prefs);
    await _loadDailyQuestForToday(prefs);
  }

  void _loadStats(SharedPreferences prefs) {
    _statsTasks        = prefs.getInt(_kStatsTasks)       ?? 0;
    _statsFocusMinutes = prefs.getInt(_kStatsFocusMin)    ?? 0;
    _statsCoinsEarned  = prefs.getInt(_kStatsCoinsEarned) ?? 0;
    _statsCoinsSpent   = prefs.getInt(_kStatsCoinsSpent)  ?? 0;
    _statsQuests       = prefs.getInt(_kStatsQuests)      ?? 0;
  }

  void _loadTransactions(SharedPreferences prefs) {
    final raw = prefs.getString(_kTransactions);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      transactions.value = list
          .map((e) => CoinTransaction.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // dato corrupto → arrancar limpio
      transactions.value = [];
    }
  }

  // ── Recompensas ──────────────────────────────────────────────────────────

  Future<void> earnFromPomodoro() => rewardFocusMinutes(porSesionPomodoro);

  /// [multiplier] viene de StreakService.instance.multiplier (1 o 2).
  Future<void> earnFromTask({int multiplier = 1}) =>
      rewardTaskCompletion(multiplier: multiplier);

  Future<void> rewardTaskCompletion({int multiplier = 1}) async {
    final prefs = await _prepareForDailyWrite();
    final mul = multiplier < 1 ? 1 : multiplier;
    final earned = coinsPerTask * mul;
    final quest = dailyQuest.value;

    balance.value += earned;
    _statsCoinsEarned += earned;
    _statsTasks++;
    dailyQuest.value = quest.copyWith(
      completedTasksToday: quest.completedTasksToday + 1,
    );

    _addTransaction(CoinTransaction(
      id: _newId(),
      amount: earned,
      type: 'task',
      timestamp: _now(),
      description: mul > 1 ? 'Tarea completada (×$mul racha)' : 'Tarea completada',
    ));

    await Future.wait([
      prefs.setInt(_kZenCoins, balance.value),
      prefs.setInt(_kDailyQuestTasks, dailyQuest.value.completedTasksToday),
      prefs.setInt(_kStatsTasks, _statsTasks),
      prefs.setInt(_kStatsCoinsEarned, _statsCoinsEarned),
    ]);
  }

  Future<void> rewardFocusMinutes(int minutes) async {
    if (minutes <= 0) return;
    final prefs = await _prepareForDailyWrite();
    final earned = minutes * coinsPerFocusMinute;
    final quest = dailyQuest.value;

    balance.value += earned;
    _statsCoinsEarned += earned;
    _statsFocusMinutes += minutes;
    dailyQuest.value = quest.copyWith(
      focusMinutesToday: quest.focusMinutesToday + minutes,
    );

    _addTransaction(CoinTransaction(
      id: _newId(),
      amount: earned,
      type: 'pomodoro',
      timestamp: _now(),
      description: 'Sesión Pomodoro ($minutes min)',
    ));

    await Future.wait([
      prefs.setInt(_kZenCoins, balance.value),
      prefs.setInt(_kDailyQuestFocus, dailyQuest.value.focusMinutesToday),
      prefs.setInt(_kStatsCoinsEarned, _statsCoinsEarned),
      prefs.setInt(_kStatsFocusMin, _statsFocusMinutes),
    ]);
  }

  Future<bool> claimDailyQuestReward() async {
    final prefs = await _prepareForDailyWrite();
    final quest = dailyQuest.value;
    if (!quest.isReadyToClaim) return false;

    balance.value += dailyQuestReward;
    _statsCoinsEarned += dailyQuestReward;
    _statsQuests++;
    dailyQuest.value = quest.copyWith(rewardClaimed: true);

    _addTransaction(CoinTransaction(
      id: _newId(),
      amount: dailyQuestReward,
      type: 'dailyQuest',
      timestamp: _now(),
      description: 'Daily Zen Quest completada',
    ));

    await Future.wait([
      prefs.setInt(_kZenCoins, balance.value),
      prefs.setString(_kDailyQuestClaimed, quest.dateKey),
      prefs.setInt(_kStatsCoinsEarned, _statsCoinsEarned),
      prefs.setInt(_kStatsQuests, _statsQuests),
    ]);

    return true;
  }

  /// Descuenta monedas. Retorna false si el saldo es insuficiente.
  /// Úsalo desde GaticosScreen: `await EconomyService.instance.spendCoins(30)`.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || balance.value < amount) return false;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    balance.value -= amount;
    _statsCoinsSpent += amount;

    _addTransaction(CoinTransaction(
      id: _newId(),
      amount: -amount,
      type: 'spend',
      timestamp: _now(),
      description: 'Gaticos — mascota',
    ));

    await Future.wait([
      prefs.setInt(_kZenCoins, balance.value),
      prefs.setInt(_kStatsCoinsSpent, _statsCoinsSpent),
    ]);

    return true;
  }

  // ── Consultas ────────────────────────────────────────────────────────────

  /// Snapshot inmutable de las estadísticas acumuladas de por vida.
  EconomyStats getStatsSnapshot() => EconomyStats(
        totalTasksCompleted: _statsTasks,
        totalFocusMinutes: _statsFocusMinutes,
        totalCoinsEarned: _statsCoinsEarned,
        totalCoinsSpent: _statsCoinsSpent,
        dailyQuestsCompleted: _statsQuests,
      );

  // ── Reset (testing / debug) ───────────────────────────────────────────────

  /// Borra todos los datos de economía. Long-press en WalletScreen.
  Future<void> resetAllEconomyData() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();

    balance.value = 0;
    transactions.value = [];
    _statsTasks = 0;
    _statsFocusMinutes = 0;
    _statsCoinsEarned = 0;
    _statsCoinsSpent = 0;
    _statsQuests = 0;
    dailyQuest.value = DailyQuestState(
      dateKey: _dateKeyFor(_now()),
      completedTasksToday: 0,
      focusMinutesToday: 0,
      rewardClaimed: false,
    );

    await Future.wait([
      prefs.setInt(_kZenCoins, 0),
      prefs.remove(_kTransactions),
      prefs.setInt(_kStatsTasks, 0),
      prefs.setInt(_kStatsFocusMin, 0),
      prefs.setInt(_kStatsCoinsEarned, 0),
      prefs.setInt(_kStatsCoinsSpent, 0),
      prefs.setInt(_kStatsQuests, 0),
      prefs.remove(_kDailyQuestDateKey),
      prefs.remove(_kDailyQuestTasks),
      prefs.remove(_kDailyQuestFocus),
      prefs.remove(_kDailyQuestClaimed),
    ]);
  }

  // ── Privados ─────────────────────────────────────────────────────────────

  Future<SharedPreferences> _prepareForDailyWrite() async {
    if (!_initialized) await _init();
    final prefs = _prefs!;
    if (dailyQuest.value.dateKey != _dateKeyFor(_now())) {
      await _loadDailyQuestForToday(prefs);
    }
    return prefs;
  }

  Future<void> _loadDailyQuestForToday(SharedPreferences prefs) async {
    final todayKey = _dateKeyFor(_now());
    final storedKey = prefs.getString(_kDailyQuestDateKey);
    final claimedKey = prefs.getString(_kDailyQuestClaimed);

    if (storedKey == todayKey) {
      dailyQuest.value = DailyQuestState(
        dateKey: todayKey,
        completedTasksToday: prefs.getInt(_kDailyQuestTasks) ?? 0,
        focusMinutesToday: prefs.getInt(_kDailyQuestFocus) ?? 0,
        rewardClaimed: claimedKey == todayKey,
      );
      return;
    }

    dailyQuest.value = DailyQuestState(
      dateKey: todayKey,
      completedTasksToday: 0,
      focusMinutesToday: 0,
      rewardClaimed: claimedKey == todayKey,
    );
    await Future.wait([
      prefs.setString(_kDailyQuestDateKey, todayKey),
      prefs.setInt(_kDailyQuestTasks, 0),
      prefs.setInt(_kDailyQuestFocus, 0),
    ]);
  }

  /// Inserta al frente y aplica el límite FIFO de [maxTransactions].
  /// Persiste de forma fire-and-forget (no bloquea el caller).
  void _addTransaction(CoinTransaction tx) {
    final updated = [tx, ...transactions.value];
    if (updated.length > maxTransactions) updated.removeLast();
    transactions.value = updated;
    _prefs?.setString(
      _kTransactions,
      jsonEncode(updated.map((t) => t.toMap()).toList()),
    );
  }

  static String _dateKeyFor(DateTime date) {
    final d = date.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _newId() => _now().microsecondsSinceEpoch.toString();

  @visibleForTesting
  void debugSetNow(DateTime Function() now) => _now = now;

  @visibleForTesting
  void debugReset({DateTime Function()? now}) {
    _prefs = null;
    _initialized = false;
    _now = now ?? DateTime.now;
    balance.value = 0;
    transactions.value = [];
    _statsTasks = 0;
    _statsFocusMinutes = 0;
    _statsCoinsEarned = 0;
    _statsCoinsSpent = 0;
    _statsQuests = 0;
    dailyQuest.value = DailyQuestState(
      dateKey: _dateKeyFor(_now()),
      completedTasksToday: 0,
      focusMinutesToday: 0,
      rewardClaimed: false,
    );
  }
}
