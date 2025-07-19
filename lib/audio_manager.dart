import 'package:just_audio/just_audio.dart';
import 'extension.dart';

// =============================
// AudioManager: Audio management using just_audio
// Handles playback and stop for sound effects
// =============================
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

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      if (_audioPlayer!.playing) {
        await _audioPlayer!.stop();
        'Stop audio: ${_audioPlayer!.playerState}'.debugPrint();
      }
    } catch (e) {
      'Stop audio failed: $e'.debugPrint();
    }
  }

} 