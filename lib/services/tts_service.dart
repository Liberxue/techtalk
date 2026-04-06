import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _playing = false;
  String _language = 'en-US';
  final Completer<void> _initCompleter = Completer<void>();

  Future<void> init() async {
    await _tts.setVolume(0.95);
    await _tts.setLanguage(_language);

    // Await speak completion for proper sequencing
    await _tts.awaitSpeakCompletion(true);

    if (Platform.isIOS) {
      // Configure audio session for natural playback
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      await _selectBestVoice();
    }

    // Natural defaults
    await _tts.setSpeechRate(Platform.isIOS ? 0.46 : 0.42);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() => _playing = false);

    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  /// Select the most natural-sounding voice available.
  /// Priority: Neural/Premium > Enhanced > Default
  Future<void> _selectBestVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;

    final enVoices = voices.cast<Map>().where((v) {
      final locale = (v['locale'] ?? '').toString();
      return locale.startsWith('en');
    }).toList();

    if (enVoices.isEmpty) return;

    // Score each voice by quality
    Map? bestVoice;
    int bestScore = -1;

    for (final v in enVoices) {
      final name = (v['name'] ?? '').toString().toLowerCase();
      final quality = (v['quality'] ?? '').toString().toLowerCase();
      int score = 0;

      // Neural voices (iOS 17+) are the most natural
      if (name.contains('neural') || quality.contains('neural')) {
        score = 100;
      }
      // Premium voices
      else if (name.contains('premium') || quality.contains('premium')) {
        score = 80;
      }
      // Enhanced voices
      else if (name.contains('enhanced') || quality.contains('enhanced')) {
        score = 60;
      }
      // Prefer en-US over other english locales
      final locale = (v['locale'] ?? '').toString();
      if (locale == 'en-US') score += 5;

      // Prefer female voices (generally clearer for language learning)
      if (name.contains('samantha') ||
          name.contains('karen') ||
          name.contains('ava') ||
          name.contains('zoe') ||
          name.contains('allison')) {
        score += 3;
      }

      if (score > bestScore) {
        bestScore = score;
        bestVoice = v;
      }
    }

    if (bestVoice != null && bestScore > 0) {
      await _tts.setVoice({
        'name': bestVoice['name'].toString(),
        'locale': bestVoice['locale'].toString(),
      });
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _tts.setLanguage(lang);
    if (Platform.isIOS) {
      await _selectBestVoice();
    }
  }

  /// Speak a single word clearly — optimized for pronunciation learning.
  Future<void> speakWord(String word) async {
    if (_playing) {
      await _tts.stop();
      _playing = false;
      // Small gap so the engine resets
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _playing = true;

    // Slower rate for individual words — clear articulation
    await _tts.setSpeechRate(Platform.isIOS ? 0.38 : 0.32);
    await _tts.setPitch(1.0);
    await _tts.speak(word);

    // awaitSpeakCompletion handles timing; add minimal buffer
    await Future.delayed(const Duration(milliseconds: 150));
    _playing = false;

    // Restore sentence rate
    await _tts.setSpeechRate(Platform.isIOS ? 0.46 : 0.42);
  }

  /// Speak a full sentence at natural conversational pace.
  Future<void> speakSentence(String sentence) async {
    if (_playing) {
      await _tts.stop();
      _playing = false;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _playing = true;

    await _tts.setSpeechRate(Platform.isIOS ? 0.46 : 0.42);
    await _tts.setPitch(1.0);
    await _tts.speak(sentence);
    // Completion handled by awaitSpeakCompletion + completionHandler
  }

  Future<void> stop() async {
    await _tts.stop();
    _playing = false;
  }

  bool get isPlaying => _playing;

  void dispose() {
    _tts.stop();
  }
}
