import 'package:go_router/go_router.dart';

import '../features/workout/pages/today_page.dart';
import '../features/workout/pages/workout_editor_page.dart';
import '../features/workout/pages/history_page.dart';
import '../features/workout/pages/workout_detail_page.dart';   // rota oficial
import '../features/exercise/pages/catalog_page.dart';         // catálogo

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'today',
        builder: (context, state) => const TodayPage(),
      ),
      GoRoute(
        path: '/workout/new',
        name: 'workout_new',
        builder: (context, state) => const WorkoutEditorPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      // ✅ nova/única rota para tela do treino
      GoRoute(
        path: '/workout/:id',
        name: 'workout_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WorkoutDetailPage(workoutId: id);
        },
      ),
      GoRoute(
        path: '/catalog',
        name: 'catalog',
        builder: (context, state) => const CatalogPage(),
      ),
    ],
  );
}
