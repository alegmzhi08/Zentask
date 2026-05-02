// lib/widgets/zencoins_badge.dart
import 'package:flutter/material.dart';
import '../services/economy_service.dart';

/// Indicador de saldo de ZenCoins para el AppBar.
/// Se auto-actualiza via ValueListenableBuilder sin necesidad de setState externo.
class ZenCoinsBadge extends StatelessWidget {
  const ZenCoinsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: EconomyService.instance.balance,
      builder: (context, saldo, _) {
        return _Badge(saldo: saldo);
      },
    );
  }
}

class _Badge extends StatefulWidget {
  final int saldo;
  const _Badge({required this.saldo});

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulso;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulso = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_Badge old) {
    super.didUpdateWidget(old);
    if (widget.saldo != old.saldo) {
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
      scale: _pulso,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD966), Color(0xFFFFAA33)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD966).withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐟', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              '${widget.saldo}',
              style: const TextStyle(
                color: Color(0xFF7A3F00),
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
