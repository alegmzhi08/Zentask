// lib/models/economy_stats.dart

class EconomyStats {
  final int totalTasksCompleted;
  final int totalFocusMinutes;
  final int totalCoinsEarned;
  final int totalCoinsSpent;
  final int dailyQuestsCompleted;

  const EconomyStats({
    required this.totalTasksCompleted,
    required this.totalFocusMinutes,
    required this.totalCoinsEarned,
    required this.totalCoinsSpent,
    required this.dailyQuestsCompleted,
  });

  static const EconomyStats empty = EconomyStats(
    totalTasksCompleted: 0,
    totalFocusMinutes: 0,
    totalCoinsEarned: 0,
    totalCoinsSpent: 0,
    dailyQuestsCompleted: 0,
  );
}
