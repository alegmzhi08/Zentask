import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) {
    return DailyQuestState(
      dateKey: dateKey ?? this.dateKey,
      completedTasksToday: completedTasksToday ?? this.completedTasksToday,
      focusMinutesToday: focusMinutesToday ?? this.focusMinutesToday,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }
}

/// Singleton que gestiona el saldo de ZenCoins.
/// Accede desde cualquier widget con EconomyService.instance.
class EconomyService {
  EconomyService._internal();
  static final EconomyService instance = EconomyService._internal();
  factory EconomyService() => instance;

  static const int coinsPerTask = 50;
  static const int coinsPerFocusMinute = 1;
  static const int dailyQuestReward = 75;
  static const int dailyQuestTaskGoal = 2;
  static const int dailyQuestFocusGoalMinutes = 25;

  static const int porSesionPomodoro = dailyQuestFocusGoalMinutes;
  static const int porTareaCompletada = coinsPerTask;

  static const String _kZenCoins = 'zenCoins';
  static const String _kDailyQuestDateKey = 'dailyQuestDateKey';
  static const String _kDailyQuestCompletedTasks = 'dailyQuestCompletedTasks';
  static const String _kDailyQuestFocusMinutes = 'dailyQuestFocusMinutes';
  static const String _kDailyQuestClaimedDateKey = 'dailyQuestClaimedDateKey';

  /// Fuente de verdad reactiva — envuelve con ValueListenableBuilder en la UI.
  final ValueNotifier<int> balance = ValueNotifier<int>(0);

  final ValueNotifier<DailyQuestState> dailyQuest =
      ValueNotifier<DailyQuestState>(
        DailyQuestState(
          dateKey: _dateKeyFor(DateTime.now()),
          completedTasksToday: 0,
          focusMinutesToday: 0,
          rewardClaimed: false,
        ),
      );

  SharedPreferences? _prefs;
  bool _initialized = false;
  DateTime Function() _now = DateTime.now;

  static Future<void> init() => instance._init();

  Future<void> _init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _initialized = true;

    balance.value = prefs.getInt(_kZenCoins) ?? 0;
    await _loadDailyQuestForToday(prefs);
  }

  Future<void> earnFromPomodoro() => rewardFocusMinutes(porSesionPomodoro);

  /// [multiplier] viene de StreakService.instance.multiplier (1 o 2).
  Future<void> earnFromTask({int multiplier = 1}) =>
      rewardTaskCompletion(multiplier: multiplier);

  Future<void> rewardTaskCompletion({int multiplier = 1}) async {
    final prefs = await _prepareForDailyWrite();
    final safeMultiplier = multiplier < 1 ? 1 : multiplier;
    final quest = dailyQuest.value;

    balance.value += coinsPerTask * safeMultiplier;
    dailyQuest.value = quest.copyWith(
      completedTasksToday: quest.completedTasksToday + 1,
    );

    await Future.wait([
      prefs.setInt(_kZenCoins, balance.value),
      prefs.setInt(
        _kDailyQuestCompletedTasks,
        dailyQuest.value.completedTasksToday,
      ),
    ]);
  }

  Future<void> rewardFocusMinutes(int minutes) async {
    if (minutes <= 0) return;

    final prefs = await _prepareForDailyWrite();
    final quest = dailyQuest.value;

    balance.value += minutes * coinsPerFocusMinute;
    dailyQuest.value = quest.copyWith(
      focusMinutesToday: quest.focusMinutesToday + minutes,
    );

    await Future.wait([
      prefs.setInt(_kZenCoins, balance.value),
      prefs.setInt(
        _kDailyQuestFocusMinutes,
        dailyQuest.value.focusMinutesToday,
      ),
    ]);
  }

  Future<bool> claimDailyQuestReward() async {
    final prefs = await _prepareForDailyWrite();
    final quest = dailyQuest.value;

    if (!quest.isReadyToClaim || quest.rewardClaimed) return false;

    balance.value += dailyQuestReward;
    dailyQuest.value = quest.copyWith(rewardClaimed: true);

    await Future.wait([
      prefs.setInt(_kZenCoins, balance.value),
      prefs.setString(_kDailyQuestClaimedDateKey, quest.dateKey),
    ]);

    return true;
  }

  /// Descuenta [amount] monedas. Retorna true si había saldo suficiente.
  /// Usa este método desde GaticosScreen al alimentar o interactuar con la mascota.
  bool spendCoins(int amount) {
    if (amount <= 0 || balance.value < amount) return false;
    balance.value -= amount;
    _prefs?.setInt(_kZenCoins, balance.value);
    // TODO: sincronizar con Firestore con FieldValue.increment(-amount)
    return true;
  }

  Future<SharedPreferences> _prepareForDailyWrite() async {
    if (!_initialized) await _init();

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final todayKey = _dateKeyFor(_now());

    if (dailyQuest.value.dateKey != todayKey) {
      await _loadDailyQuestForToday(prefs);
    }

    return prefs;
  }

  Future<void> _loadDailyQuestForToday(SharedPreferences prefs) async {
    final todayKey = _dateKeyFor(_now());
    final storedDateKey = prefs.getString(_kDailyQuestDateKey);
    final claimedDateKey = prefs.getString(_kDailyQuestClaimedDateKey);

    if (storedDateKey == todayKey) {
      dailyQuest.value = DailyQuestState(
        dateKey: todayKey,
        completedTasksToday: prefs.getInt(_kDailyQuestCompletedTasks) ?? 0,
        focusMinutesToday: prefs.getInt(_kDailyQuestFocusMinutes) ?? 0,
        rewardClaimed: claimedDateKey == todayKey,
      );
      return;
    }

    dailyQuest.value = DailyQuestState(
      dateKey: todayKey,
      completedTasksToday: 0,
      focusMinutesToday: 0,
      rewardClaimed: claimedDateKey == todayKey,
    );

    await Future.wait([
      prefs.setString(_kDailyQuestDateKey, todayKey),
      prefs.setInt(_kDailyQuestCompletedTasks, 0),
      prefs.setInt(_kDailyQuestFocusMinutes, 0),
    ]);
  }

  static String _dateKeyFor(DateTime date) {
    final localDate = date.toLocal();
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @visibleForTesting
  void debugSetNow(DateTime Function() now) {
    _now = now;
  }

  @visibleForTesting
  void debugReset({DateTime Function()? now}) {
    _prefs = null;
    _initialized = false;
    _now = now ?? DateTime.now;
    balance.value = 0;
    dailyQuest.value = DailyQuestState(
      dateKey: _dateKeyFor(_now()),
      completedTasksToday: 0,
      focusMinutesToday: 0,
      rewardClaimed: false,
    );
  }
}
