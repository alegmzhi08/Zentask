import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat_model.dart';
import '../services/economy_service.dart';

/// Resultado de intentar alimentar a un gato.
enum FeedResult {
  /// El usuario no tenía suficientes ZenCoins.
  insufficientFunds,
  /// El gato fue alimentado correctamente (sin subir de tier).
  fed,
  /// El gato alcanzó 3 feeds y subió de tier.
  levelUp,
}

/// Controlador de estado del jardín de gatos.
///
/// Ciclo de vida esperado (gestionado por GatitosScreen):
///   1. [start]      — initState: arranca el timer y carga gatos guardados.
///   2. [setBounds]  — LayoutBuilder: comunica el tamaño disponible.
///   3. [dispose]    — State.dispose: cancela el timer.
class CatGardenProvider extends ChangeNotifier {
  static const double spriteSize = 48.0;
  static const int catCost = 50;
  static const int feedCost = 5;
  static const int _feedsPerTier = 3;
  static const int _tickIntervalMs = 16; // ~60 fps
  static const String _kCats = 'zt_garden_cats';

  final Random _rng = Random();
  final List<CatModel> _cats = [];

  Size _bounds = Size.zero;
  Timer? _timer;
  int _lastTickMs = 0;
  bool _initStarted = false;

  // DEMO MODE ONLY — vive únicamente en memoria, no toca SharedPreferences.
  bool isDemoMode = false;

  List<CatModel> get cats => List.unmodifiable(_cats);

  /// Tier visual del jardín según la cantidad de gatos.
  /// 1 → arena lisa · 2 → líneas · 3 → líneas + ripples + piedras.
  int get gardenTier {
    final n = _cats.length;
    if (n <= 3) return 1;
    if (n <= 7) return 2;
    return 3;
  }

  // ── Ciclo de vida ────────────────────────────────────────────────────────

