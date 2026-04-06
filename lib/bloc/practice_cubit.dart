import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/service_locator.dart';
import '../domain/llm_service.dart';
import '../models/word_result.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/word_matcher.dart';

// ── State ──

enum PracticePhase { before, recording, result }

class PracticeState {
  final PracticePhase phase;
  final List<String> sentences;
  final int currentIndex;
  final List<WordResult> words;
  final int score;
  final double amplitude;
  final String? wrongWordFlash;
  final String? errorText;
  final bool permissionGranted;
  final String language;

  const PracticeState({
    this.phase = PracticePhase.before,
    this.sentences = const [],
    this.currentIndex = 0,
    this.words = const [],
    this.score = 0,
    this.amplitude = 0.0,
    this.wrongWordFlash,
    this.errorText,
    this.permissionGranted = false,
    this.language = 'EN',
  });

  PracticeState copyWith({
    PracticePhase? phase,
    List<String>? sentences,
    int? currentIndex,
    List<WordResult>? words,
    int? score,
    double? amplitude,
    String? wrongWordFlash,
    String? errorText,
    bool? permissionGranted,
    String? language,
    bool clearWrongWord = false,
    bool clearError = false,
  }) {
    return PracticeState(
      phase: phase ?? this.phase,
      sentences: sentences ?? this.sentences,
      currentIndex: currentIndex ?? this.currentIndex,
      words: words ?? this.words,
      score: score ?? this.score,
      amplitude: amplitude ?? this.amplitude,
      wrongWordFlash: clearWrongWord ? null : (wrongWordFlash ?? this.wrongWordFlash),
      errorText: clearError ? null : (errorText ?? this.errorText),
      permissionGranted: permissionGranted ?? this.permissionGranted,
      language: language ?? this.language,
    );
  }

  String get currentSentence =>
      currentIndex < sentences.length ? sentences[currentIndex] : '';

  int get totalSentences => sentences.length;
}

// ── Cubit ──

class PracticeCubit extends Cubit<PracticeState> {
  final TtsService _tts = ServiceLocator.I.get<TtsService>();
  final SttService _stt = ServiceLocator.I.get<SttService>();
  // ignore: unused_field — reserved for LLM pronunciation tips
  final LlmService _llm = ServiceLocator.I.get<LlmService>();

  Timer? _decayTimer;
  Timer? _flashTimer;
  int _lastWordCount = 0;
  bool _hasSpoken = false;

  PracticeCubit() : super(const PracticeState(
    sentences: [
      'This introduces a breaking change',
      'We need to reduce the latency',
      'The throughput is not sufficient',
      'Consider using an idempotent operation',
      'This requires a distributed consensus',
    ],
  )) {
    _initWords();
    _checkPermission();
  }

  void _initWords() {
    final words = state.currentSentence
        .split(RegExp(r'\s+'))
        .map((w) => WordResult(target: w))
        .toList();
    emit(state.copyWith(words: words));
  }

  Future<void> _checkPermission() async {
    final ok = await _stt.init();
    emit(state.copyWith(permissionGranted: ok));
  }

  // ── Actions ──

  void setLanguage(String lang) {
    emit(state.copyWith(language: lang));
  }

  Future<void> speakWord(String word) async {
    await _tts.speakWord(word);
  }

  Future<void> startRecording() async {
    if (!state.permissionGranted) {
      emit(state.copyWith(errorText: 'microphone permission required'));
      final ok = await _stt.init();
      emit(state.copyWith(permissionGranted: ok, clearError: ok));
      if (!ok) return;
    }

    _lastWordCount = 0;
    _hasSpoken = false;

    final words = state.currentSentence
        .split(RegExp(r'\s+'))
        .map((w) => WordResult(target: w))
        .toList();
    if (words.isNotEmpty) words[0].state = WordState.current;

    emit(state.copyWith(
      phase: PracticePhase.recording,
      words: words,
      amplitude: 0.0,
      clearError: true,
      clearWrongWord: true,
    ));

    _startAmplitudeDecay();

    try {
      await _stt.startListening(
        onResult: (text, isFinal) {
          _processResult(text);
          if (isFinal && _hasSpoken) finishRecording();
        },
        localeId: _localeForLang(state.language),
      );
    } catch (e) {
      emit(state.copyWith(
        phase: PracticePhase.before,
        errorText: 'could not start recording',
      ));
    }
  }

