import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../logic/cat_garden_provider.dart';
import '../../services/audio_service.dart';

enum _FeedbackType { heart, food, levelUp, error }

// ── Línea de tiempo de la evolución (fracciones del controlador) ──────────────
//   [0.00 – 0.28]  sacudida horizontal
//   [0.28 – 0.50]  destello sube  →  pico (audio aquí)
//   [0.50 – 0.85]  destello baja
//   [0.85 – 1.00]  reposo
const double _kShakeEnd  = 0.28;
const double _kFlashPeak = 0.50;
const double _kFlashEnd  = 0.85;
const int    _kEvoDurMs  = 1300; // < 1500 ms según restricción

/// Sprite de gato con retroalimentación táctil, de alimentación y de evolución.
///
/// - Tap       → sonido pet + corazón flotante.
/// - LongPress → feedCat():
///     · insufficientFunds → icono error.
///     · fed               → sonido feed + icono comida.
///     · levelUp           → sacudida + destello + audio en el pico + estrellas.
class InteractiveCatWidget extends StatefulWidget {
  const InteractiveCatWidget({
    super.key,
    required this.asset,
    required this.size,
    required this.catId,
    required this.provider,
  });

  final String asset;
  final double size;
  final String catId;
  final CatGardenProvider provider;

  @override
  State<InteractiveCatWidget> createState() => _InteractiveCatWidgetState();
}

