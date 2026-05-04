import 'package:flutter/material.dart';

/// Pinta el fondo del jardín zen de forma procedural según el [tier].
///
/// Tier 1: gradiente oscuro limpio, sin líneas.
/// Tier 2: gradiente + líneas de rastrillo muy sutiles.
/// Tier 3: rastrillo con ondas circulares alrededor de dos piedras.
///
/// [shouldRepaint] devuelve `false` mientras el tier no cambie.
class ZenGardenPainter extends CustomPainter {
  const ZenGardenPainter({required this.tier});

  final int tier;

  // ── Paleta pastel "estanque zen diurno" ──────────────────────────────────
  static const Color _gradTop    = Color(0xFFC8E6F5); // azul cielo suave
  static const Color _gradBottom = Color(0xFFADD4EC); // azul estanque sereno
  static const Color _rake       = Color(0x50638FAA); // rastrillo visible en claro
  static const Color _rock       = Color(0xFF7B9CAF); // piedra azul-gris suave
  static const Color _rockEdge   = Color(0xFF5A7B8E); // borde piedra

  // ── Métricas del rastrillado ─────────────────────────────────────────────
  static const double _lineGap   = 18.0;
  static const double _amplitude =  2.2;
  static const double _waveLen   = 60.0;
  static const double _strokeW   =  1.1;
  static const double _rockR     = 10.0;
  static const int    _ripples   =  5;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Fondo: gradiente vertical ───────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_gradTop, _gradBottom],
        ).createShader(Offset.zero & size),
    );

    if (tier < 2) return;

    final rake = Paint()
      ..color = _rake
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeW
      ..isAntiAlias = true;

    if (tier == 2) {
      _drawLines(canvas, size, rake);
      return;
    }

    _drawTier3(canvas, size, rake);
  }

  // ── Tier 2 ───────────────────────────────────────────────────────────────

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    for (double y = _lineGap; y < size.height; y += _lineGap) {
      canvas.drawPath(_wavePath(y, 0, size.width), paint);
    }
  }

  Path _wavePath(double baseY, double xStart, double xEnd) {
    final path = Path()..moveTo(xStart, baseY);
    double x = xStart;
    while (x < xEnd) {
      final nextX = x + _waveLen;
      path.quadraticBezierTo(
        x + _waveLen / 4, baseY + _amplitude,
        x + _waveLen / 2, baseY,
      );
      path.quadraticBezierTo(
        x + _waveLen * 3 / 4, baseY - _amplitude,
        nextX, baseY,
      );
      x = nextX;
    }
    return path;
  }

  // ── Tier 3 ───────────────────────────────────────────────────────────────

  void _drawTier3(Canvas canvas, Size size, Paint paint) {
    final rocks = _rockCenters(size);
    const rippleR = _rockR + _ripples * _lineGap;

    final clip = Path()..addRect(Offset.zero & size);
    for (final c in rocks) {
      clip.addOval(Rect.fromCircle(center: c, radius: rippleR + 2));
    }
    clip.fillType = PathFillType.evenOdd;

    canvas.save();
    canvas.clipPath(clip);
    _drawLines(canvas, size, paint);
    canvas.restore();

    for (final c in rocks) {
      for (int i = 1; i <= _ripples; i++) {
        canvas.drawCircle(c, _rockR + i * _lineGap, paint);
      }
      canvas.drawCircle(
        c.translate(1.5, 2),
        _rockR,
        Paint()
          ..color = const Color(0x50000000)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(c, _rockR, Paint()
        ..color = _rock
        ..style = PaintingStyle.fill);
      canvas.drawCircle(c, _rockR, paint
        ..color = _rockEdge
        ..strokeWidth = 1.0);
    }
    paint
      ..color = _rake
      ..strokeWidth = _strokeW;
  }

  static List<Offset> _rockCenters(Size size) => [
        Offset(size.width * 0.27, size.height * 0.37),
        Offset(size.width * 0.71, size.height * 0.64),
      ];

  @override
  bool shouldRepaint(ZenGardenPainter old) => old.tier != tier;
}
