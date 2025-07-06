import 'package:audioplayers/audioplayers.dart';
import 'extension.dart';

// =============================
// AudioManager: Sound effect and loop audio management
// Handles playback and stop for sound effects and looped audio
// =============================
class AudioManager {
  final List<AudioPlayer> audioPlayers;

  static const audioPlayerNumber = 1;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());
  
  /// Get player state
  PlayerState playerState(int index) => audioPlayers[index].state;
  
  /// Get player title
  String playerTitle(int index) => "${["effectSound"][index]}Player";

  /// Play loop sound
  Future<void> playLoopSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource(asset));
    "Loop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  /// Play effect sound
  Future<void> playEffectSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(asset));
    "Play ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  /// Stop sound for a player
  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  /// Stop all players
  Future<void> stopAll() async {
    for (final player in audioPlayers) {
      try {
        if (player.state == PlayerState.playing) {
          await player.stop();
          "Stop all players".debugPrint();
        }
      } catch (_) {}
    }
  }
} 