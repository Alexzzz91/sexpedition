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

  DateTime? _lastScratchAt;

  Future<void> playScratch() async {
    final now = DateTime.now();
    if (_lastScratchAt != null &&
        now.difference(_lastScratchAt!).inMilliseconds < 120) {
      return;
    }
    _lastScratchAt = now;
    await _play(_scratchPlayer, 'sounds/scratch.wav');
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
}
