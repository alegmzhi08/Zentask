import 'package:audioplayers/audioplayers.dart';

/// Servicio de efectos de sonido del jardín zen.
///
/// Patrón idéntico a los demás servicios del proyecto (singleton con
/// constructor privado). No requiere [init] — los [AudioPlayer] están listos
/// desde la construcción.
///
/// Cada método tiene un throttle independiente para evitar saturación si el
/// usuario dispara la misma acción varias veces en rápida sucesión.
///
/// Uso:
/// ```dart
/// await AudioService.instance.playPetSound();     // tap en un gato
/// await AudioService.instance.playFeedSound();    // recompensa / compra
/// await AudioService.instance.playLevelUpSound(); // subida de tier
/// ```
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();
  factory AudioService() => instance;

  // ── Throttle ──────────────────────────────────────────────────────────────
  // Tiempo mínimo (ms) entre dos reproducciones del mismo sonido.
  // Evita superposición caótica sin bloquear sonidos de tipos distintos.
  static const int _throttleMs = 500;

  // ── Paths de assets ───────────────────────────────────────────────────────
  // Rutas relativas al prefijo `assets/` declarado en pubspec.yaml.
  // Si renombras los archivos, actualiza solo estas constantes.
  static const String _sPet     = 'images/game/cats/MeowsAudio/Gato_1.wav';
  static const String _sFeed    = 'images/game/cats/MeowsAudio/Gato_2.wav';
  static const String _sLevelUp = 'images/game/cats/MeowsAudio/Gato_3.wav';

  // ── Players independientes ────────────────────────────────────────────────
  // Un player por sonido para que distintos efectos puedan sonar en paralelo
  // (p. ej. comprar un gato puede disparar feed + levelUp simultáneamente).
  final AudioPlayer _petPlayer     = AudioPlayer();
  final AudioPlayer _feedPlayer    = AudioPlayer();
  final AudioPlayer _levelUpPlayer = AudioPlayer();

  // ── Marcas de tiempo para throttle ───────────────────────────────────────
  int _lastPetMs     = 0;
  int _lastFeedMs    = 0;
  int _lastLevelUpMs = 0;

  // ── API pública ───────────────────────────────────────────────────────────

  /// Acción: tap básico / acariciar un gato.
  Future<void> playPetSound() async {
    if (!_canPlay(_lastPetMs)) return;
    _lastPetMs = _nowMs();
    await _safePlay(_petPlayer, _sPet);
  }

  /// Acción: recompensa / compra de un nuevo gato.
  Future<void> playFeedSound() async {
    if (!_canPlay(_lastFeedMs)) return;
    _lastFeedMs = _nowMs();
    await _safePlay(_feedPlayer, _sFeed);
  }

  /// Acción: subida de tier o interacción especial.
  Future<void> playLevelUpSound() async {
    if (!_canPlay(_lastLevelUpMs)) return;
    _lastLevelUpMs = _nowMs();
    await _safePlay(_levelUpPlayer, _sLevelUp);
  }

  /// Libera los recursos de audio. Llamar solo al cerrar la app.
  Future<void> dispose() async {
    await Future.wait([
      _petPlayer.dispose(),
      _feedPlayer.dispose(),
      _levelUpPlayer.dispose(),
    ]);
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  bool _canPlay(int lastMs) => _nowMs() - lastMs >= _throttleMs;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  /// Reproduce [asset] en [player] ignorando errores de plataforma.
  /// Los errores (p. ej. audio bloqueado en segundo plano) no deben romper
  /// el flujo de la app.
  Future<void> _safePlay(AudioPlayer player, String asset) async {
    try {
      await player.play(AssetSource(asset));
    } catch (_) {}
  }
}
