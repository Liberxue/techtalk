import 'package:speech_to_text/speech_to_text.dart';

typedef OnPartialResult = void Function(String text, bool isFinal);

class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  String? lastError;

  Future<bool> init() async {
    try {
      _initialized = await _stt.initialize(
        onError: (error) {
          lastError = error.errorMsg;
        },
        onStatus: (status) {},
      );
    } catch (e) {
      _initialized = false;
      lastError = e.toString();
    }
    return _initialized;
  }

  Future<void> startListening({
    required OnPartialResult onResult,
    String localeId = 'en_US',
  }) async {
    if (!_initialized) {
      final ok = await init();
      if (!ok) {
        throw Exception(lastError ?? 'Speech recognition unavailable');
      }
    }

    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      ),
      localeId: localeId,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
  bool get isAvailable => _initialized;

  void dispose() {
    _stt.stop();
  }
}
