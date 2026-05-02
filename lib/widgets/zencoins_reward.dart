// lib/widgets/zencoins_reward.dart
import 'package:flutter/material.dart';

/// Muestra un toast flotante animado al ganar ZenCoins.
/// Uso: ZenCoinsReward.show(context, 50);
class ZenCoinsReward {
  static void show(BuildContext context, int amount) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RewardToast(
        amount: amount,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }
}

class _RewardToast extends StatefulWidget {
  final int amount;
  final VoidCallback onDone;

  const _RewardToast({required this.amount, required this.onDone});

  @override
  State<_RewardToast> createState() => _RewardToastState();
}

class _RewardToastState extends State<_RewardToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Pop-in elástico durante el primer 20 % de la animación
  late final Animation<double> _escala;

  // Fade: aparece → se mantiene → desvanece
  late final Animation<double> _opacidad;

  // Flota suavemente hacia arriba desde el 20 % al 100 %
  late final Animation<Offset> _deslizamiento;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _escala = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.2, curve: Curves.elasticOut),
    );

    _opacidad = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _deslizamiento = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.2),
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _opacidad,
            child: SlideTransition(
              position: _deslizamiento,
              child: ScaleTransition(
                scale: _escala,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3D32),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🐟', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Gran trabajo!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              '+${widget.amount} ZenCoins',
                              style: const TextStyle(
                                color: Color(0xFFFFD966),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
