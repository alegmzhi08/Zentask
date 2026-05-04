import 'package:flutter/material.dart';

/// Pinta el fondo del jardín zen de forma procedural según el [tier].
///
/// Tier 1 (0-3 gatos): arena lisa.
/// Tier 2 (4-7 gatos): arena con líneas horizontales suaves (rastrillado simple).
/// Tier 3 (8+ gatos):  rastrillado con ondas circulares alrededor de dos piedras.
///
/// [shouldRepaint] devuelve `false` mientras el tier no cambie, de modo que
/// los ~60 ticks/s del movimiento de gatos no disparan redibujado del fondo.
class ZenGardenPainter extends CustomPainter {
  const ZenGardenPainter({required this.tier});

  final int tier;

  // ── Paleta ───────────────────────────────────────────────────────────────
  static const Color _sand  = Color(0xFFF5EDDA);
  static const Color _rake  = Color(0xFFCCBFA0);
  static const Color _rock  = Color(0xFFAA9878);
  static const Color _rockEdge = Color(0xFF8E7E62);

  // ── Métricas del rastrillado ──────────────────────────────────────────────
  static const double _lineGap    = 18.0; // separación entre líneas
  static const double _amplitude  =  2.2; // altura de la onda (px)
  static const double _waveLen    = 60.0; // longitud de onda (px)
  static const double _strokeW    =  1.1;

  // ── Piedras (posición relativa, fija) ────────────────────────────────────
  static const double _rockR      = 10.0;
  static const int    _ripples    =  5;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Fondo de arena ──────────────────────────────────────────────────────
    canvas.drawRect(Offset.zero & size, Paint()..color = _sand);

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

    // ── Tier 3: líneas evitando zonas de piedras ─────────────────────────────
    _drawTier3(canvas, size, rake);
  }

  // ── Tier 2 ───────────────────────────────────────────────────────────────

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    for (double y = _lineGap; y < size.height; y += _lineGap) {
      canvas.drawPath(_wavePath(y, 0, size.width), paint);
    }
  }

  /// Genera una curva bezier cuadrática que simula una línea de rastrillo.
  /// [xOffset] desplaza la fase horizontal (para las líneas fuera del clip).
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

    // Clip: recorte que excluye las zonas de ripple alrededor de cada piedra.
    // PathFillType.evenOdd: rect(odd) - círculos(even) = visible fuera de los círculos.
    final clip = Path()..addRect(Offset.zero & size);
    for (final c in rocks) {
      clip.addOval(Rect.fromCircle(center: c, radius: rippleR + 2));
    }
    clip.fillType = PathFillType.evenOdd;

    canvas.save();
    canvas.clipPath(clip);
    _drawLines(canvas, size, paint);
    canvas.restore();

    // Ripples concéntricos
    for (final c in rocks) {
      for (int i = 1; i <= _ripples; i++) {
        canvas.drawCircle(c, _rockR + i * _lineGap, paint);
      }
      // Sombra sutil (círculo desplazado)
      canvas.drawCircle(
        c.translate(1.5, 2),
        _rockR,
        Paint()
          ..color = const Color(0x40000000)
          ..style = PaintingStyle.fill,
      );
      // Piedra
      canvas.drawCircle(c, _rockR, Paint()
        ..color = _rock
        ..style = PaintingStyle.fill);
      canvas.drawCircle(c, _rockR, paint
        ..color = _rockEdge
        ..strokeWidth = 1.0);
    }
    // Restaurar color del rake para usos futuros (paint es mutable)
    paint
      ..color = _rake
      ..strokeWidth = _strokeW;
  }

  /// Posiciones fijas de las piedras en coordenadas relativas al tamaño.
  static List<Offset> _rockCenters(Size size) => [
        Offset(size.width * 0.27, size.height * 0.37),
        Offset(size.width * 0.71, size.height * 0.64),
      ];

  @override
  bool shouldRepaint(ZenGardenPainter old) => old.tier != tier;
}
