import 'package:audioplayers/audioplayers.dart';

class GameSoundService {
  GameSoundService._();

  static final GameSoundService instance = GameSoundService._();

  final AudioPlayer _scratchPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _tickPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _finalPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  Future<AudioPool>? _scratchPool;
  DateTime? _lastScratchAt;

  Future<void> playScratch() async {
    final now = DateTime.now();
    if (_lastScratchAt != null &&
        now.difference(_lastScratchAt!).inMilliseconds < 120) {
      return;
    }
    _lastScratchAt = now;
    await _playScratch();
  }

  Future<void> playDiceTick() async {
    await _play(_tickPlayer, 'sounds/dice_tick.wav');
  }

  Future<void> playDiceFinal() async {
    await _play(_finalPlayer, 'sounds/dice_final.wav');
  }

  Future<void> _play(AudioPlayer player, String assetPath) async {
    try {
      await player.stop();
      await player.play(AssetSource(assetPath), volume: 0.75);
    } catch (_) {
      // Sound effects should never block the game flow.
    }
  }

  Future<void> _playScratch() async {
    try {
      final pool = await (_scratchPool ??= AudioPool.createFromAsset(
        path: 'sounds/scratch.wav',
        minPlayers: 2,
        maxPlayers: 4,
      ));
      await pool.start(volume: 0.55);
    } catch (_) {
      await _play(_scratchPlayer, 'sounds/scratch.wav');
    }
  }
}
