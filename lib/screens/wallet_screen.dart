// lib/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import '../models/coin_transaction.dart';
import '../services/economy_service.dart';
import '../services/streak_service.dart';

// ─────────────────────────────────────────────────────────────────────────────

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF5),
      appBar: AppBar(
        title: const Text('Billetera',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4FBF5),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF3A4A3E),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BalanceHeader(),
            SizedBox(height: 16),
            _StreakCard(),
            SizedBox(height: 12),
            _DailyQuestCard(),
            SizedBox(height: 12),
            _StatsGrid(),
            SizedBox(height: 20),
            _TransactionHistory(),
          ],
        ),
      ),
    );
  }
}

// ── Balance Header ────────────────────────────────────────────────────────────

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: EconomyService.instance.balance,
      builder: (ctx, saldo, _) {
        return GestureDetector(
          onLongPress: () => _confirmarReset(ctx),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8DC49A), Color(0xFF5A9E6C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8DC49A).withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🐟', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _formatearNumero(saldo),
                    key: ValueKey(saldo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Z E N C O I N S',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmarReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetear economía'),
        content: const Text(
            '¿Borrar todas las monedas, estadísticas y transacciones? Esta acción es irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              EconomyService.instance.resetAllEconomyData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }
}

// ── Streak Card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StreakService.instance.streak,
      builder: (_, racha, _) {
        final x2Activo = racha >= StreakService.umbralMultiplicador;
        return _Card(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: x2Activo
                      ? const Color(0xFFFFF3CD)
                      : const Color(0xFFFFECE0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('🔥',
                      style: TextStyle(fontSize: x2Activo ? 24 : 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$racha día${racha == 1 ? '' : 's'} consecutivo${racha == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A4A3E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      racha == 0
                          ? 'Completa una tarea para iniciar tu racha'
                          : '¡No rompas la racha!',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7D9882)),
                    ),
                  ],
                ),
              ),
              if (x2Activo)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    '×2',
                    style: TextStyle(
                      color: Color(0xFF7A4000),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Daily Quest Card ──────────────────────────────────────────────────────────

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DailyQuestState>(
      valueListenable: EconomyService.instance.dailyQuest,
      builder: (ctx, quest, _) {
        final taskPct =
            (quest.completedTasksToday / EconomyService.dailyQuestTaskGoal)
                .clamp(0.0, 1.0);
        final focusPct =
            (quest.focusMinutesToday / EconomyService.dailyQuestFocusGoalMinutes)
                .clamp(0.0, 1.0);

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Daily Zen Quest',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A4A3E),
                      ),
                    ),
                  ),
                  if (quest.rewardClaimed)
                    const Text('✅', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 14),
              _ProgressRow(
                label: 'Tareas',
                actual: quest.completedTasksToday,
                meta: EconomyService.dailyQuestTaskGoal,
                progreso: taskPct,
                icono: Icons.check_circle_outline,
              ),
              const SizedBox(height: 10),
              _ProgressRow(
                label: 'Minutos de foco',
                actual: quest.focusMinutesToday,
                meta: EconomyService.dailyQuestFocusGoalMinutes,
                progreso: focusPct,
                icono: Icons.timer_outlined,
                unidad: 'min',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      quest.isReadyToClaim ? () => _reclamar(ctx) : null,
                  icon: const Text('🐟', style: TextStyle(fontSize: 16)),
                  label: Text(
                    quest.rewardClaimed
                        ? 'Ya reclamaste hoy'
                        : 'Reclamar  +${EconomyService.dailyQuestReward} ZenCoins',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8DC49A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD6E8D8),
                    disabledForegroundColor: const Color(0xFF7D9882),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reclamar(BuildContext context) async {
    final claimed = await EconomyService.instance.claimDailyQuestReward();
    if (!context.mounted || !claimed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Daily Quest reclamada! +75 ZenCoins 🐟'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    // transactions como proxy reactivo: cualquier cambio en stats
    // también agrega una transacción, por lo que este builder siempre está al día
    return ValueListenableBuilder<List<CoinTransaction>>(
      valueListenable: EconomyService.instance.transactions,
      builder: (_, _, _) {
        final s = EconomyService.instance.getStatsSnapshot();
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _StatTile(
              label: 'Tareas totales',
              valor: s.totalTasksCompleted,
              icono: Icons.check_circle_outline,
              color: const Color(0xFF8DC49A),
            ),
            _StatTile(
              label: 'Minutos enfocado',
              valor: s.totalFocusMinutes,
              icono: Icons.timer_outlined,
              color: Colors.blue.shade400,
            ),
            _StatTile(
              label: 'Coins ganadas',
              valor: s.totalCoinsEarned,
              icono: Icons.trending_up_rounded,
              color: Colors.green.shade500,
            ),
            _StatTile(
              label: 'Coins gastadas',
              valor: s.totalCoinsSpent,
              icono: Icons.trending_down_rounded,
              color: Colors.red.shade400,
            ),
          ],
        );
      },
    );
  }
}

