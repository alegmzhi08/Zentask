import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/db_service.dart';
import '../services/economy_service.dart';
import '../services/settings_service.dart';
import '../services/streak_service.dart';
import '../widgets/streak_fire.dart';
import '../widgets/zen_streak_widget.dart';
import '../widgets/zencoins_badge.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // El descanso largo permanece fijo; el corto y el trabajo vienen de SettingsService.
  static const int _descansoLargoSeg = 15 * 60;
  static const Color _colorTrabajo = Color(0xFF8DC49A);

  Timer? _timer;
  int _segundosRestantes = SettingsService.instance.pomodoroDuration.value * 60;
  bool _corriendo = false;
  bool _esTrabajo = true;
  int _pomodorosEnCiclo = 0;

  List<Tarea> _tareasHoy = [];
  Tarea? _tareaActual;
  int _tareaIndex = 0;
  int _completadas = 0;
  int _pendientes = 0;
  int _vencidas = 0;
  int _racha = 0;

  final _db = DbService();

  @override
  void initState() {
    super.initState();
    StreakService.instance.init();
    _cargarDatos();
    // Reactividad: actualizar timer cuando cambian los ajustes de Pomodoro.
    SettingsService.instance.pomodoroDuration.addListener(_onPomodoroChanged);
    SettingsService.instance.breakDuration.addListener(_onBreakChanged);
    // Reactividad: recargar stats cuando se escribe en la BD desde cualquier pantalla.
    DbService().revision.addListener(_onDbRevision);
  }

  void _onPomodoroChanged() {
    if (_corriendo || !_esTrabajo) return;
    final newSecs =
        (_tareaActual?.tiempoSesion ?? SettingsService.instance.pomodoroDuration.value) * 60;
    if (mounted) setState(() => _segundosRestantes = newSecs);
  }

  void _onBreakChanged() {
    if (_corriendo || _esTrabajo || _pomodorosEnCiclo == 0) return;
    if (mounted) {
      setState(() =>
          _segundosRestantes = SettingsService.instance.breakDuration.value * 60);
    }
  }

  void _onDbRevision() {
    if (mounted) { _cargarDatos(); }
  }

  Future<void> _cargarDatos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hoy = DateTime.now();
    final tareas = await _db.obtenerTareasPorFecha(uid, hoy);
    final completadas = await _db.contarCompletadas(uid);
    final pendientes = await _db.contarPendientes(uid);
    final vencidas = await _db.contarVencidas(uid);
    final racha = await _db.calcularRacha(uid);

    if (!mounted) return;
    StreakService.instance.streak.value = racha;
    setState(() {
      _tareasHoy = tareas;
      _tareaActual = tareas.isNotEmpty ? tareas[0] : null;
      _tareaIndex = 0;
      _completadas = completadas;
      _pendientes = pendientes;
      _vencidas = vencidas;
      _racha = racha;
      // Solo sincroniza el timer si no está corriendo para no interrumpir sesiones.
      if (!_corriendo && _tareaActual != null) {
        _segundosRestantes = _tareaActual!.tiempoSesion * 60;
      }
    });
  }

  void _cambiarTarea(int index) {
    if (index < 0 || index >= _tareasHoy.length) return;
    setState(() {
      _tareaIndex = index;
      _tareaActual = _tareasHoy[index];
      _segundosRestantes = _tareaActual!.tiempoSesion * 60;
      _corriendo = false;
      _timer?.cancel();
    });
  }

  Future<void> _completarTarea() async {
    if (_tareaActual == null) return;
    final tarea = _tareaActual!;
    await _db.completarTarea(tarea.id);

    // Recompensar con ZenCoins
    final aTime = !DateTime.now().isAfter(tarea.fechaEntrega);
    await EconomyService.instance.rewardTaskCompletion(
      multiplier: aTime ? (_racha >= 3 ? 2 : 1) : 1,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aTime
              ? '¡Tarea completada a tiempo! +${EconomyService.coinsPerTask} 🐟'
              : '¡Tarea completada! +${EconomyService.coinsPerTask} 🐟'),
          backgroundColor: const Color(0xFF8DC49A),
        ),
      );
    }
    await _cargarDatos();
  }

  Future<void> _claimDailyQuest() async {
    final claimed = await EconomyService.instance.claimDailyQuestReward();
    if (claimed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡+75 ZenCoins reclamados! 🎉'),
          backgroundColor: Color(0xFF8DC49A),
        ),
      );
    }
  }

  void _showZenQuestModal() {
    final totalHoy = _tareasHoy.length;
    final completadasHoy = _tareasHoy.where((t) => t.completada).length;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ZenQuestSheet(
        pendientes: _pendientes,
        completadasHoy: completadasHoy,
        totalHoy: totalHoy,
        vencidas: _vencidas,
        racha: _racha,
        completadasTotal: _completadas,
      ),
    );
  }

  int get _duracionTotal => _esTrabajo
      ? (_tareaActual?.tiempoSesion ?? SettingsService.instance.pomodoroDuration.value) * 60
      : (_pomodorosEnCiclo == 0
          ? _descansoLargoSeg
          : SettingsService.instance.breakDuration.value * 60);

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

  void _alTerminar() {
    _timer?.cancel();
    setState(() {
      _corriendo = false;
      if (_esTrabajo) {
        _pomodorosEnCiclo = (_pomodorosEnCiclo + 1) % 4;
        _esTrabajo = false;
        // Recompensar minutos de foco según la duración real de la sesión.
        EconomyService.instance.rewardFocusMinutes(
          _tareaActual?.tiempoSesion ?? SettingsService.instance.pomodoroDuration.value,
        );
      } else {
        _esTrabajo = true;
      }
      _segundosRestantes = _duracionTotal;
    });
    final mensaje =
        _esTrabajo ? '¡A trabajar! 💪' : '¡Tómate un descanso! ☕';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(mensaje),
          duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    SettingsService.instance.pomodoroDuration.removeListener(_onPomodoroChanged);
    SettingsService.instance.breakDuration.removeListener(_onBreakChanged);
    DbService().revision.removeListener(_onDbRevision);
    super.dispose();
  }

  String get _tiempoFormateado {
    final min = _segundosRestantes ~/ 60;
    final seg = _segundosRestantes % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  Color get _colorModo =>
      _esTrabajo ? _colorTrabajo : Colors.amber.shade600;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/bicato.png', width: 28, height: 28, fit: BoxFit.contain),
            const SizedBox(width: 8),
            const Text('Zentask', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: false,
        actions: [
          const StreakFire(),
          const SizedBox(width: 8),
          const ZenCoinsBadge(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Perfil ────────────────────────────────────────────────────
            FutureBuilder<void>(
              future: user?.reload(),
              builder: (context, _) {
                final u = FirebaseAuth.instance.currentUser;
                return Column(
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xFF8DC49A),
                      child: Icon(Icons.person,
                          size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      u?.displayName ??
                          u?.email?.split('@')[0] ??
                          'Usuario',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      u?.email ?? '',
                      style:
                          TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const ZenStreakWidget(),
            const SizedBox(height: 16),

            // ── Tarea actual ──────────────────────────────────────────────
            if (_tareaActual != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFD6E8D8), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tarea de hoy',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7D9882),
                            letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(_tareaActual!.nombre,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A4A3E))),
                    Text(_tareaActual!.materia,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7D9882))),
                    const SizedBox(height: 4),
                    Text(
                      'Entrega: ${_tareaActual!.fechaEntrega.day}/${_tareaActual!.fechaEntrega.month}/${_tareaActual!.fechaEntrega.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: DateTime.now().isAfter(
                                _tareaActual!.fechaEntrega)
                            ? Colors.red.shade400
                            : const Color(0xFF7D9882),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selector de tarea si hay varias
                    if (_tareasHoy.length > 1)
                      Row(
                        children: List.generate(
                          _tareasHoy.length,
                          (i) => GestureDetector(
                            onTap: () => _cambiarTarea(i),
                            child: Container(
                              width: 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _tareaIndex
                                    ? const Color(0xFF8DC49A)
                                    : const Color(0xFFD6E8D8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Botón completar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _completarTarea,
                        icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white),
                        label: const Text(
                            'Marcar como completada',
                            style:
                                TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF8DC49A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFD6E8D8), width: 1.5),
                ),
                child: const Column(
                  children: [
                    Text('🌿', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 8),
                    Text('No hay tareas para hoy',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4A3E))),
                    Text('¡Crea una nueva tarea!',
                        style:
                            TextStyle(color: Color(0xFF7D9882))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Timer Pomodoro ────────────────────────────────────────────
            _buildTimerSection(),
            const SizedBox(height: 16),

            // ── Daily Zen Quest ───────────────────────────────────────────
            GestureDetector(
              onTap: _showZenQuestModal,
              child: _buildDailyQuestSection(),
            ),
            const SizedBox(height: 16),

            // ── Estadísticas ──────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Pendientes', '$_pendientes',
                    'Sin completar', Colors.amber.shade700),
                _buildStatCard('Completadas', '$_completadas',
                    'Total', Colors.green.shade600),
                _buildStatCard('Vencidas', '$_vencidas',
                    'Sin entregar', Colors.red.shade400),
                _buildStatCard(
                    'Racha', '🔥 $_racha', 'Días seguidos', Colors.orange.shade600),
              ],
            ),
            const SizedBox(height: 16),
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
        final canClaim =
            quest.isReadyToClaim && !quest.rewardClaimed;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFFD6E8D8), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8DC49A)
                    .withValues(alpha: 0.08),
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
                    child: const Icon(Icons.spa_rounded,
                        color: Color(0xFF8DC49A), size: 21),
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
                        horizontal: 10, vertical: 6),
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
                    disabledBackgroundColor:
                        const Color(0xFFEAF4EB),
                    disabledForegroundColor:
                        const Color(0xFF7D9882),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12),
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
                    child: Text(label,
                        style: const TextStyle(
                          color: Color(0xFF3A4A3E),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                  ),
                  Text(value,
                      style: const TextStyle(
                        color: Color(0xFF7D9882),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFEAF4EB),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFD6E8D8), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _colorModo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _esTrabajo
                  ? 'Trabajo'
                  : (_pomodorosEnCiclo == 0
                      ? 'Descanso largo'
                      : 'Descanso'),
              style: TextStyle(
                  color: _colorModo,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _colorModo),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  _tiempoFormateado,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A4A3E),
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _reiniciar,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 28,
                color: const Color(0xFF7D9882),
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
                        color:
                            _colorModo.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _corriendo
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final completado = i < _pomodorosEnCiclo;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: completado ? 10 : 8,
                  height: completado ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completado
                        ? _colorTrabajo
                        : const Color(0xFFD6E8D8),
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
      String title, String count, String subtitle, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Spacer(),
            Text(count,
                style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Modal de ZenQuest ─────────────────────────────────────────────────────────

class _ZenQuestSheet extends StatelessWidget {
  const _ZenQuestSheet({
    required this.pendientes,
    required this.completadasHoy,
    required this.totalHoy,
    required this.vencidas,
    required this.racha,
    required this.completadasTotal,
  });

  final int pendientes;
  final int completadasHoy;
  final int totalHoy;
  final int vencidas;
  final int racha;
  final int completadasTotal;

  @override
  Widget build(BuildContext context) {
    final progreso =
        totalHoy > 0 ? (completadasHoy / totalHoy).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6E8D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.spa_rounded,
                    color: Color(0xFF8DC49A), size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Zen Quest',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3A4A3E))),
                  Text('Tu progreso de hoy',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF7D9882))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Barra de progreso tareas del día
          Row(
            children: [
              Text('$completadasHoy / $totalHoy tareas completadas hoy',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3A4A3E))),
              const Spacer(),
              Text('${(progreso * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8DC49A))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 10,
              backgroundColor: const Color(0xFFEAF4EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF8DC49A)),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEAF4EB), height: 1),
          const SizedBox(height: 20),

          // Cuadrícula de estadísticas
          Row(
            children: [
              Expanded(
                child: _statCell(
                  icon: Icons.hourglass_top_rounded,
                  value: '$pendientes',
                  label: 'Pendientes',
                  color: Colors.amber.shade700,
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$completadasTotal',
                  label: 'Completadas',
                  color: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.warning_amber_rounded,
                  value: '$vencidas',
                  label: 'Vencidas',
                  color: Colors.red.shade400,
                ),
              ),
              Expanded(
                child: _statCell(
                  icon: Icons.local_fire_department_rounded,
                  value: '$racha',
                  label: 'Racha',
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón cerrar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7D9882),
                side: const BorderSide(color: Color(0xFFD6E8D8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cerrar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF7D9882))),
      ],
    );
  }
}