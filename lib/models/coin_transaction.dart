// lib/models/coin_transaction.dart

/// Tipos válidos: 'task' | 'pomodoro' | 'dailyQuest' | 'spend'
class CoinTransaction {
  final String id;
  final int amount; // positivo = ingreso, negativo = gasto
  final String type;
  final DateTime timestamp;
  final String description;

  const CoinTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
      };

  factory CoinTransaction.fromMap(Map<String, dynamic> m) => CoinTransaction(
        id: m['id'] as String,
        amount: m['amount'] as int,
        type: m['type'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        description: m['description'] as String,
      );
}