// ── Transaction History ───────────────────────────────────────────────────────

class _TransactionHistory extends StatelessWidget {
  const _TransactionHistory();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CoinTransaction>>(
      valueListenable: EconomyService.instance.transactions,
      builder: (_, txList, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'HISTORIAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFF7D9882),
                ),
              ),
            ),
            if (txList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aún no hay transacciones 🐟',
                    style: TextStyle(color: Color(0xFF7D9882)),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: txList.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 56,
                  color: Color(0xFFEAF4EB),
                ),
                itemBuilder: (_, i) => _TxTile(tx: txList[i]),
              ),
          ],
        );
      },
    );
  }
}

// ── Widgets atómicos ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAF4EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int valor;
  final IconData icono;
  final Color color;

  const _StatTile({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF4EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icono, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7D9882),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            _formatearNumero(valor),
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final CoinTransaction tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final esGasto = tx.amount < 0;
    final color =
        esGasto ? Colors.red.shade400 : const Color(0xFF8DC49A);
    final amountStr = esGasto ? '${tx.amount}' : '+${tx.amount}';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: _fondoPorTipo(tx.type),
        child:
            Text(_emojiPorTipo(tx.type), style: const TextStyle(fontSize: 16)),
      ),
      title: Text(
        tx.description,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A4A3E),
        ),
      ),
      subtitle: Text(
        _tiempoRelativo(tx.timestamp),
        style: const TextStyle(fontSize: 11, color: Color(0xFF7D9882)),
      ),
      trailing: Text(
        amountStr,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int actual;
  final int meta;
  final double progreso;
  final IconData icono;
  final String unidad;

  const _ProgressRow({
    required this.label,
    required this.actual,
    required this.meta,
    required this.progreso,
    required this.icono,
    this.unidad = '',
  });

  @override
  Widget build(BuildContext context) {
    final completado = actual >= meta;
    return Row(
      children: [
        Icon(icono, size: 14, color: const Color(0xFF7D9882)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7D9882))),
                  Text(
                    '$actual/$meta${unidad.isNotEmpty ? ' $unidad' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: completado
                          ? const Color(0xFF8DC49A)
                          : const Color(0xFF3A4A3E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFD6E8D8),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF8DC49A)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatearNumero(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return k == k.truncateToDouble()
        ? '${k.toInt()}k'
        : '${k.toStringAsFixed(1)}k';
  }
  return '${(n / 1000000).toStringAsFixed(1)}M';
}

String _tiempoRelativo(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inSeconds < 60) return 'Hace un momento';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  return 'Hace ${diff.inDays} días';
}

String _emojiPorTipo(String type) => switch (type) {
      'task' => '✅',
      'pomodoro' => '⏱',
      'dailyQuest' => '⚡',
      'spend' => '🐾',
      _ => '💫',
    };

Color _fondoPorTipo(String type) => switch (type) {
      'task' => const Color(0xFFEAF4EB),
      'pomodoro' => const Color(0xFFE3F2FD),
      'dailyQuest' => const Color(0xFFFFF9C4),
      'spend' => const Color(0xFFFFEBEE),
      _ => const Color(0xFFF5F5F5),
    };