  void start() {
    _lastTickMs = DateTime.now().millisecondsSinceEpoch;
    _timer ??= Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (_) => _tick(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  // ── Bounds ───────────────────────────────────────────────────────────────

  void setBounds(Size size) {
    if (_bounds == size) return;
    _bounds = size;

    if (!_initStarted) {
      _initStarted = true;
      _initializeCats(); // fire-and-forget; notifica al terminar
    } else if (_cats.isNotEmpty) {
      for (int i = 0; i < _cats.length; i++) {
        _cats[i] = _clampToBounds(_cats[i]);
      }
    }
  }

  // ── Compra de gatos ───────────────────────────────────────────────────────

  /// Intenta comprar un nuevo gato por [catCost] ZenCoins.
  /// Devuelve [true] si la compra fue exitosa, [false] si el saldo es insuficiente.
  Future<bool> buyCat() async {
    final success = await EconomyService.instance.spendCoins(catCost);
    if (!success) return false;

    final id = 'cat_${DateTime.now().microsecondsSinceEpoch}';
    final maxX = (_bounds.width - spriteSize).clamp(0.0, double.infinity);
    final maxY = (_bounds.height - spriteSize).clamp(0.0, double.infinity);

    _cats.add(CatModel.spawn(
      id: id,
      x: _rng.nextDouble() * maxX,
      y: _rng.nextDouble() * maxY,
      skin: _rng.nextBool() ? CatSkin.spotted : CatSkin.bw,
      speed: 55.0 + _rng.nextDouble() * 30.0,
      idleDuration: 1.5 + _rng.nextDouble() * 3.0,
      walkDuration: 1.0 + _rng.nextDouble() * 2.5,
    ));

    notifyListeners();
    await _persistCats();
    return true;
  }

  // DEMO MODE ONLY ─────────────────────────────────────────────────────────

  /// Activa el modo demo: puebla el jardín con 8 gatos de tiers variados y
  /// desactiva el costo de alimentación. No escribe en SharedPreferences.
  void enableDemoMode() {
    isDemoMode = true;
    _cats.clear();

    final w = _bounds.width;
    final h = _bounds.height;
    final maxX = (w - spriteSize).clamp(0.0, double.infinity);
    final maxY = (h - spriteSize).clamp(0.0, double.infinity);

    // 8 gatos → gardenTier 3; tiers individuales variados para mostrar progresión.
    const specs = <(double, double, CatSkin, int)>[
      (0.10, 0.15, CatSkin.spotted, 1),
      (0.50, 0.10, CatSkin.bw,      2),
      (0.80, 0.20, CatSkin.spotted, 3),
      (0.15, 0.55, CatSkin.bw,      1),
      (0.45, 0.60, CatSkin.spotted, 2),
      (0.75, 0.55, CatSkin.bw,      3),
      (0.30, 0.80, CatSkin.spotted, 2),
      (0.65, 0.80, CatSkin.bw,      1),
    ];

    for (int i = 0; i < specs.length; i++) {
      final (rx, ry, skin, tier) = specs[i];
      _cats.add(CatModel.spawn(
        id: 'demo_cat_$i',
        x: (w * rx).clamp(0.0, maxX),
        y: (h * ry).clamp(0.0, maxY),
        skin: skin,
        speed: 55.0 + _rng.nextDouble() * 30.0,
        idleDuration: 1.5 + _rng.nextDouble() * 3.0,
        walkDuration: 1.0 + _rng.nextDouble() * 2.5,
        tier: tier,
      ));
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// Alimenta al gato con [catId] por [feedCost] ZenCoins.
  ///
  /// Retorna [FeedResult.insufficientFunds] si el saldo es insuficiente.
  /// Retorna [FeedResult.levelUp] si el gato sube de tier tras acumular
  /// [_feedsPerTier] feeds. Retorna [FeedResult.fed] en caso normal.
  Future<FeedResult> feedCat(String catId) async {
    final i = _cats.indexWhere((c) => c.id == catId);
    if (i == -1) return FeedResult.fed;

    // DEMO MODE ONLY: sin costo, 1 feed = tier up.
    if (!isDemoMode) {
      final success = await EconomyService.instance.spendCoins(feedCost);
      if (!success) return FeedResult.insufficientFunds;
    }

    final cat = _cats[i];
    final threshold = isDemoMode ? 1 : _feedsPerTier;
    final newFeedCount = cat.feedCount + 1;

    if (newFeedCount >= threshold && cat.tier < 3) {
      _cats[i] = cat.copyWith(tier: cat.tier + 1, feedCount: 0);
      notifyListeners();
      if (!isDemoMode) await _persistCats();
      return FeedResult.levelUp;
    }

    _cats[i] = cat.copyWith(feedCount: newFeedCount);
    notifyListeners();
    if (!isDemoMode) await _persistCats();
    return FeedResult.fed;
  }

  // ── Simulación ───────────────────────────────────────────────────────────

  void _tick() {
    if (_bounds == Size.zero || _cats.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = ((now - _lastTickMs) / 1000.0).clamp(0.001, 0.05);
    _lastTickMs = now;

    for (int i = 0; i < _cats.length; i++) {
      _cats[i] = _step(_cats[i], dt);
    }
    notifyListeners();
  }

  CatModel _step(CatModel cat, double dt) {
    final timer = cat.stateTimer + dt;

    if (cat.isIdle) {
      if (timer < cat.idleDuration) {
        return cat.copyWith(stateTimer: timer);
      }
      final angle = _rng.nextDouble() * 2 * pi;
      final vx = cos(angle);
      final vy = sin(angle);
      return cat.copyWith(
        isIdle: false,
        isMoving: true,
        stateTimer: 0,
        velocityX: vx,
        velocityY: vy,
        direction: _dirFrom(vx, vy),
        walkDuration: 1.0 + _rng.nextDouble() * 2.5,
      );
    }

    final maxX = _bounds.width - spriteSize;
    final maxY = _bounds.height - spriteSize;
    double nx = cat.x + cat.velocityX * cat.speed * dt;
    double ny = cat.y + cat.velocityY * cat.speed * dt;
    double vx = cat.velocityX;
    double vy = cat.velocityY;

    if (nx < 0 || nx > maxX) { vx = -vx; nx = nx.clamp(0.0, maxX); }
    if (ny < 0 || ny > maxY) { vy = -vy; ny = ny.clamp(0.0, maxY); }

    if (timer >= cat.walkDuration) {
      return cat.copyWith(
        x: nx, y: ny, velocityX: vx, velocityY: vy,
        direction: _dirFrom(vx, vy),
        isIdle: true, isMoving: false,
        stateTimer: 0,
        idleDuration: 1.5 + _rng.nextDouble() * 3.0,
      );
    }

    return cat.copyWith(
      x: nx, y: ny, velocityX: vx, velocityY: vy,
      direction: _dirFrom(vx, vy),
      stateTimer: timer,
    );
  }

  // ── Persistencia ─────────────────────────────────────────────────────────

  Future<void> _initializeCats() async {
    final loaded = await _loadSavedCats();
    if (!loaded) {
      _spawnDefaults();
      await _persistCats();
    } else {
      for (int i = 0; i < _cats.length; i++) {
        _cats[i] = _clampToBounds(_cats[i]);
      }
    }
    notifyListeners();
  }

  /// Devuelve [true] si se cargaron gatos desde SharedPreferences.
  Future<bool> _loadSavedCats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCats);
      if (raw == null) return false;
      final list = jsonDecode(raw) as List<dynamic>;
      if (list.isEmpty) return false;
      for (final e in list) {
        _cats.add(CatModel.fromMap(e as Map<String, dynamic>));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistCats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCats,
        jsonEncode(_cats.map((c) => c.toMap()).toList()),
      );
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _spawnDefaults() {
    const skins = [CatSkin.spotted, CatSkin.bw, CatSkin.spotted];
    final cx = _bounds.width / 2;
    final cy = _bounds.height / 2;
    final maxX = (_bounds.width - spriteSize).clamp(0.0, double.infinity);
    final maxY = (_bounds.height - spriteSize).clamp(0.0, double.infinity);

    for (int i = 0; i < 3; i++) {
      _cats.add(CatModel.spawn(
        id: 'cat_default_$i',
        x: (cx + (i - 1) * 100.0).clamp(0.0, maxX),
        y: (cy + (i - 1) * 50.0).clamp(0.0, maxY),
        skin: skins[i],
        speed: 55.0 + _rng.nextDouble() * 30.0,
        idleDuration: 1.5 + _rng.nextDouble() * 3.0,
        walkDuration: 1.0 + _rng.nextDouble() * 2.5,
      ));
    }
  }

  CatModel _clampToBounds(CatModel cat) {
    final maxX = (_bounds.width - spriteSize).clamp(0.0, double.infinity);
    final maxY = (_bounds.height - spriteSize).clamp(0.0, double.infinity);
    return cat.copyWith(
      x: cat.x.clamp(0.0, maxX),
      y: cat.y.clamp(0.0, maxY),
    );
  }

  static CatDirection _dirFrom(double vx, double vy) {
    if (vx.abs() >= vy.abs()) {
      return vx >= 0 ? CatDirection.east : CatDirection.west;
    }
    return vy >= 0 ? CatDirection.south : CatDirection.north;
  }
}
