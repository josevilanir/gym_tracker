// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

final _themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class GymApp extends ConsumerWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(_themeModeProvider);

    return MaterialApp.router(
      title: 'Gym Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Exponho um helper para alternar tema no app (usado em SettingsPage).
void toggleTheme(WidgetRef ref) {
  final current = ref.read(_themeModeProvider);
  ref.read(_themeModeProvider.notifier).state =
      current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}
