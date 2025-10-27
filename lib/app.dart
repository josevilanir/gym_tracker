// lib/app.dart
// VERSÃO COM ONBOARDING INTEGRADO

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'features/onboarding/pages/onboarding_page.dart';

final _themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class GymApp extends StatefulWidget {
  const GymApp({super.key});

  @override
  State<GymApp> createState() => _GymAppState();
}

class _GymAppState extends State<GymApp> {
  bool? _showOnboarding; // null = loading, true = show, false = hide

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    
    if (mounted) {
      setState(() {
        _showOnboarding = !completed;
      });
    }
  }

  void _completeOnboarding() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    // Estado de loading
    if (_showOnboarding == null) {
      return MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Gym Tracker',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mostrar onboarding
    if (_showOnboarding!) {
      return MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: OnboardingPage(onComplete: _completeOnboarding),
      );
    }

    // App normal (já viu o onboarding)
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final themeMode = ref.watch(_themeModeProvider);

          return MaterialApp.router(
            title: 'Gym Tracker',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

/// Exponho um helper para alternar tema no app (usado em SettingsPage).
void toggleTheme(WidgetRef ref) {
  final current = ref.read(_themeModeProvider);
  ref.read(_themeModeProvider.notifier).state =
      current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}