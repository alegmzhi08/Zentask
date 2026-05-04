import 'package:flutter/material.dart';
import '../logic/cat_garden_provider.dart';
import 'zen_garden_painter.dart';
import 'garden/interactive_cat_widget.dart';

// ── Rutas de assets del jardín ────────────────────────────────────────────────
const _kRock1   = 'assets/images/game/garden/rock_1.png';
const _kRock2   = 'assets/images/game/garden/rock_2.png';
const _kBush1   = 'assets/images/game/garden/bush_1.png';
const _kBush2   = 'assets/images/game/garden/bush_2.png';
const _kLantern = 'assets/images/game/garden/lantern.png';
const _kBonsai  = 'assets/images/game/garden/bonsai.png';
const _kSakura  = 'assets/images/game/garden/sakura.png';

/// Jardín interactivo donde los gatos se mueven de forma autónoma.
///
/// Z-index del Stack (de atrás hacia adelante):
///   0 – Fondo procedural [ZenGardenPainter] (gradiente oscuro)
///   1 – Rocas            (tier 1+, ancladas al fondo como suelo)
///   2 – Arbustos, bonsai, linterna (tier 2+, plano medio)
///   3 – Gatos animados   (centro del jardín)
///   4 – Cerezo sakura    (tier 3, esquina superior-derecha)
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

                // ── Capa 1: Rocas (tier 1+) — ancladas al suelo ─────────────
                // Posicionadas en la franja inferior para crear un plano base
                // que visualmente "ancla" a los gatos.
                _decorLayer(
                  visible: tier >= 1,
                  children: [
                    _decor(_kRock1, left: w * 0.04, top: h * 0.78, size: 92),
                    _decor(_kRock2, left: w * 0.70, top: h * 0.80, size: 86),
                  ],
                ),

                // ── Capa 2: Arbustos, bonsai y linterna (tier 2+) ───────────
                _decorLayer(
                  visible: tier >= 2,
                  children: [
                    _decor(_kBush2,   left: w * 0.02, top: h * 0.22, size: 88),
                    _decor(_kBonsai,  left: w * 0.07, top: h * 0.48, size: 88),
                    _decor(_kBush1,   left: w * 0.56, top: h * 0.53, size: 94),
                    _decor(_kLantern, left: w * 0.43, top: h * 0.63, size: 58),
                  ],
                ),

                // ── Capa 3: Gatos interactivos ───────────────────────────────
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

                // ── Capa 4: Cerezo sakura (tier 3, techo superior-derecho) ───
                // Los gatos que pasen por esa zona quedan visualmente "bajo"
                // las ramas al estar en una capa inferior.
                _decorLayer(
                  visible: tier >= 3,
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: _img(_kSakura, 175),
                    ),
                  ],
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
