// test/integration/workout_repository_integration_test.dart
// Testes de INTEGRAÇÃO com banco de dados REAL (in-memory)
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/db/app_database.dart';
import 'package:gym_tracker/data/repositories/workout_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Extensão do AppDatabase para testes com banco in-memory
class TestAppDatabase extends AppDatabase {
  // ✅ Armazena o executor para não criar múltiplas instâncias
  final QueryExecutor _executor;
  
  TestAppDatabase._(this._executor) : super();
  
  factory TestAppDatabase.memory() {
    // Cria UMA única instância do NativeDatabase
    final executor = NativeDatabase.memory();
    return TestAppDatabase._(executor);
  }
  
  @override
  QueryExecutor get executor => _executor;
}

void main() {
  late AppDatabase db;
  late WorkoutRepository repository;
  
  setUp(() async {
    // Criar banco IN-MEMORY
    db = TestAppDatabase.memory();
    repository = WorkoutRepository(db);
    
    // Popular com exercícios padrão
    await repository.ensureSeed();
  });
  
  tearDown(() async {
    await db.close();
  });
  
  group('WorkoutRepository - Criação com DB Real', () {
    test('createWorkout deve criar e retornar ID válido', () async {
      final id = await repository.createWorkout(title: 'Treino A');
      
      expect(id, isNotEmpty);
      
      final workout = await repository.getWorkout(id);
      expect(workout, isNot(null));
      expect(workout!.title, 'Treino A');
      expect(workout.done, false);
    });
    
    test('createWorkout sem título deve funcionar', () async {
      final id = await repository.createWorkout();
      
      expect(id, isNotEmpty);
      
      final workout = await repository.getWorkout(id);
      expect(workout, isNot(null));
      expect(workout!.title, null);
    });
    
    test('createEmptyWorkoutNow deve criar workout ativo', () async {
      final id = await repository.createEmptyWorkoutNow(title: 'Treino B');
      
      expect(id, isNotEmpty);
      
      final workout = await repository.getWorkout(id);
      expect(workout, isNot(null));
      expect(workout!.title, 'Treino B');
      expect(workout.done, false);
    });
    
    test('createWorkoutAt deve criar com data específica', () async {
      final customDate = DateTime(2024, 1, 15, 10, 30);
      
      final id = await repository.createWorkoutAt(
        date: customDate,
        title: 'Treino Retroativo',
        done: true,
      );
      
      expect(id, isNotEmpty);
      
      final workout = await repository.getWorkout(id);
      expect(workout, isNot(null));
      expect(workout!.title, 'Treino Retroativo');
      expect(workout.done, true);
      
      final workoutDate = DateTime.fromMillisecondsSinceEpoch(workout.dateEpoch);
      expect(workoutDate.year, customDate.year);
      expect(workoutDate.month, customDate.month);
      expect(workoutDate.day, customDate.day);
      expect(workoutDate.hour, customDate.hour);
      expect(workoutDate.minute, customDate.minute);
    });
    
    test('múltiplos workouts devem ser listados', () async {
      await repository.createWorkout(title: 'Treino 1');
      await repository.createWorkout(title: 'Treino 2');
      await repository.createWorkout(title: 'Treino 3');
      
      final workouts = await repository.listWorkouts();
      
      expect(workouts.length, greaterThanOrEqualTo(3));
    });
  });
  
  group('WorkoutRepository - Fluxo Completo', () {
    test('criar workout, adicionar exercício, adicionar série', () async {
      final workoutId = await repository.createWorkout(title: 'Push Day');
      expect(workoutId, isNotEmpty);
      
      final exercises = await repository.allExercises();
      expect(exercises, isNotEmpty);
      final exerciseId = exercises.first.id;
      
      final workoutExerciseId = await repository.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exerciseId,
        ord: 0,
      );
      expect(workoutExerciseId, isNotEmpty);
      
      await db.addSet(
        id: 'set-test-1',
        workoutExerciseId: workoutExerciseId,
        setIndex: 1,
        reps: 12,
        weight: 60.0,
        rpe: 8.0,
        restSec: 90,
        note: null,
      );
      
      final sets = await db.listSets(workoutExerciseId);
      expect(sets, hasLength(1));
      expect(sets.first.reps, 12);
      expect(sets.first.weight, 60.0);
    });
    
    test('finalizar workout deve marcar como done', () async {
      final workoutId = await repository.createWorkout(title: 'Treino');
      
      await repository.markDone(workoutId, true);
      
      final workout = await repository.getWorkout(workoutId);
      expect(workout!.done, true);
      
      final active = await repository.listActiveWorkouts();
      expect(active.where((w) => w.id == workoutId), isEmpty);
    });
    
    test('adicionar múltiplos exercícios e séries', () async {
      final workoutId = await repository.createWorkout(title: 'Leg Day');
      
      final exercises = await repository.allExercises();
      expect(exercises.length, greaterThanOrEqualTo(3));
      
      final we1 = await repository.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exercises[0].id,
        ord: 0,
      );
      
      final we2 = await repository.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exercises[1].id,
        ord: 1,
      );
      
      final we3 = await repository.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exercises[2].id,
        ord: 2,
      );
      
      await db.addSet(
        id: 'set-1-1',
        workoutExerciseId: we1,
        setIndex: 1,
        reps: 10,
        weight: 100.0,
        rpe: null,
        restSec: null,
        note: null,
      );
      
      await db.addSet(
        id: 'set-2-1',
        workoutExerciseId: we2,
        setIndex: 1,
        reps: 12,
        weight: 80.0,
        rpe: null,
        restSec: null,
        note: null,
      );
      
      await db.addSet(
        id: 'set-3-1',
        workoutExerciseId: we3,
        setIndex: 1,
        reps: 15,
        weight: 50.0,
        rpe: null,
        restSec: null,
        note: null,
      );
      
      final exerciseCount = await repository.countExercisesInWorkout(workoutId);
      expect(exerciseCount, 3);
      
      final setCount = await repository.countSetsInWorkout(workoutId);
      expect(setCount, 3);
    });
    
    test('calcular volume total do workout', () async {
      final workoutId = await repository.createWorkout(title: 'Volume Test');
      
      final exercises = await repository.allExercises();
      final weId = await repository.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exercises.first.id,
        ord: 0,
      );
      
      await db.addSet(
        id: 'set-v-1',
        workoutExerciseId: weId,
        setIndex: 1,
        reps: 10,
        weight: 100.0,
        rpe: null,
        restSec: null,
        note: null,
      );
      
      await db.addSet(
        id: 'set-v-2',
        workoutExerciseId: weId,
        setIndex: 2,
        reps: 8,
        weight: 100.0,
        rpe: null,
        restSec: null,
        note: null,
      );
      
      final volume = await repository.computeWorkoutVolume(workoutId);
      expect(volume, 1800.0);
    });
  });
  
  group('WorkoutRepository - Busca e Histórico', () {
    test('ensureSeed deve popular banco com exercícios', () async {
      final exercises = await repository.allExercises();
      
      expect(exercises, isNotEmpty);
      expect(exercises.length, greaterThanOrEqualTo(30));
      
      final groups = exercises.map((e) => e.muscleGroup).toSet();
      expect(groups.length, greaterThanOrEqualTo(5));
    });
    
    test('listFinishedWorkoutsBetween deve filtrar por data', () async {
      final date1 = DateTime(2024, 1, 10);
      final date2 = DateTime(2024, 1, 20);
      final date3 = DateTime(2024, 2, 5);
      
      await repository.createWorkoutAt(
        date: date1,
        title: 'Jan 10',
        done: true,
      );
      
      await repository.createWorkoutAt(
        date: date2,
        title: 'Jan 20',
        done: true,
      );
      
      await repository.createWorkoutAt(
        date: date3,
        title: 'Feb 5',
        done: true,
      );
      
      final januaryWorkouts = await repository.listFinishedWorkoutsBetween(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      
      expect(januaryWorkouts.length, 2);
      
      final titles = januaryWorkouts.map((w) => w.title).toList();
      expect(titles.contains('Jan 10'), true);
      expect(titles.contains('Jan 20'), true);
      expect(titles.contains('Feb 5'), false);
    });
  });
}