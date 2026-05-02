// lib/widgets/streak_fire.dart
import 'package:flutter/material.dart';
import '../services/streak_service.dart';

/// Badge de racha para el AppBar. Pulsa al entrar si la racha está activa,
/// y vuelve a pulsar cada vez que el valor sube.
class StreakFire extends StatelessWidget {
  const StreakFire({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StreakService.instance.streak,
      builder: (context, valor, _) {
        if (valor == 0) return const SizedBox.shrink();
        return _FireBadge(valor: valor);
      },
    );
  }
}

class _FireBadge extends StatefulWidget {
  final int valor;
  const _FireBadge({required this.valor});

  @override
  State<_FireBadge> createState() => _FireBadgeState();
}

class _FireBadgeState extends State<_FireBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _escala;

  // Naranja normal → dorado cuando se alcanza el umbral del multiplicador
  Color get _colorFondo => widget.valor >= StreakService.umbralMultiplicador
      ? const Color(0xFFFFD700)
      : const Color(0xFFFF6B35);

  Color get _colorTexto => widget.valor >= StreakService.umbralMultiplicador
      ? const Color(0xFF7A4000)
      : Colors.white;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _escala = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.25, end: 0.95)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(_ctrl);

    // Pulso inicial al aparecer en pantalla
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_FireBadge old) {
    super.didUpdateWidget(old);
    if (widget.valor != old.valor) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _escala,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: _colorFondo,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _colorFondo.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              '${widget.valor}',
              style: TextStyle(
                color: _colorTexto,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