  void _processResult(String spoken) {
    if (spoken.trim().isEmpty) return;

    final results = WordMatcher.compare(state.currentSentence, spoken);
    final currentWordCount =
        spoken.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final newWords = currentWordCount - _lastWordCount;
    _lastWordCount = currentWordCount;

    if (currentWordCount > 0) _hasSpoken = true;

    final words = List<WordResult>.from(state.words);
    double amplitude = state.amplitude;

    if (newWords > 0) {
      amplitude = (0.5 + newWords * 0.25).clamp(0.3, 1.0);
    }

    for (var i = 0; i < results.length && i < words.length; i++) {
      if (results[i].spokenWord != null) {
        final wasUnspoken =
            words[i].state == WordState.unspoken || words[i].state == WordState.current;
        words[i].state = results[i].isCorrect ? WordState.correct : WordState.wrong;
        words[i].similarity = results[i].similarity;
        words[i].spoken = results[i].spokenWord;

        if (!results[i].isCorrect && wasUnspoken) {
          _tts.speakWord(words[i].target);
          _showWrongWordFlash(words[i].target);
        }
      }
    }

    final spokenCount = results.where((r) => r.spokenWord != null).length;
    for (var i = 0; i < words.length; i++) {
      if (i >= spokenCount && words[i].state == WordState.unspoken) {
        words[i].state = WordState.current;
        break;
      }
    }

    emit(state.copyWith(words: words, amplitude: amplitude));
  }

  void finishRecording() {
    _stt.stopListening();
    _decayTimer?.cancel();

    if (!_hasSpoken) {
      _initWords();
      emit(state.copyWith(phase: PracticePhase.before, amplitude: 0.0));
      return;
    }

    final words = List<WordResult>.from(state.words);
    for (final w in words) {
      if (w.state == WordState.unspoken || w.state == WordState.current) {
        w.state = WordState.wrong;
      }
    }

    final correct = words.where((w) => w.state == WordState.correct).length;
    final score = ((correct / words.length) * 100).round();

    emit(state.copyWith(
      phase: PracticePhase.result,
      words: words,
      score: score,
      amplitude: 0.0,
      clearWrongWord: true,
    ));
  }

  void retry() {
    _initWords();
    emit(state.copyWith(
      phase: PracticePhase.before,
      score: 0,
      clearError: true,
    ));
  }

  void next() {
    final nextIdx = (state.currentIndex + 1) % state.sentences.length;
    emit(state.copyWith(
      currentIndex: nextIdx,
      phase: PracticePhase.before,
      score: 0,
      clearError: true,
    ));
    _initWords();
  }

  // ── Private helpers ──

  void _startAmplitudeDecay() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (state.phase != PracticePhase.recording) {
        _decayTimer?.cancel();
        return;
      }
      var a = state.amplitude * 0.82;
      if (a < 0.01) a = 0.0;
      emit(state.copyWith(amplitude: a));
    });
  }

  void _showWrongWordFlash(String word) {
    _flashTimer?.cancel();
    emit(state.copyWith(wrongWordFlash: word));
    _flashTimer = Timer(const Duration(milliseconds: 1500), () {
      emit(state.copyWith(clearWrongWord: true));
    });
  }

  String _localeForLang(String lang) {
    switch (lang) {
      case 'JP': return 'ja_JP';
      case 'KR': return 'ko_KR';
      case 'DE': return 'de_DE';
      default: return 'en_US';
    }
  }

  @override
  Future<void> close() {
    _decayTimer?.cancel();
    _flashTimer?.cancel();
    return super.close();
  }
}
