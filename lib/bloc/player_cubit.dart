import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/audio_content.dart';

enum PlayState { idle, playing, paused }

class PlayerState {
  final AudioContent? content;
  final PlayState playState;
  final double speed;

  /// All sentences extracted from content, in order.
  final List<String> sentences;

  /// Index of the sentence currently being spoken.
  final int currentSentence;

  /// Character offsets within the current sentence for word highlighting.
  final int highlightStart;
  final int highlightEnd;

  const PlayerState({
    this.content,
    this.playState = PlayState.idle,
    this.speed = 1.0,
    this.sentences = const [],
    this.currentSentence = 0,
    this.highlightStart = -1,
    this.highlightEnd = -1,
  });

  PlayerState copyWith({
    AudioContent? content,
    PlayState? playState,
    double? speed,
    List<String>? sentences,
    int? currentSentence,
    int? highlightStart,
    int? highlightEnd,
  }) {
    return PlayerState(
      content: content ?? this.content,
      playState: playState ?? this.playState,
      speed: speed ?? this.speed,
      sentences: sentences ?? this.sentences,
      currentSentence: currentSentence ?? this.currentSentence,
      highlightStart: highlightStart ?? this.highlightStart,
      highlightEnd: highlightEnd ?? this.highlightEnd,
    );
  }

  bool get isPlaying => playState == PlayState.playing;
  bool get isPaused => playState == PlayState.paused;
  bool get isIdle => playState == PlayState.idle;
  bool get hasContent => content != null && sentences.isNotEmpty;

  double get progress {
    if (sentences.isEmpty) return 0;
    return currentSentence / sentences.length;
  }

  String get currentText =>
      currentSentence < sentences.length ? sentences[currentSentence] : '';
}

class PlayerCubit extends Cubit<PlayerState> {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String _currentUtterance = '';
  int _generation = 0;

  PlayerCubit() : super(const PlayerState());

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;

    await _tts.setVolume(0.95);
    await _tts.awaitSpeakCompletion(false);

    if (Platform.isIOS) {
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

    _tts.setProgressHandler((String text, int start, int end, String word) {
      if (!state.isPlaying) return;
      if (text != _currentUtterance) return;
      if (start < 0 || end > text.length) return;
      emit(state.copyWith(highlightStart: start, highlightEnd: end));
    });

    _tts.setCompletionHandler(_onSentenceComplete);
  }

  Future<void> _selectBestVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;
    Map? best;
    int bestScore = -1;
    for (final v in voices.cast<Map>()) {
      final name = (v['name'] ?? '').toString().toLowerCase();
      final quality = (v['quality'] ?? '').toString().toLowerCase();
      final locale = (v['locale'] ?? '').toString();
      if (!locale.startsWith('en')) continue;
      int score = 0;
      if (name.contains('neural') || quality.contains('neural')) {
        score = 100;
      } else if (name.contains('premium') || quality.contains('premium')) {
        score = 80;
      } else if (name.contains('enhanced') || quality.contains('enhanced')) {
        score = 60;
      }
      if (locale == 'en-US') score += 5;
      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }
    if (best != null && bestScore > 0) {
      await _tts.setVoice({
        'name': best['name'].toString(),
        'locale': best['locale'].toString(),
      });
    }
  }

  /// Split content into sentences for lyrics-mode display.
  static List<String> _extractSentences(AudioContent content) {
    final result = <String>[];
    for (final para in content.paragraphs) {
      // Split on sentence boundaries: . ! ? followed by space or end
      final raw = para.split(RegExp(r'(?<=[.!?])\s+'));
      for (final s in raw) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty) result.add(trimmed);
      }
    }
    return result;
  }

  // ── Public API ──

  Future<void> play(AudioContent content, {int fromSentence = 0}) async {
    await _ensureInit();
    await _safeStop();

    final sentences = _extractSentences(content);

    emit(PlayerState(
      content: content,
      playState: PlayState.playing,
      speed: state.speed,
      sentences: sentences,
      currentSentence: fromSentence.clamp(0, sentences.length - 1),
    ));

    await _speakCurrent();
  }

  Future<void> resume() async {
    if (!state.isPaused || !state.hasContent) return;
    emit(state.copyWith(playState: PlayState.playing));
    await _speakCurrent();
  }

  Future<void> pause() async {
    await _safeStop();
    emit(state.copyWith(
      playState: PlayState.paused,
      highlightStart: -1, highlightEnd: -1,
    ));
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else if (state.isPaused) {
      await resume();
    }
  }

  Future<void> stop() async {
    await _safeStop();
    emit(const PlayerState());
  }

  Future<void> next() async {
    if (!state.hasContent) return;
    await _safeStop();
    final nextIdx = state.currentSentence + 1;
    if (nextIdx >= state.sentences.length) {
      emit(state.copyWith(
        playState: PlayState.idle, currentSentence: 0,
        highlightStart: -1, highlightEnd: -1,
      ));
      return;
    }
    emit(state.copyWith(
      currentSentence: nextIdx, playState: PlayState.playing,
      highlightStart: -1, highlightEnd: -1,
    ));
    await _speakCurrent();
  }

  Future<void> previous() async {
    if (!state.hasContent) return;
    await _safeStop();
    final prevIdx = (state.currentSentence - 1).clamp(0, state.sentences.length - 1);
    emit(state.copyWith(
      currentSentence: prevIdx, playState: PlayState.playing,
      highlightStart: -1, highlightEnd: -1,
    ));
    await _speakCurrent();
  }

  Future<void> jumpTo(int sentenceIndex) async {
    if (!state.hasContent) return;
    if (sentenceIndex < 0 || sentenceIndex >= state.sentences.length) return;
    await _safeStop();
    emit(state.copyWith(
      currentSentence: sentenceIndex, playState: PlayState.playing,
      highlightStart: -1, highlightEnd: -1,
    ));
    await _speakCurrent();
  }

  Future<void> setSpeed(double speed) async {
    final wasPlaying = state.isPlaying;
    if (wasPlaying) await _safeStop();
    emit(state.copyWith(
      speed: speed, highlightStart: -1, highlightEnd: -1,
      playState: wasPlaying ? PlayState.playing : state.playState,
    ));
    if (wasPlaying) await _speakCurrent();
  }

  // ── Internal ──

  Future<void> _safeStop() async {
    _generation++;
    _currentUtterance = '';
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 80));
  }

  Future<void> _speakCurrent() async {
    if (!state.hasContent || !state.isPlaying) return;

    final sentence = state.sentences[state.currentSentence];
    final gen = ++_generation;
    _currentUtterance = sentence;

    final rate = Platform.isIOS
        ? (0.46 * state.speed).clamp(0.25, 0.7)
        : (0.42 * state.speed).clamp(0.2, 0.65);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(1.0);

    emit(state.copyWith(highlightStart: -1, highlightEnd: -1));
    await _tts.speak(sentence);

    if (gen != _generation) return;
  }

  void _onSentenceComplete() {
    if (!state.isPlaying || !state.hasContent) return;

    final nextIdx = state.currentSentence + 1;
    if (nextIdx >= state.sentences.length) {
      _currentUtterance = '';
      emit(state.copyWith(
        playState: PlayState.idle, currentSentence: 0,
        highlightStart: -1, highlightEnd: -1,
      ));
      return;
    }

    emit(state.copyWith(
      currentSentence: nextIdx,
      highlightStart: -1, highlightEnd: -1,
    ));
    _speakCurrent();
  }

  @override
  Future<void> close() async {
    _generation++;
    _currentUtterance = '';
    await _tts.stop();
    return super.close();
  }
}
