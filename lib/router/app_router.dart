// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/workout/pages/today_page.dart';
import '../features/workout/pages/history_page.dart';
import '../features/exercise/pages/catalog_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/workout/pages/workout_detail_page.dart';
import '../features/workout/pages/workout_editor_page.dart';
import '../features/workout/pages/history_workout_detail_page.dart';


/// Rotas nomeadas
abstract class AppRoutes {
  static const shell = '/';
  static const today = '/today';
  static const history = '/history';
  static const catalog = '/catalog';
  static const settings = '/settings';

  static const workoutDetail = '/workout/:id';
  static const workoutNew = '/workout/new';
}

final router = GoRouter(
  initialLocation: AppRoutes.today,
  routes: [
    ShellRoute(
      builder: (context, state, child) => _NavShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.today,
          name: 'today',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TodayPage()),
        ),
        GoRoute(
          path: AppRoutes.history,
          name: 'history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HistoryPage()),
          routes: [
            // 👇 detalhe como child de /history
            GoRoute(
              name: 'history_workout_detail',
              path: 'workout/:id', // URL final: /history/workout/<id>
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return HistoryWorkoutDetailPage(workoutId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.catalog,
          name: 'catalog',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CatalogPage()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),

    // continua fora do Shell: edições/criações
    GoRoute(
      path: AppRoutes.workoutDetail,
      name: 'workout_detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return WorkoutDetailPage(workoutId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.workoutNew,
      name: 'workout_new',
      builder: (context, state) => const WorkoutEditorPage(),
    ),
  ],
);

class _NavShell extends StatefulWidget {
  const _NavShell({required this.child});
  final Widget child;

  @override
  State<_NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<_NavShell> {
  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.history)) return 1;
    if (location.startsWith(AppRoutes.catalog)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3;
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.today);
        break;
      case 1:
        context.go(AppRoutes.history);
        break;
      case 2:
        context.go(AppRoutes.catalog);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: SafeArea(child: widget.child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(i, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Config.',
          ),
        ],
      ),
    );
  }
}
