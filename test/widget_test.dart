import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:techtalk/main.dart';
import 'package:techtalk/bloc/theme_cubit.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ThemeCubit(),
        child: const TechTalkApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TechTalk'), findsOneWidget);
  });
}
