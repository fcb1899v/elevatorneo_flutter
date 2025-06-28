import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'extension.dart';

/// For TTS
class TtsManager {

  final BuildContext context;
  TtsManager({required this.context});

  final FlutterTts flutterTts = FlutterTts();

  Future<void> setTtsVoice() async {
    final voices = await flutterTts.getVoices;
    List<dynamic> localFemaleVoices = (Platform.isIOS || Platform.isMacOS) ? voices.where((voice) {
      final isLocalMatch = voice['locale'].toString().contains(context.ttsLocale());
      final isFemale = voice['gender'].toString().contains('female');
      return isLocalMatch && isFemale;
    }).toList(): [];
    "localFemaleVoices: $localFemaleVoices".debugPrint();
    if (context.mounted) {
      final voiceName = (localFemaleVoices.isNotEmpty) ? localFemaleVoices[0]['name']: context.defaultVoiceName();
      final voiceLocale = (localFemaleVoices.isNotEmpty) ? localFemaleVoices[0]['locale']: context.ttsLocale();
      final result = await flutterTts.setVoice({'name': voiceName, 'locale': voiceLocale,});
      "setVoice: $voiceName, result: $result".debugPrint();
    }
  }

  Future<void> speakText(String text, bool isSoundOn) async {
    if (isSoundOn) {
      await flutterTts.stop();
      await flutterTts.speak(text);
      text.debugPrint();
    }
  }

  Future<void> stopTts() async {
    await flutterTts.stop();
    "Stop TTS".debugPrint();
  }

  Future<void> initTts() async {
    await flutterTts.setSharedInstance(true);
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ]
    );
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.awaitSynthCompletion(true);
    if (context.mounted) await flutterTts.setLanguage(context.lang());
    if (context.mounted) await flutterTts.isLanguageAvailable(context.lang());
    if (context.mounted) await setTtsVoice();
    await flutterTts.setVolume(1);
    await flutterTts.setSpeechRate(0.5);
    if (context.mounted) speakText(context.pushNumber(), true);
  }
}

/// For Audio
class AudioManager {

  final List<AudioPlayer> audioPlayers;

  static const audioPlayerNumber = 1;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());
  PlayerState playerState(int index) => audioPlayers[index].state;
  String playerTitle(int index) => "${["warning", "left train", "right train", "emergency", "effectSound"][index]}Player";

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

  Future<void> playEffectSound({
    required int index,
    required String asset,
    required double volume,
  }) async {
    final player = audioPlayers[index];
    await player.setVolume(volume);
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(asset));
    "Play effect sound: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

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