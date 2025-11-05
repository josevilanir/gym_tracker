// test/unit/providers/workout_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/data/db/app_database.dart';
import 'package:gym_tracker/data/repositories/workout_repository.dart';
import '../../mocks/mocks.mocks.dart';
import '../../helpers/mock_data.dart';

// Provider do repository para testes
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  throw UnimplementedError();
});

// Provider de workouts (usando StreamProvider)
final workoutsProvider = StreamProvider<List<Workout>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return Stream.fromFuture(repo.listWorkouts());
});

void main() {
  late MockWorkoutRepository mockRepository;
  
  setUp(() {
    mockRepository = MockWorkoutRepository();
  });
  
  group('WorkoutProvider -', () {
    test('deve carregar workouts com sucesso', () async {
      // Arrange
      final workouts = [
    
        MockData.createWorkout(id: '1', title: 'Treino 1'),
        MockData.createWorkout(id: '2', title: 'Treino 2'),
      ];
      
      when(mockRepository.listWorkouts())
        .thenAnswer((_) async => workouts);
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act - aguarda o provider carregar
      final asyncValue = await container.read(workoutsProvider.future);
      
      // Assert
      expect(asyncValue, hasLength(2));
      expect(asyncValue[0].title, 'Treino 1');
      expect(asyncValue[1].title, 'Treino 2');
      
      verify(mockRepository.listWorkouts()).called(1);
      
      container.dispose();
    });
    
    test('deve emitir erro quando falha ao carregar', () async {
      // Arrange
      when(mockRepository.listWorkouts())
        .thenThrow(Exception('Database error'));
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act & Assert
      expect(
        () => container.read(workoutsProvider.future),
        throwsA(isA<Exception>()),
      );
      
      container.dispose();
    });
    
    test('deve retornar lista vazia quando não há workouts', () async {
      // Arrange
      when(mockRepository.listWorkouts())
        .thenAnswer((_) async => []);
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final asyncValue = await container.read(workoutsProvider.future);
      
      // Assert
      expect(asyncValue, isEmpty);
      
      container.dispose();
    });
  });
  
  group('WorkoutRepository Provider -', () {
    test('deve criar workout com sucesso', () async {
      // Arrange
      const workoutId = 'new-workout-id';
      when(mockRepository.createWorkout(title: 'Novo Treino'))
        .thenAnswer((_) async => workoutId);
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final repo = container.read(workoutRepositoryProvider);
      final id = await repo.createWorkout(title: 'Novo Treino');
      
      // Assert
      expect(id, workoutId);
      verify(mockRepository.createWorkout(title: 'Novo Treino')).called(1);
      
      container.dispose();
    });
    
    test('deve marcar workout como concluído', () async {
      // Arrange
      const workoutId = 'workout-123';
      when(mockRepository.markDone(workoutId, true))
        .thenAnswer((_) async => Future.value());
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final repo = container.read(workoutRepositoryProvider);
      await repo.markDone(workoutId, true);
      
      // Assert
      verify(mockRepository.markDone(workoutId, true)).called(1);
      
      container.dispose();
    });
    
    test('deve buscar workout por ID', () async {
      // Arrange
      const workoutId = 'workout-123';
      final workout = MockData.createWorkout(
        id: workoutId,
        title: 'Treino Teste',
      );
      
      when(mockRepository.getWorkout(workoutId))
        .thenAnswer((_) async => workout);
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final repo = container.read(workoutRepositoryProvider);
      final result = await repo.getWorkout(workoutId);
      
      // Assert
      expect(result, isNot(null));
      expect(result!.id, workoutId);
      expect(result.title, 'Treino Teste');
      
      container.dispose();
    });
    
    test('deve adicionar exercício ao workout', () async {
      // Arrange
      const workoutId = 'workout-1';
      const exerciseId = 'ex-1';
      const workoutExerciseId = 'we-1';
      
      when(mockRepository.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exerciseId,
        ord: 0,
      )).thenAnswer((_) async => workoutExerciseId);
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final repo = container.read(workoutRepositoryProvider);
      final id = await repo.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exerciseId,
        ord: 0,
      );
      
      // Assert
      expect(id, workoutExerciseId);
      verify(mockRepository.addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: exerciseId,
        ord: 0,
      )).called(1);
      
      container.dispose();
    });
    
    test('deve listar exercícios do workout', () async {
      // Arrange
      const workoutId = 'workout-1';
      final workoutExercises = [
        MockData.createWorkoutExercise(id: 'we-1', workoutId: workoutId),
        MockData.createWorkoutExercise(id: 'we-2', workoutId: workoutId),
      ];
      
      when(mockRepository.listWorkoutExercises(workoutId))
        .thenAnswer((_) async => workoutExercises);
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final repo = container.read(workoutRepositoryProvider);
      final exercises = await repo.listWorkoutExercises(workoutId);
      
      // Assert
      expect(exercises, hasLength(2));
      expect(exercises[0].workoutId, workoutId);
      
      container.dispose();
    });
  });
}