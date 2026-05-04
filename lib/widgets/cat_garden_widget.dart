import 'package:flutter/material.dart';
import '../logic/cat_garden_provider.dart';
import 'zen_garden_painter.dart';
import 'garden/interactive_cat_widget.dart';

// ── Rutas de assets del jardín ────────────────────────────────────────────────
const _kRock1    = 'assets/images/game/garden/rock_1.png';
const _kRock2    = 'assets/images/game/garden/rock_2.png';
const _kBush1    = 'assets/images/game/garden/bush_1.png';
const _kBush2    = 'assets/images/game/garden/bush_2.png';
const _kLantern  = 'assets/images/game/garden/lantern.png';
const _kLantern2 = 'assets/images/game/garden/lantern_2.png';
const _kLantern3 = 'assets/images/game/garden/lantern_3.png';
const _kBonsai   = 'assets/images/game/garden/bonsai.png';
const _kBonsai2  = 'assets/images/game/garden/bonsai_2.png';
const _kSakura   = 'assets/images/game/garden/sakura.png';
const _kSakura2  = 'assets/images/game/garden/sakura_2.png';
const _kPond1    = 'assets/images/game/garden/pond_1.png';
const _kPond2    = 'assets/images/game/garden/pond_2.png';
const _kBicato   = 'assets/bicato.png';

/// Jardín interactivo donde los gatos se mueven de forma autónoma.
///
/// Z-index del Stack (de atrás hacia adelante):
///   0   – Fondo procedural [ZenGardenPainter] (gradiente verde ZenTask)
///   0.5 – Marca de agua Bicato (opacidad 0.04)
///   1   – Estanques + rocas   (tier 1+, ordenados por top asc = profundidad)
///   2   – Vegetación + 3 linternas (tier 2+, ordenados por top asc = profundidad)
///   2.5 – Sakura (tier 3): top-izq + bottom-der — siempre BAJO los gatos
///   3   – Gatos animados (SIEMPRE encima de todo)
class CatGardenWidget extends StatelessWidget {
  const CatGardenWidget({super.key, required this.provider});

  final CatGardenProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        provider.setBounds(Size(constraints.maxWidth, constraints.maxHeight));

        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return ListenableBuilder(
          listenable: provider,
          builder: (_, __) {
            final tier = provider.gardenTier;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [

                // ── Capa 0: Gradiente de fondo ──────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: ZenGardenPainter(tier: tier),
                  ),
                ),

                // ── Capa 0.5: Marca de agua Bicato ──────────────────────────
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 0.04,
                      child: Image.asset(
                        _kBicato,
                        width: w * 0.55,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // ── Capa 1: Estanques + rocas (tier 1+) ─────────────────────
                // Orden: top ascendente → pond_2 primero (fondo), pond_1 al último
                // (frente). Las rocas se intercalan por profundidad.
                _decorLayer(
                  visible: tier >= 1,
                  children: [
                    // pond_2: esquina superior-derecha (más lejana, pinta primero)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: _img(_kPond2, 135),
                    ),
                    // rock_2: franja media-derecha
                    _decor(_kRock2, left: w * 0.76, top: h * 0.48, size: 84),
                    // rock_1: franja inferior-izquierda
                    _decor(_kRock1, left: w * 0.06, top: h * 0.70, size: 90),
                    // pond_1: esquina inferior-izquierda (más cercana, pinta al último)
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: _img(_kPond1, 135),
                    ),
                  ],
                ),

                // ── Capa 2: Vegetación + 3 linternas (tier 2+) ──────────────
                // Orden estricto: top ascendente = profundidad isométrica correcta.
                //
                // Distribución de bonsáis (>15% de separación entre sí):
                //   • bonsai   → zona izquierda  (left ~4%)
                //   • bonsai_2 → zona dcha-alta   (left ~60%, cerca de pond_2)
                //
                // Arbustos como conectores, no como muros:
                //   • bush_1 → conector entre lantern_2 y zona derecha (left ~52%)
                //   • bush_2 → conector hacia pond_1, bajo izquierda  (left ~24%)
                _decorLayer(
                  visible: tier >= 2,
                  children: [
                    // top h*0.22 — lanterna central (ancla zona media)
                    _decor(_kLantern2, left: w * 0.40, top: h * 0.22, size: 60),
                    // top h*0.28 — bonsai_2: dcha-media, base debajo de pond_2
                    // (pond_2 ocupa top 0..135px ≈ 0..16%h; h*0.28 queda siempre libre)
                    _decor(_kBonsai2,  left: w * 0.58, top: h * 0.28, size: 88),
                    // top h*0.30 — bonsai: zona izquierda (>50% sep. horizontal)
                    _decor(_kBonsai,   left: w * 0.04, top: h * 0.30, size: 88),
                    // top h*0.35 — bush_1: conector junto a lantern_2, aireado
                    _decor(_kBush1,    left: w * 0.52, top: h * 0.35, size: 84),
                    // top h*0.44 — lanterna izquierda
                    _decor(_kLantern,  left: w * 0.10, top: h * 0.44, size: 60),
                    // top h*0.58 — lanterna derecha (franja inferior)
                    _decor(_kLantern3, left: w * 0.70, top: h * 0.58, size: 60),
                    // top h*0.66 — bush_2: conector en el camino hacia pond_1
                    _decor(_kBush2,    left: w * 0.24, top: h * 0.66, size: 84),
                  ],
                ),

                // ── Capa 2.5: Sakura (tier 3) ───────────────────────────────
                // Posición simétrica diagonal: top-izq ↔ bottom-der.
                // Sakura sale de top-der para no tapar pond_2 (también top-der).
                // Gatos se renderizan en capa 3, SIEMPRE por encima.
                _decorLayer(
                  visible: tier >= 3,
                  children: [
                    // sakura: esquina superior-izquierda (libre de estanques)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: _img(_kSakura, 175),
                    ),
                    // sakura_2: esquina inferior-derecha (simétrica diagonal)
                    Positioned(
                      right: 0,
                      bottom: h * 0.05,
                      child: _img(_kSakura2, 130),
                    ),
                  ],
                ),

                // ── Capa 3: Gatos interactivos (siempre encima) ─────────────
                for (final cat in provider.cats)
                  Positioned(
                    key: ValueKey(cat.id),
                    left: cat.x,
                    top: cat.y,
                    child: InteractiveCatWidget(
                      asset: cat.spriteAssetPath,
                      size: CatGardenProvider.spriteSize,
                      catId: cat.id,
                      provider: provider,
                    ),
                  ),

              ],
            );
          },
        );
      },
    );
  }

  // ── Helpers de construcción ───────────────────────────────────────────────

  static Widget _decorLayer({
    required bool visible,
    required List<Widget> children,
  }) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        child: Stack(
          fit: StackFit.expand,
          children: children,
        ),
      ),
    );
  }

  static Positioned _decor(
    String asset, {
    required double left,
    required double top,
    required double size,
  }) {
    return Positioned(left: left, top: top, child: _img(asset, size));
  }

  static Widget _img(String asset, double size) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      fit: BoxFit.contain,
    );
  }
}
