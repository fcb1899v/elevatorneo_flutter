import 'package:just_audio/just_audio.dart';
import 'extension.dart';

// ===== AudioManager: sound effect playback and stop via just_audio =====
class AudioManager {
  AudioPlayer? _audioPlayer;

  /// Initialize audio player
  Future<void> _initializePlayer() async => _audioPlayer ??= AudioPlayer();

  /// Play effect sound
  Future<void> playEffectSound({
    required String asset,
    required double volume,
  }) async {
    try {
      await _initializePlayer();
      if (_audioPlayer == null) {
        'Audio player is null'.debugPrint();
        return;
      }
      if (_audioPlayer!.playing) await _audioPlayer!.stop();
      await _audioPlayer!.setVolume(volume);
      await _audioPlayer!.setAsset(asset);
      await _audioPlayer!.play();
      'Play $asset: ${_audioPlayer!.playerState}'.debugPrint();
    } catch (e) {
      'Play sound failed for $asset: $e'.debugPrint();
    }
  }

  /// Stop audio playback; safe before any sound has created the player
  Future<void> stopAudio() async {
    final player = _audioPlayer;
    if (player == null) return;
    try {
      if (player.playing) {
        await player.stop();
        'Stop audio: ${player.playerState}'.debugPrint();
      }
    } catch (e) {
      'Stop audio failed: $e'.debugPrint();
    }
  }
} 