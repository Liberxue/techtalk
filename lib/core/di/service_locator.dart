import '../../data/repositories/content_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/llm_service.dart';
import '../../domain/mock_llm_service.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';

/// Simple service locator (no external package needed).
///
/// Usage:
/// ```dart
/// final tts = ServiceLocator.I.get<TtsService>();
/// ```
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get I => _instance;
  ServiceLocator._();

  final Map<Type, dynamic> _services = {};

  /// Register a service instance by its type.
  void register<T>(T service) => _services[T] = service;

  /// Retrieve a previously registered service.
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw StateError('Service $T is not registered in ServiceLocator.');
    }
    return service as T;
  }

  /// Check whether a service of type [T] has been registered.
  bool has<T>() => _services.containsKey(T);

  /// Initialise and register all core services.
  ///
  /// Call once during app startup (e.g. in `main()`).
  Future<void> init() async {
    // Core services
    register<TtsService>(TtsService());
    register<SttService>(SttService());

    // LLM — default to offline mock; swap to ClaudeLlmService when an API key
    // is available via `register<LlmService>(ClaudeLlmService(apiKey: ...))`.
    register<LlmService>(MockLlmService());

    // Repositories
    register<ContentRepository>(ContentRepository());
    register<LibraryRepository>(LibraryRepository());

    // Async initialisation
    await get<TtsService>().init();
    await get<SttService>().init();
  }
}