class _InteractiveCatWidgetState extends State<InteractiveCatWidget>
    with SingleTickerProviderStateMixin {

  // ── Feedback flotante (tap / feed / error) ────────────────────────────────
  _FeedbackType? _feedbackType;
  int _feedbackKey = 0;
  Timer? _hideTimer;

  // ── Evolución ─────────────────────────────────────────────────────────────
  late final AnimationController _evoCtrl;
  bool _isEvolving = false;
  bool _evoAudioFired = false;

  @override
  void initState() {
    super.initState();
    _evoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kEvoDurMs),
    );
    // Dispara el audio exactamente al llegar al pico del destello.
    _evoCtrl.addListener(_onEvoTick);
    _evoCtrl.addStatusListener(_onEvoStatus);
  }

  void _onEvoTick() {
    if (!_evoAudioFired && _evoCtrl.value >= _kFlashPeak) {
      _evoAudioFired = true;
      AudioService.instance.playLevelUpSound();
    }
  }

  void _onEvoStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _evoCtrl.reset();
      _evoAudioFired = false;
      if (mounted) setState(() => _isEvolving = false);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _evoCtrl.dispose();
    super.dispose();
  }

  // ── Triggers ──────────────────────────────────────────────────────────────

  void _trigger(_FeedbackType type, {int durationMs = 850}) {
    _hideTimer?.cancel();
    setState(() {
      _feedbackType = type;
      _feedbackKey++;
    });
    _hideTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) setState(() => _feedbackType = null);
    });
  }

  void _triggerEvolution() {
    _evoAudioFired = false;
    setState(() => _isEvolving = true);
    _evoCtrl.forward(from: 0.0);
    _trigger(_FeedbackType.levelUp, durationMs: 1100); // estrellas flotantes
  }

  void _onTap() {
    AudioService.instance.playPetSound();
    _trigger(_FeedbackType.heart);
  }

  Future<void> _onLongPress() async {
    final result = await widget.provider.feedCat(widget.catId);
    switch (result) {
      case FeedResult.insufficientFunds:
        _trigger(_FeedbackType.error, durationMs: 600);
      case FeedResult.fed:
        AudioService.instance.playFeedSound();
        _trigger(_FeedbackType.food);
      case FeedResult.levelUp:
        _triggerEvolution(); // el audio se dispara en _onEvoTick, no aquí
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      // AnimatedBuilder redibuja solo este subárbol en cada tick del controlador.
      child: AnimatedBuilder(
        animation: _evoCtrl,
        builder: (_, __) {
          final t = _evoCtrl.value;

          // Sacudida: onda sinusoidal horizontal durante [0, _kShakeEnd].
          final shakeX = (_isEvolving && t <= _kShakeEnd)
              ? sin(t / _kShakeEnd * pi * 5) * 5.0
              : 0.0;

          // Destello: sube de 0 a 1 entre [shakeEnd, peak], baja entre [peak, flashEnd].
          double flash = 0.0;
          if (_isEvolving) {
            if (t > _kShakeEnd && t <= _kFlashPeak) {
              flash = (t - _kShakeEnd) / (_kFlashPeak - _kShakeEnd);
            } else if (t > _kFlashPeak && t <= _kFlashEnd) {
              flash = 1.0 - (t - _kFlashPeak) / (_kFlashEnd - _kFlashPeak);
            }
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [

              // Sprite del gato con sacudida
              Transform.translate(
                offset: Offset(shakeX, 0),
                child: GestureDetector(
                  onTap: _onTap,
                  onLongPress: _onLongPress,
                  behavior: HitTestBehavior.opaque,
                  child: Image.asset(
                    widget.asset,
                    key: ValueKey(widget.asset),
                    width: s,
                    height: s,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),

              // Destello blanco de evolución
              if (flash > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: flash.clamp(0.0, 0.88),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                ),

              // Iconos flotantes (corazón, comida, estrellas, error)
              if (_feedbackType != null)
                ..._buildOverlay(_feedbackType!, s),
            ],
          );
        },
      ),
    );
  }

  // ── Overlays flotantes ────────────────────────────────────────────────────

  List<Widget> _buildOverlay(_FeedbackType type, double s) {
    switch (type) {
      case _FeedbackType.heart:
        return [
          _floatingAt(
            key: '$_feedbackKey',
            left: s / 2 - 7,  top: s * 0.1,
            icon: Icons.favorite, color: const Color(0xFFFF6B8A),
            size: 14, rise: 36, ms: 800,
          ),
        ];
      case _FeedbackType.food:
        return [
          _floatingAt(
            key: '$_feedbackKey',
            left: s / 2 - 9,  top: s * 0.05,
            icon: Icons.set_meal, color: const Color(0xFFFF9800),
            size: 17, rise: 36, ms: 800,
          ),
        ];
      case _FeedbackType.levelUp:
        return [
          _floatingAt(
            key: '${_feedbackKey}_c',
            left: s / 2 - 9, top: -s * 0.05,
            icon: Icons.star, color: const Color(0xFFFFD700),
            size: 18, rise: 48, ms: 1000, scaleUp: true,
          ),
          _floatingAt(
            key: '${_feedbackKey}_l',
            left: s * 0.03, top: s * 0.05,
            icon: Icons.star, color: const Color(0xFFFFF176),
            size: 12, rise: 34, ms: 900,
          ),
          _floatingAt(
            key: '${_feedbackKey}_r',
            left: s * 0.68, top: s * 0.05,
            icon: Icons.star, color: const Color(0xFFFFD700),
            size: 12, rise: 30, ms: 950,
          ),
        ];
      case _FeedbackType.error:
        return [
          _floatingAt(
            key: '$_feedbackKey',
            left: s / 2 - 7, top: s * 0.1,
            icon: Icons.money_off, color: const Color(0xFFE53935),
            size: 14, rise: 20, ms: 500,
          ),
        ];
    }
  }

  static Widget _floatingAt({
    required String key,
    required double left,
    required double top,
    required IconData icon,
    required Color color,
    required double size,
    required double rise,
    required int ms,
    bool scaleUp = false,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: _FloatingIcon(
        key: ValueKey(key),
        icon: icon, color: color, size: size, rise: rise,
        duration: Duration(milliseconds: ms),
        scaleUp: scaleUp,
      ),
    );
  }
}

// ── Icono flotante genérico (TweenAnimationBuilder) ───────────────────────────

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.rise,
    required this.duration,
    this.scaleUp = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double rise;
  final Duration duration;
  final bool scaleUp;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (_, t, __) {
        final opacity = t < 0.2
            ? t / 0.2
            : t < 0.6
                ? 1.0
                : 1.0 - (t - 0.6) / 0.4;
        final scale = scaleUp ? (0.5 + 0.5 * (t < 0.3 ? t / 0.3 : 1.0)) : 1.0;
        return Transform.translate(
          offset: Offset(0, -t * rise),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Icon(icon, color: color, size: size),
            ),
          ),
        );
      },
    );
  }
}
