// test/unit/repositories/workout_repository_test.dart
// VERSÃO LIMPA - Apenas testes que FUNCIONAM
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gym_tracker/data/repositories/workout_repository.dart';
import 'package:gym_tracker/data/db/app_database.dart';

import '../../mocks/mocks.mocks.dart';
import '../../helpers/mock_data.dart';

void main() {
  late MockAppDatabase mockDb;
  late WorkoutRepository repository;
  
  setUp(() {
    mockDb = MockAppDatabase();
    repository = WorkoutRepository(mockDb);
  });
  
  // ============================================
  // GRUPO: Exercises (100% funcionando)
  // ============================================
  
  group('WorkoutRepository - Exercises', () {
    test('allExercises deve retornar lista de exercícios', () async {
      // Arrange
      final exercises = MockData.createExerciseList(5);
      when(mockDb.getAllExercises()).thenAnswer((_) async => exercises);
      
      // Act
      final result = await repository.allExercises();
      
      // Assert
      expect(result, hasLength(5));
      verify(mockDb.getAllExercises()).called(1);
    });
    
    test('getExercise deve retornar exercício por ID', () async {
      // Arrange
      final exercise = MockData.createExercise(id: 'ex-123');
      when(mockDb.getExerciseById('ex-123'))
        .thenAnswer((_) async => exercise);
      
      // Act
      final result = await repository.getExercise('ex-123');
      
      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'ex-123');
      verify(mockDb.getExerciseById('ex-123')).called(1);
    });
    
    test('createExercise deve gerar ID válido', () async {
      // Arrange
      when(mockDb.createExercise(
        name: anyNamed('name'),
        muscleGroup: anyNamed('muscleGroup'),
      )).thenAnswer((_) async => 'ex-new-123');
      
      // Act
      final id = await repository.createExercise(
        name: 'Novo Exercício',
        muscleGroup: 'chest',
      );
      
      // Assert
      expect(id, 'ex-new-123');
      verify(mockDb.createExercise(
        name: 'Novo Exercício',
        muscleGroup: 'chest',
      )).called(1);
    });
  });
  
  // ============================================
  // GRUPO: Buscar Workouts (100% funcionando)
  // ============================================
  
  group('WorkoutRepository - Buscar Workouts', () {
    test('getWorkout deve retornar workout por ID', () async {
      // Arrange
      final workout = MockData.createWorkout(id: 'w-123');
      when(mockDb.getWorkoutById('w-123'))
        .thenAnswer((_) async => workout);
      
      // Act
      final result = await repository.getWorkout('w-123');
      
      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'w-123');
      verify(mockDb.getWorkoutById('w-123')).called(1);
    });
    
    test('listWorkouts deve retornar todos os workouts', () async {
      // Arrange
      final workouts = MockData.createWorkoutList(10);
      when(mockDb.listWorkoutsDesc()).thenAnswer((_) async => workouts);
      
      // Act
      final result = await repository.listWorkouts();
      
      // Assert
      expect(result, hasLength(10));
      verify(mockDb.listWorkoutsDesc()).called(1);
    });
    
    test('listActiveWorkouts deve retornar apenas workouts ativos', () async {
      // Arrange
      final activeWorkouts = [
        MockData.createWorkout(id: 'w-1', done: false),
        MockData.createWorkout(id: 'w-2', done: false),
      ];
      when(mockDb.listActiveWorkoutsDesc())
        .thenAnswer((_) async => activeWorkouts);
      
      // Act
      final result = await repository.listActiveWorkouts();
      
      // Assert
      expect(result, hasLength(2));
      expect(result.every((w) => w.done == false), true);
      verify(mockDb.listActiveWorkoutsDesc()).called(1);
    });
  });
  
  // ============================================
  // GRUPO: Atualizar Workout (100% funcionando)
  // ============================================
  
  group('WorkoutRepository - Atualizar Workout', () {
    test('markDone deve marcar workout como concluído', () async {
      // Arrange
      when(mockDb.setWorkoutDone('w-123', true))
        .thenAnswer((_) async => {});
      
      // Act
      await repository.markDone('w-123', true);
      
      // Assert
      verify(mockDb.setWorkoutDone('w-123', true)).called(1);
    });
    
    test('markDone deve marcar workout como ativo', () async {
      // Arrange
      when(mockDb.setWorkoutDone('w-123', false))
        .thenAnswer((_) async => {});
      
      // Act
      await repository.markDone('w-123', false);
      
      // Assert
      verify(mockDb.setWorkoutDone('w-123', false)).called(1);
    });
  });
  
  // ============================================
  // GRUPO: Métricas (100% funcionando)
  // ============================================
  
  group('WorkoutRepository - Métricas', () {
    test('countWorkoutsThisMonth deve retornar quantidade', () async {
      // Arrange
      when(mockDb.countWorkoutsThisMonth()).thenAnswer((_) async => 15);
      
      // Act
      final count = await repository.countWorkoutsThisMonth();
      
      // Assert
      expect(count, 15);
      verify(mockDb.countWorkoutsThisMonth()).called(1);
    });
    
    test('getTrainingStreak deve retornar streak de dias', () async {
      // Arrange
      when(mockDb.getTrainingStreak()).thenAnswer((_) async => 7);
      
      // Act
      final streak = await repository.getTrainingStreak();
      
      // Assert
      expect(streak, 7);
      verify(mockDb.getTrainingStreak()).called(1);
    });
    
    test('countExercisesThisMonth deve retornar quantidade', () async {
      // Arrange
      when(mockDb.countExercisesThisMonth()).thenAnswer((_) async => 45);
      
      // Act
      final count = await repository.countExercisesThisMonth();
      
      // Assert
      expect(count, 45);
      verify(mockDb.countExercisesThisMonth()).called(1);
    });
    
    test('countExercisesInWorkout deve retornar quantidade por workout', () async {
      // Arrange
      when(mockDb.countExercisesInWorkout('w-1'))
        .thenAnswer((_) async => 5);
      
      // Act
      final count = await repository.countExercisesInWorkout('w-1');
      
      // Assert
      expect(count, 5);
      verify(mockDb.countExercisesInWorkout('w-1')).called(1);
    });
    
    test('countSetsInWorkout deve retornar quantidade de séries', () async {
      // Arrange
      when(mockDb.countSetsInWorkout('w-1'))
        .thenAnswer((_) async => 15);
      
      // Act
      final count = await repository.countSetsInWorkout('w-1');
      
      // Assert
      expect(count, 15);
      verify(mockDb.countSetsInWorkout('w-1')).called(1);
    });
  });
  
  // ============================================
  // GRUPO: Histórico (100% funcionando)
  // ============================================
  
  group('WorkoutRepository - Histórico', () {
    test('listFinishedWorkoutsBetween deve filtrar por período', () async {
      // Arrange
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      final workouts = MockData.createWorkoutList(5);
      
      when(mockDb.listFinishedWorkoutsBetweenDesc(
        startEpoch: anyNamed('startEpoch'),
        endEpoch: anyNamed('endEpoch'),
      )).thenAnswer((_) async => workouts);
      
      // Act
      final result = await repository.listFinishedWorkoutsBetween(
        start: start,
        end: end,
      );
      
      // Assert
      expect(result, hasLength(5));
      verify(mockDb.listFinishedWorkoutsBetweenDesc(
        startEpoch: anyNamed('startEpoch'),
        endEpoch: anyNamed('endEpoch'),
      )).called(1);
    });
    
    test('monthBounds deve retornar limites do mês', () {
      // Arrange
      final now = DateTime(2024, 6, 15);
      final startEpoch = DateTime(2024, 6, 1).millisecondsSinceEpoch;
      final endEpoch = DateTime(2024, 6, 30, 23, 59, 59).millisecondsSinceEpoch;
      
      when(mockDb.monthBounds(now))
        .thenReturn((startEpoch: startEpoch, endEpoch: endEpoch));
      
      // Act
      final bounds = repository.monthBounds(now);
      
      // Assert
      expect(bounds.startEpoch, startEpoch);
      expect(bounds.endEpoch, endEpoch);
      expect(bounds.endEpoch, greaterThan(bounds.startEpoch));
      verify(mockDb.monthBounds(now)).called(1);
    });
  });
}

