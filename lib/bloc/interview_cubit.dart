import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/service_locator.dart';
import '../domain/llm_service.dart';
import '../models/interview_scenario.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

// ── State ──

class InterviewMessage {
  final String role; // interviewer, you, feedback, summary
  final String text;
  final int? score;
  final String? correct;
  final String? improve;
  final String? nativeAlt;

  const InterviewMessage({
    required this.role,
    required this.text,
    this.score,
    this.correct,
    this.improve,
    this.nativeAlt,
  });
}

class InterviewState {
  final InterviewScenario scenario;
  final int currentTurn;
  final List<InterviewMessage> messages;
  final bool started;
  final bool isTyping;
  final bool isThinking;
  final bool isRecording;
  final bool awaitingAnswer;
  final String partialText;
  final String language;

  const InterviewState({
    required this.scenario,
    this.currentTurn = 0,
    this.messages = const [],
    this.started = false,
    this.isTyping = false,
    this.isThinking = false,
    this.isRecording = false,
    this.awaitingAnswer = false,
    this.partialText = '',
    this.language = 'EN',
  });

  InterviewState copyWith({
    InterviewScenario? scenario,
    int? currentTurn,
    List<InterviewMessage>? messages,
    bool? started,
    bool? isTyping,
    bool? isThinking,
    bool? isRecording,
    bool? awaitingAnswer,
    String? partialText,
    String? language,
  }) {
    return InterviewState(
      scenario: scenario ?? this.scenario,
      currentTurn: currentTurn ?? this.currentTurn,
      messages: messages ?? this.messages,
      started: started ?? this.started,
      isTyping: isTyping ?? this.isTyping,
      isThinking: isThinking ?? this.isThinking,
      isRecording: isRecording ?? this.isRecording,
      awaitingAnswer: awaitingAnswer ?? this.awaitingAnswer,
      partialText: partialText ?? this.partialText,
      language: language ?? this.language,
    );
  }

  bool get isComplete => currentTurn >= scenario.turns.length;
}

// ── Cubit ──

class InterviewCubit extends Cubit<InterviewState> {
  final TtsService _tts = ServiceLocator.I.get<TtsService>();
  final SttService _stt = ServiceLocator.I.get<SttService>();
  final LlmService _llm = ServiceLocator.I.get<LlmService>();

  bool _askingInProgress = false;

  InterviewCubit()
      : super(InterviewState(scenario: interviewScenarios[0]));

  // ── Public API ──

  void setScenario(InterviewScenario scenario) {
    emit(InterviewState(scenario: scenario));
    _askingInProgress = false;
  }

  void setLanguage(String lang) {
    emit(state.copyWith(language: lang));
  }

  Future<void> startInterview() async {
    _askingInProgress = false;
    emit(state.copyWith(
      started: true,
      currentTurn: 0,
      messages: [],
      awaitingAnswer: false,
    ));
    await askQuestion();
  }

  Future<void> askQuestion() async {
    if (_askingInProgress) return;
    if (state.currentTurn >= state.scenario.turns.length) {
      _showSummary();
      return;
    }

    _askingInProgress = true;
    final turnIndex = state.currentTurn;
    final question = state.scenario.turns[turnIndex].question;
    final words = question.split(RegExp(r'\s+'));

    // Add empty message for typewriter effect
    final msgIndex = state.messages.length;
    final msgs = List<InterviewMessage>.from(state.messages)
      ..add(const InterviewMessage(role: 'interviewer', text: ''));
    emit(state.copyWith(messages: msgs, isTyping: true));

    // Typewriter animation — emit word by word
    final buffer = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      if (state.currentTurn != turnIndex) break;
      if (i > 0) buffer.write(' ');
      buffer.write(words[i]);
      final updated = List<InterviewMessage>.from(state.messages);
      updated[msgIndex] = InterviewMessage(
        role: 'interviewer',
        text: buffer.toString(),
      );
      emit(state.copyWith(messages: updated));
      await Future.delayed(const Duration(milliseconds: 55));
    }

    if (state.currentTurn != turnIndex) {
      _askingInProgress = false;
      return;
    }

    // Finalize with full text
    final finalMsgs = List<InterviewMessage>.from(state.messages);
    finalMsgs[msgIndex] = InterviewMessage(role: 'interviewer', text: question);
    emit(state.copyWith(
      messages: finalMsgs,
      isTyping: false,
      awaitingAnswer: true,
    ));
    _askingInProgress = false;

    _tts.speakSentence(question);
  }

  Future<void> startRecording() async {
    if (state.isTyping || !state.awaitingAnswer) return;

    emit(state.copyWith(isRecording: true, partialText: ''));

    try {
      await _stt.startListening(
        onResult: (text, isFinal) {
          emit(state.copyWith(partialText: text));
          if (isFinal) stopRecording(text);
        },
        localeId: _localeForLang(state.language),
      );
    } catch (_) {
      emit(state.copyWith(isRecording: false));
    }
  }

  Future<void> stopRecording([String? finalText]) async {
    await _stt.stopListening();
    final text = finalText ?? state.partialText;
    if (text.trim().isEmpty) {
      emit(state.copyWith(isRecording: false));
      return;
    }
    emit(state.copyWith(isRecording: false, partialText: ''));
    await submitAnswer(text);
  }

  Future<void> submitAnswer(String answer) async {
    if (!state.awaitingAnswer) return;

    final msgs = List<InterviewMessage>.from(state.messages)
      ..add(InterviewMessage(role: 'you', text: answer));
    emit(state.copyWith(
      messages: msgs,
      awaitingAnswer: false,
      isThinking: true,
    ));

    // Use LLM service for feedback (Strategy pattern)
    final turn = state.scenario.turns[state.currentTurn];
    final feedback = await _llm.generateFeedback(
      question: turn.question,
      userAnswer: answer,
      keyPhrases: turn.keyPhrases,
      idealAnswer: turn.idealAnswer,
    );

    final feedbackMsgs = List<InterviewMessage>.from(state.messages)
      ..add(InterviewMessage(
        role: 'feedback',
        text: '',
        score: feedback.score,
        correct: feedback.correct,
        improve: feedback.improve,
        nativeAlt: feedback.nativeAlt,
      ));

    emit(state.copyWith(
      messages: feedbackMsgs,
      isThinking: false,
      currentTurn: state.currentTurn + 1,
    ));

    // Next question after pause
    await Future.delayed(const Duration(milliseconds: 1500));
    if (state.currentTurn < state.scenario.turns.length) {
      await askQuestion();
    } else {
      _showSummary();
    }
  }

  void speakWord(String word) => _tts.speakWord(word);
  void speakSentence(String text) => _tts.speakSentence(text);
  void stopTts() => _tts.stop();

  void reset() {
    _askingInProgress = false;
    emit(InterviewState(scenario: state.scenario));
  }

  // ── Private ──

  void _showSummary() {
    final feedbacks = state.messages.where((m) => m.role == 'feedback').toList();
    if (feedbacks.isEmpty) return;

    final avgScore = feedbacks
        .map((f) => f.score ?? 0)
        .reduce((a, b) => a + b) ~/
        feedbacks.length;

    final msgs = List<InterviewMessage>.from(state.messages)
      ..add(InterviewMessage(
        role: 'summary',
        text: 'interview complete',
        score: avgScore,
      ));
    emit(state.copyWith(messages: msgs, awaitingAnswer: false));
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
    _tts.stop();
    _stt.dispose();
    return super.close();
  }
}
