import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentask/services/economy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 5, 2, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    EconomyService.instance.debugReset(now: () => today);
    await EconomyService.init();
  });

  test('completar una tarea suma monedas y progreso diario', () async {
    await EconomyService.instance.rewardTaskCompletion();

    expect(EconomyService.instance.balance.value, EconomyService.coinsPerTask);
    expect(EconomyService.instance.dailyQuest.value.completedTasksToday, 1);
    expect(EconomyService.instance.dailyQuest.value.focusMinutesToday, 0);
  });

  test('25 minutos de foco dejan la quest lista para reclamar', () async {
    await EconomyService.instance.rewardFocusMinutes(25);

    expect(EconomyService.instance.balance.value, 25);
    expect(EconomyService.instance.dailyQuest.value.focusMinutesToday, 25);
    expect(EconomyService.instance.dailyQuest.value.isReadyToClaim, isTrue);
  });

  test('dos tareas completadas dejan la quest lista para reclamar', () async {
    await EconomyService.instance.rewardTaskCompletion();
    await EconomyService.instance.rewardTaskCompletion();

    expect(EconomyService.instance.dailyQuest.value.completedTasksToday, 2);
    expect(EconomyService.instance.dailyQuest.value.isReadyToClaim, isTrue);
  });

  test('reclamar la quest suma exactamente el bono diario', () async {
    await EconomyService.instance.rewardFocusMinutes(25);
    final beforeClaim = EconomyService.instance.balance.value;

    final claimed = await EconomyService.instance.claimDailyQuestReward();

    expect(claimed, isTrue);
    expect(
      EconomyService.instance.balance.value - beforeClaim,
      EconomyService.dailyQuestReward,
    );
    expect(EconomyService.instance.dailyQuest.value.rewardClaimed, isTrue);
  });

  test('no permite reclamar dos veces el mismo dia', () async {
    await EconomyService.instance.rewardTaskCompletion();
    await EconomyService.instance.rewardTaskCompletion();

    final firstClaim = await EconomyService.instance.claimDailyQuestReward();
    final balanceAfterFirstClaim = EconomyService.instance.balance.value;
    final secondClaim = await EconomyService.instance.claimDailyQuestReward();

    expect(firstClaim, isTrue);
    expect(secondClaim, isFalse);
    expect(EconomyService.instance.balance.value, balanceAfterFirstClaim);
  });

  test('al cambiar de dia se reinician los contadores diarios', () async {
    await EconomyService.instance.rewardTaskCompletion();

    EconomyService.instance.debugSetNow(() => DateTime(2026, 5, 3, 9));
    await EconomyService.instance.rewardFocusMinutes(1);

    final quest = EconomyService.instance.dailyQuest.value;
    expect(quest.dateKey, '2026-05-03');
    expect(quest.completedTasksToday, 0);
    expect(quest.focusMinutesToday, 1);
    expect(quest.rewardClaimed, isFalse);
  });

  test('minutos cero o negativos no suman monedas ni progreso', () async {
    await EconomyService.instance.rewardFocusMinutes(0);
    await EconomyService.instance.rewardFocusMinutes(-5);

    expect(EconomyService.instance.balance.value, 0);
    expect(EconomyService.instance.dailyQuest.value.focusMinutesToday, 0);
  });
}
