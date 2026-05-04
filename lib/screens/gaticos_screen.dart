import 'package:flutter/material.dart';
import '../logic/cat_garden_provider.dart';
import '../services/economy_service.dart';
import '../widgets/cat_garden_widget.dart';

class GaticosScreen extends StatefulWidget {
  const GaticosScreen({super.key});

  @override
  State<GaticosScreen> createState() => _GaticosScreenState();
}

class _GaticosScreenState extends State<GaticosScreen> {
  late final CatGardenProvider _gardenProvider;

  @override
  void initState() {
    super.initState();
    _gardenProvider = CatGardenProvider();
    _gardenProvider.start();
  }

  @override
  void dispose() {
    _gardenProvider.dispose();
    super.dispose();
  }

  // ── Gestos ocultos del fondo (solo demo) ─────────────────────────────────

  Future<void> _onGardenDoubleTap() async {
    await EconomyService.instance.addCoins(1000);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ El jardín florece... (+1000 ZenCoins)'),
        backgroundColor: Color(0xFF3A4A3E),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onGardenLongPress() {
    _gardenProvider.enableDemoMode();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎯 Modo demo activo — Gatos desbloqueados ✓'),
        backgroundColor: Color(0xFF3A4A3E),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onBuyCat() async {
    final success = await _gardenProvider.buyCat();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitas ${CatGardenProvider.catCost} 🐟 para adoptar un gato',
          ),
          backgroundColor: Color(0xFF5D4037),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Jardín Zen'),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: EconomyService.instance.balance,
            builder: (_, balance, __) => GestureDetector(
              // DEMO MODE ONLY — disparador oculto para presentaciones.
              onLongPress: _gardenProvider.enableDemoMode,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    '$balance 🐟',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: _onGardenDoubleTap,
        onLongPress: _onGardenLongPress,
        child: CatGardenWidget(provider: _gardenProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onBuyCat,
        backgroundColor: const Color(0xFF8DC49A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.pets),
        label: const Text('+ Gato  (${CatGardenProvider.catCost} 🐟)'),
      ),
    );
  }
}
