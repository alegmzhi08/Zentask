import 'dart:math';
import 'package:flutter/material.dart';
import '../services/streak_service.dart';

// ── Frases Zen (12) ───────────────────────────────────────────────────────────
const List<String> _kFrases = [
  'Un paso a la vez, una tarea al día.',
  'Tu jardín florece con tu constancia.',
  'Respira, enfócate, logra.',
  'La racha no es un número — es un hábito.',
  'Cada día completado es una semilla plantada.',
  'El árbol más fuerte creció con paciencia.',
  'Pequeñas acciones, grandes transformaciones.',
  'La calma es la base de toda productividad.',
  'Hoy sembraste. Mañana cosecharás.',
  'Tu mente clara, tus metas más cerca.',
  'El momento presente siempre será suficiente.',
  'Fluye con tus tareas como el agua sobre las piedras.',
];

/// Tarjeta de racha con pulso continuo y frases motivacionales al toque.
///
/// Consume [StreakService.instance.streak] (ValueNotifier) — se actualiza
/// automáticamente cada vez que [InicioScreen._cargarDatos] sincroniza el
/// dato real del DbService.
///
/// No usa Riverpod ni dependencias externas: mismo patrón que [ZenCoinsBadge].
class ZenStreakWidget extends StatelessWidget {
  const ZenStreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StreakService.instance.streak,
      builder: (_, racha, __) => _StreakCard(racha: racha),
    );
  }
}

// ── Tarjeta interna con animación ─────────────────────────────────────────────

class _StreakCard extends StatefulWidget {
  final int racha;
  const _StreakCard({required this.racha});

  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard>
    with SingleTickerProviderStateMixin {
  static final _rng = Random();

  late final AnimationController _ctrl;
  late final Animation<double> _pulso;

  bool get _activa => widget.racha > 0;
  bool get _dorada => widget.racha >= StreakService.umbralMultiplicador;

  @override
  void initState() {
    super.initState();
    // Pulso "respiración" continuo: va de 0.93 a 1.07 y vuelve.
    // 1 800 ms por ciclo → ~33 FPS de esfuerzo mínimo vía ScaleTransition.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulso = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Feedback de frase ─────────────────────────────────────────────────────

  void _mostrarFrase() {
    final frase = _kFrases[_rng.nextInt(_kFrases.length)];
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  frase,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D3B33),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          duration: const Duration(seconds: 4),
          elevation: 4,
        ),
      );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gradientColors = _dorada
        ? [const Color(0xFFFF8C00), const Color(0xFFFFD700)]
        : _activa
            ? [const Color(0xFFE05A20), const Color(0xFFFF9040)]
            : [const Color(0xFF3A4A3E), const Color(0xFF536057)];

    final glowColor = _dorada
        ? const Color(0xFFFFD700)
        : _activa
            ? const Color(0xFFFF6B35)
            : Colors.transparent;

    return GestureDetector(
      onTap: _mostrarFrase,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _activa
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            // ── Fuego con pulso continuo ───────────────────────────────────
            ScaleTransition(
              scale: _activa ? _pulso : const AlwaysStoppedAnimation(1.0),
              child: Text(
                _activa ? '🔥' : '✨',
                style: const TextStyle(fontSize: 38),
              ),
            ),
            const SizedBox(width: 16),

            // ── Texto informativo ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número de racha con AnimatedSwitcher para transición suave
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      key: ValueKey(widget.racha),
                      _activa
                          ? '${widget.racha} día${widget.racha == 1 ? '' : 's'} de racha'
                          : 'Comienza tu racha',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dorada
                        ? '¡Racha dorada · Recompensa ×2! ✦'
                        : 'Toca para una frase zen 🌿',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Badge ×2 (solo en racha dorada) ───────────────────────────
            if (_dorada) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '×2',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
