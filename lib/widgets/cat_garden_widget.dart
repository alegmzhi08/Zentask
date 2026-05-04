import 'package:flutter/material.dart';
import '../logic/cat_garden_provider.dart';
import 'zen_garden_painter.dart';
import 'garden/interactive_cat_widget.dart';

// ── Rutas de assets del jardín ────────────────────────────────────────────────
// Ajusta los paths si renombraste algún archivo en assets/images/game/garden/.
const _kRock1   = 'assets/images/game/garden/rock_1.png';   // grupo rocas angulares
const _kRock2   = 'assets/images/game/garden/rock_2.png';   // grupo rocas mixtas
const _kBush1   = 'assets/images/game/garden/bush_1.png';   // arbusto flor rosa (con base)
const _kBush2   = 'assets/images/game/garden/bush_2.png';   // arbusto flor rosa (sin base)
const _kLantern = 'assets/images/game/garden/lantern.png';  // linterna de piedra
const _kBonsai  = 'assets/images/game/garden/bonsai.png';   // bonsai con rocas
const _kPond    = 'assets/images/game/garden/pond.png';     // estanque (vista cenital)
const _kSakura  = 'assets/images/game/garden/sakura.png';   // cerezo sakura

/// Jardín interactivo donde los gatos se mueven de forma autónoma.
///
/// Z-index del Stack (de atrás hacia adelante):
///   0 – Fondo procedural [ZenGardenPainter]
///   1 – Estanque / lago  (tier 3)
///   2 – Rocas            (tier 1+)
///   2 – Arbustos, bonsai, linterna (tier 2+)
///   3 – Gatos animados
///   4 – Cerezo sakura    (tier 3, esquina superior-derecha)
///
/// Las capas 1, 2 y 4 se envuelven en [AnimatedOpacity] (800 ms) para que
/// el fundido de entrada sea suave cuando el usuario sube de tier.
class CatGardenWidget extends StatelessWidget {
  const CatGardenWidget({super.key, required this.provider});

  final CatGardenProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // setBounds solo se llama cuando cambia el tamaño — no en cada tick.
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

                // ── Capa 0: Arena procedural ────────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: ZenGardenPainter(tier: tier),
                  ),
                ),

                // ── Capa 1: Estanque (tier 3) ───────────────────────────────
                _decorLayer(
                  visible: tier >= 3,
                  children: [
                    _decor(_kPond, left: w * 0.02, top: h * 0.42, size: 175),
                  ],
                ),

                // ── Capa 2: Rocas (tier 1+) ─────────────────────────────────
                _decorLayer(
                  visible: tier >= 1,
                  children: [
                    _decor(_kRock1, left: w * 0.04, top: h * 0.54, size: 92),
                    _decor(_kRock2, left: w * 0.60, top: h * 0.28, size: 86),
                  ],
                ),

                // ── Capa 2: Arbustos, bonsai y linterna (tier 2+) ───────────
                _decorLayer(
                  visible: tier >= 2,
                  children: [
                    _decor(_kBonsai,  left: w * 0.16, top: h * 0.30, size: 88),
                    _decor(_kBush1,   left: w * 0.66, top: h * 0.52, size: 94),
                    _decor(_kBush2,   left: w * 0.04, top: h * 0.10, size: 88),
                    _decor(_kLantern, left: w * 0.43, top: h * 0.08, size: 58),
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
                // Los gatos que pasen por esa zona quedarán visualmente "bajo"
                // las ramas al estar en una capa inferior.
                _decorLayer(
                  visible: tier >= 3,
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: _img(_kSakura, 155),
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

  /// Capa de decoración con fundido animado al cambiar el [visible].
  /// Usa [StackFit.expand] para que los [Positioned] hijos usen las mismas
  /// coordenadas que el Stack padre.
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

  /// [Positioned] con [Image.asset] colocado desde coordenadas absolutas.
  static Positioned _decor(
    String asset, {
    required double left,
    required double top,
    required double size,
  }) {
    return Positioned(left: left, top: top, child: _img(asset, size));
  }

  /// Imagen pixel-art sin interpolación bilinear.
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

