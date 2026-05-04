import 'package:flutter/foundation.dart';

/// Skin/raza del gato. Mapea directamente a las dos variantes de sprites del HTML original.
enum CatSkin { spotted, bw }

/// Dirección a la que mira el gato. Coincide con los valores 'north'|'south'|'east'|'west'
/// usados como sufijo de clave en CAT_IMG y BW_IMG del juego original.
enum CatDirection { north, south, east, west }

/// Representa el estado completo de un gato en el jardín virtual.
///
/// Campos de posición y movimiento extraídos de la función [spawnCat] del HTML original.
/// Los campos [el] y [_lastSrc] (runtime DOM) no se incluyen; en Flutter se manejan
/// a nivel de widget.
///
/// Campos persistidos originalmente: x, y, skin (localStorage 'pixelcats_cats').
/// El resto son estado de simulación recalculado al cargar.
@immutable
class CatModel {
  const CatModel({
    required this.id,
    required this.x,
    required this.y,
    required this.skin,
    required this.direction,
    required this.isMoving,
    required this.isIdle,
    required this.speed,
    required this.velocityX,
    required this.velocityY,
    required this.stateTimer,
    required this.idleDuration,
    required this.walkDuration,
    required this.frameTimer,
    this.feedCount = 0,
    this.tier = 1,
  });

  /// Identificador único del gato (no existe en el HTML; añadido para Dart).
  final String id;

  /// Posición X en coordenadas de mundo (píxeles).
  final double x;

  /// Posición Y en coordenadas de mundo (píxeles).
  final double y;

  /// Variante visual del gato: manchado (spotted) o blanco-negro (bw).
  final CatSkin skin;

  /// Dirección a la que mira el gato, determina qué sprite se muestra.
  final CatDirection direction;

  /// [true] cuando el gato está caminando (usa sprites walk_*).
  final bool isMoving;

  /// [true] durante la fase de reposo; [false] durante la fase de caminata.
  final bool isIdle;

  /// Velocidad de desplazamiento en píxeles/segundo. Rango original: 55–85.
  final double speed;

  /// Componente X del vector de dirección de movimiento (−1 a 1 normalizado).
  final double velocityX;

  /// Componente Y del vector de dirección de movimiento (−1 a 1 normalizado).
  final double velocityY;

  /// Tiempo acumulado en el estado actual (segundos). Se reinicia al cambiar de estado.
  final double stateTimer;

  /// Duración de la fase idle actual (segundos). Rango original: 1.5–4.5.
  final double idleDuration;

  /// Duración de la fase walk actual (segundos). Rango original: 1.0–3.5.
  final double walkDuration;

  /// Acumulador para la cadencia de animación de frames (milisegundos).
  /// Threshold: 150 ms caminando, 300 ms en reposo.
  final double frameTimer;

  /// Veces que el gato ha sido alimentado en el tier actual. Rango: 0–2.
  /// Al llegar a 3 se sube de tier y se reinicia a 0.
  final int feedCount;

  /// Nivel de evolución del gato (1–3). Sube al acumular 3 feeds en el mismo tier.
  final int tier;

  // ── Constructores de fábrica ────────────────────────────────────────────

  /// Crea un gato con valores de simulación por defecto, listo para ser spawneado.
  factory CatModel.spawn({
    required String id,
    required double x,
    required double y,
    CatSkin skin = CatSkin.spotted,
    CatDirection direction = CatDirection.south,
    double speed = 70,
    double idleDuration = 3.0,
    double walkDuration = 2.0,
    int feedCount = 0,
    int tier = 1,
  }) {
    return CatModel(
      id: id,
      x: x,
      y: y,
      skin: skin,
      direction: direction,
      isMoving: false,
      isIdle: true,
      speed: speed,
      velocityX: 0,
      velocityY: 0,
      stateTimer: 0,
      idleDuration: idleDuration,
      walkDuration: walkDuration,
      frameTimer: 0,
      feedCount: feedCount,
      tier: tier,
    );
  }

  // ── Persistencia ────────────────────────────────────────────────────────

  /// Serializa los campos persistidos. feedCount y tier se incluyen para
  /// mantener el progreso de alimentación entre sesiones.
  Map<String, dynamic> toMap() => {
        'id': id,
        'x': x.truncate(),
        'y': y.truncate(),
        'skin': skin.name,
        'feedCount': feedCount,
        'tier': tier,
      };

  /// Reconstruye desde el formato persistido; el resto de campos usa defaults de spawn.
  /// feedCount y tier tienen fallback a 0/1 para compatibilidad con datos guardados
  /// antes de la funcionalidad de alimentación.
  factory CatModel.fromMap(Map<String, dynamic> map) {
    return CatModel.spawn(
      id: map['id'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      skin: CatSkin.values.byName((map['skin'] as String?) ?? 'spotted'),
      feedCount: (map['feedCount'] as int?) ?? 0,
      tier: (map['tier'] as int?) ?? 1,
    );
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  CatModel copyWith({
    String? id,
    double? x,
    double? y,
    CatSkin? skin,
    CatDirection? direction,
    bool? isMoving,
    bool? isIdle,
    double? speed,
    double? velocityX,
    double? velocityY,
    double? stateTimer,
    double? idleDuration,
    double? walkDuration,
    double? frameTimer,
    int? feedCount,
    int? tier,
  }) {
    return CatModel(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      skin: skin ?? this.skin,
      direction: direction ?? this.direction,
      isMoving: isMoving ?? this.isMoving,
      isIdle: isIdle ?? this.isIdle,
      speed: speed ?? this.speed,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      stateTimer: stateTimer ?? this.stateTimer,
      idleDuration: idleDuration ?? this.idleDuration,
      walkDuration: walkDuration ?? this.walkDuration,
      frameTimer: frameTimer ?? this.frameTimer,
      feedCount: feedCount ?? this.feedCount,
      tier: tier ?? this.tier,
    );
  }

  // ── Helpers de sprite ────────────────────────────────────────────────────

  /// Devuelve la clave de asset para el sprite actual, siguiendo la lógica de
  /// [getCatSrc] del HTML original.
  ///
  /// Ejemplo: 'assets/images/game/cats/spotted/walk_east.gif'
  String get spriteAssetPath {
    if (skin == CatSkin.bw) {
      if (isMoving) {
        return 'assets/images/game/cats/bw/bw_walk_${direction.name}.gif';
      }
      // BW solo tiene idle_north e idle_south (ver getCatSrc en HTML original)
      final idleDir = direction == CatDirection.north ? 'north' : 'south';
      return 'assets/images/game/cats/bw/bw_idle_$idleDir.gif';
    }
    final anim = isMoving ? 'walk' : 'idle';
    return 'assets/images/game/cats/spotted/${anim}_${direction.name}.gif';
  }

  /// Cadencia de frame en milisegundos (150 ms caminando, 300 ms en reposo).
  double get frameCadenceMs => isMoving ? 150.0 : 300.0;
}
