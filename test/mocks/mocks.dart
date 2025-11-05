// test/mocks/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:gym_tracker/data/db/app_database.dart';
import 'package:gym_tracker/data/repositories/workout_repository.dart';

/// Gerar mocks APENAS para as classes que EXISTEM no projeto
@GenerateMocks([
  AppDatabase,
  WorkoutRepository,
])
void main() {}