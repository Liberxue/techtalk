import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bloc/theme_cubit.dart';
import 'bloc/player_cubit.dart';
import 'core/di/service_locator.dart';
import 'screens/home_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/interview_screen.dart';
import 'screens/library_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/book_detail_screen.dart';
import 'models/audio_content.dart';
import 'widgets/app_shell.dart';

// Smooth slide + fade transition for page navigation
CustomTransitionPage<void> _smoothPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(
          currentRoute: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
            path: '/',
            pageBuilder: (_, state) =>
                _smoothPage(state, const HomeScreen())),
        GoRoute(
            path: '/library',
            pageBuilder: (_, state) =>
                _smoothPage(state, const LibraryScreen())),
        GoRoute(
            path: '/progress',
            pageBuilder: (_, state) =>
                _smoothPage(state, const ProgressScreen())),
        GoRoute(
            path: '/settings',
            pageBuilder: (_, state) =>
                _smoothPage(state, const SettingsScreen())),
      ],
    ),
    // Detail routes — full-screen, outside the shell
    GoRoute(
        path: '/practice',
        pageBuilder: (_, state) =>
            _smoothPage(state, const PracticeScreen())),
    GoRoute(
        path: '/interview',
        pageBuilder: (_, state) =>
            _smoothPage(state, const InterviewScreen())),
    GoRoute(
        path: '/book/:id',
        pageBuilder: (_, state) {
          final content = state.extra as AudioContent?;
          if (content == null) {
            return _smoothPage(state, const Scaffold(
              body: Center(child: Text('Book not found')),
            ));
          }
          return _smoothPage(state, BookDetailScreen(content: content));
        }),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Hive (persistence)
  try {
    await Hive.initFlutter();
    await Hive.openBox('settings');
    await Hive.openBox('library');
  } catch (e) {
    await Hive.initFlutter('techtalk_data');
    try {
      await Hive.openBox('settings');
      await Hive.openBox('library');
    } catch (_) {}
  }

  // 2. Service Locator (DI)
  await ServiceLocator.I.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => PlayerCubit()),
      ],
      child: const TechTalkApp(),
    ),
  );
}

class TechTalkApp extends StatelessWidget {
  const TechTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp.router(
          title: 'TechTalk',
          debugShowCheckedModeBanner: false,
          theme: themeState.theme,
          darkTheme: themeState.darkTheme,
          themeMode: themeState.flutterThemeMode,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOut,
          routerConfig: _router,
        );
      },
    );
  }
}
