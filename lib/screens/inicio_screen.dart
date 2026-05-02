// lib/screens/inicio_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../services/economy_service.dart';
import '../services/streak_service.dart';
import '../widgets/streak_fire.dart';
import '../widgets/zencoins_badge.dart';
import '../widgets/zencoins_reward.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // ── Timer Pomodoro ────────────────────────────────────────────────────────
  static const int _trabajoSeg = 25 * 60;
  static const int _descansoCortaSeg = 5 * 60;
  static const int _descansoLargoSeg = 15 * 60;
  static const Color _colorTrabajo = Color(0xFF8DC49A);

  Timer? _timer;
  int _segundosRestantes = _trabajoSeg;
  bool _corriendo = false;
  bool _esTrabajo = true;
  int _pomodorosEnCiclo = 0;

  int get _duracionTotal => _esTrabajo
      ? _trabajoSeg
      : (_pomodorosEnCiclo == 0 ? _descansoLargoSeg : _descansoCortaSeg);

  // ── Tareas de hoy ─────────────────────────────────────────────────────────
  // TODO: reemplazar con StreamBuilder que escuche Firestore
  final List<Tarea> _tareasHoy = [
    Tarea(
      id: 'demo_1',
      nombre: 'Leer capítulo 5',
      materia: 'Cálculo III',
      fechaEntrega: DateTime.now(),
      diasTrabajo: ['Lu', 'Mi'],
      tiempoSesion: 25,
      sesionesPorDia: 2,
    ),
    Tarea(
      id: 'demo_2',
      nombre: 'Resolver ejercicios',
      materia: 'Estadística',
      fechaEntrega: DateTime.now(),
      diasTrabajo: ['Ma', 'Ju'],
      tiempoSesion: 25,
      sesionesPorDia: 1,
    ),
    Tarea(
      id: 'demo_3',
      nombre: 'Ensayo de introducción',
      materia: 'Español',
      fechaEntrega: DateTime.now(),
      diasTrabajo: ['Vi'],
      tiempoSesion: 30,
      sesionesPorDia: 1,
    ),
  ];

  // ── Métodos del timer ─────────────────────────────────────────────────────
  void _iniciarPausar() {
    if (_corriendo) {
      _timer?.cancel();
      setState(() => _corriendo = false);
      return;
    }
    setState(() => _corriendo = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes <= 1) {
        _alTerminar();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  void _reiniciar() {
    _timer?.cancel();
    setState(() {
      _corriendo = false;
      _segundosRestantes = _duracionTotal;
    });
  }

  Future<void> _alTerminar() async {
    _timer?.cancel();
    final bool eraTrabajoAntes = _esTrabajo;
    setState(() {
      _corriendo = false;
      if (_esTrabajo) {
        _pomodorosEnCiclo = (_pomodorosEnCiclo + 1) % 4;
        _esTrabajo = false;
      } else {
        _esTrabajo = true;
      }
      _segundosRestantes = _duracionTotal;
    });

    // Recompensa solo al completar una sesión de trabajo
    if (eraTrabajoAntes && mounted) {
      await EconomyService.instance.rewardFocusMinutes(
        EconomyService.porSesionPomodoro,
      );
      if (!mounted) return;
      ZenCoinsReward.show(context, EconomyService.porSesionPomodoro);
    }

    final mensaje = _esTrabajo ? '¡A trabajar! 💪' : '¡Tómate un descanso! ☕';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), duration: const Duration(seconds: 3)),
      );
    }
  }

  // ── Métodos de tareas ─────────────────────────────────────────────────────
  Future<void> _completarTarea(int index) async {
    if (_tareasHoy[index].completada) return;
    setState(() => _tareasHoy[index].completada = true);
    // La racha se actualiza primero para que el multiplicador esté vigente
    await StreakService.instance.recordActivity();
    if (!mounted) return;
    final mul = StreakService.instance.multiplier;
    await EconomyService.instance.rewardTaskCompletion(multiplier: mul);
    if (!mounted) return;
    ZenCoinsReward.show(context, EconomyService.porTareaCompletada * mul);
    // TODO: actualizar Firestore:
    // FirebaseFirestore.instance.collection('tareas').doc(tarea.id)
    //   .update({'completada': true});
  }

  Future<void> _claimDailyQuest() async {
    final claimed = await EconomyService.instance.claimDailyQuestReward();
    if (!mounted || !claimed) return;

    ZenCoinsReward.show(context, EconomyService.dailyQuestReward);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily Zen Quest completada: +75 ZenCoins'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    StreakService.instance.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _tiempoFormateado {
    final min = _segundosRestantes ~/ 60;
    final seg = _segundosRestantes % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  Color get _colorModo => _esTrabajo ? _colorTrabajo : Colors.amber.shade600;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Zentask Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          const StreakFire(),
          const SizedBox(width: 6),
          const ZenCoinsBadge(),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Perfil
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF8DC49A),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Usuario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Test Zentask #1',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),

            // ── Timer Pomodoro
            _buildTimerSection(),
            const SizedBox(height: 16),
            _buildDailyQuestSection(),
            const SizedBox(height: 28),

            // ── Estadísticas
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  'Pending Tasks',
                  '0',
                  'Last 7 days',
                  Colors.amber.shade700,
                ),
                _buildStatCard(
                  'Overdue Tasks',
                  '5',
                  'Total',
                  Colors.red.shade400,
                ),
                _buildStatCard(
                  'Tasks Completed',
                  '0',
                  'Last 7 days',
                  Colors.green.shade600,
                ),
                _buildStatCard(
                  'Your Streak',
                  '0',
                  'Total streak',
                  Colors.orange.shade600,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Tareas de hoy
            _buildTareasHoySection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Daily Zen Quest ───────────────────────────────────────────────────────
  Widget _buildDailyQuestSection() {
    return ValueListenableBuilder<DailyQuestState>(
      valueListenable: EconomyService.instance.dailyQuest,
      builder: (context, quest, _) {
        final taskProgress =
            (quest.completedTasksToday / EconomyService.dailyQuestTaskGoal)
                .clamp(0.0, 1.0)
                .toDouble();
        final focusProgress =
            (quest.focusMinutesToday /
                    EconomyService.dailyQuestFocusGoalMinutes)
                .clamp(0.0, 1.0)
                .toDouble();
        final canClaim = quest.isReadyToClaim && !quest.rewardClaimed;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD6E8D8), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8DC49A).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: Color(0xFF8DC49A),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Daily Zen Quest',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3A4A3E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4CC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '+75 ZenCoins',
                      style: TextStyle(
                        color: Color(0xFF8A5A00),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildQuestProgressRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Tareas',
                value:
                    '${quest.completedTasksToday}/${EconomyService.dailyQuestTaskGoal}',
                progress: taskProgress,
                color: const Color(0xFF8DC49A),
              ),
              const SizedBox(height: 12),
              _buildQuestProgressRow(
                icon: Icons.timer_outlined,
                label: 'Foco',
                value:
                    '${quest.focusMinutesToday}/${EconomyService.dailyQuestFocusGoalMinutes} min',
                progress: focusProgress,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canClaim ? _claimDailyQuest : null,
                  icon: Icon(
                    quest.rewardClaimed
                        ? Icons.check_rounded
                        : Icons.savings_outlined,
                    size: 19,
                  ),
                  label: Text(
                    quest.rewardClaimed
                        ? 'Reclamado por hoy'
                        : canClaim
                        ? 'Reclamar +75'
                        : 'Completa una meta',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8DC49A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEAF4EB),
                    disabledForegroundColor: const Color(0xFF7D9882),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestProgressRow({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF3A4A3E),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF7D9882),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFEAF4EB),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sección de tareas ─────────────────────────────────────────────────────
  Widget _buildTareasHoySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'TAREAS DE HOY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF7D9882),
            ),
          ),
        ),
        if (_tareasHoy.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '¡Sin tareas por hoy! 🎉',
                style: TextStyle(color: Color(0xFF7D9882)),
              ),
            ),
          )
        else
          ..._tareasHoy.asMap().entries.map((entry) {
            final i = entry.key;
            final tarea = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _completarTarea(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: tarea.completada
                        ? const Color(0xFFEAF4EB)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tarea.completada
                          ? const Color(0xFF8DC49A)
                          : const Color(0xFFE8E8E8),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Checkbox circular animado
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tarea.completada
                              ? const Color(0xFF8DC49A)
                              : Colors.transparent,
                          border: Border.all(
                            color: tarea.completada
                                ? const Color(0xFF8DC49A)
                                : const Color(0xFFD6E8D8),
                            width: 2,
                          ),
                        ),
                        child: tarea.completada
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tarea.completada
                                    ? const Color(0xFF7D9882)
                                    : const Color(0xFF3A4A3E),
                                decoration: tarea.completada
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: const Color(0xFF7D9882),
                              ),
                              child: Text(tarea.nombre),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tarea.materia,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7D9882),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: tarea.completada
                            ? const Text(
                                '🐟',
                                key: ValueKey('done'),
                                style: TextStyle(fontSize: 18),
                              )
                            : const Icon(
                                Icons.chevron_right,
                                key: ValueKey('pending'),
                                color: Color(0xFFD6E8D8),
                                size: 20,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Sección del timer ─────────────────────────────────────────────────────
  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6E8D8), width: 1.5),
      ),
      child: Column(
        children: [
          // Chip de modo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _colorModo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _esTrabajo
                  ? 'Trabajo'
                  : (_pomodorosEnCiclo == 0 ? 'Descanso largo' : 'Descanso'),
              style: TextStyle(
                color: _colorModo,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Círculo del timer
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: _segundosRestantes / _duracionTotal,
                    strokeWidth: 9,
                    backgroundColor: const Color(0xFFD6E8D8),
                    valueColor: AlwaysStoppedAnimation<Color>(_colorModo),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  _tiempoFormateado,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A4A3E),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _reiniciar,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 28,
                color: const Color(0xFF7D9882),
                tooltip: 'Reiniciar',
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _iniciarPausar,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _colorModo,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _colorModo.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _corriendo ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 20),

          // Dots del ciclo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final completado = i < _pomodorosEnCiclo;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: completado ? 10 : 8,
                  height: completado ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completado ? _colorTrabajo : const Color(0xFFD6E8D8),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Stat card ─────────────────────────────────────────────────────────────
  Widget _buildStatCard(
    String title,
    String count,
    String subtitle,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
