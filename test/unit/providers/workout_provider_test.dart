// test/unit/providers/workout_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/providers/workout_provider.dart';
import '../../mocks/mocks.mocks.dart';
import '../../helpers/mock_data.dart';

void main() {
  late MockWorkoutRepository mockRepository;
  
  setUp(() {
    mockRepository = MockWorkoutRepository();
  });
  
  group('WorkoutProvider -', () {
    test('deve carregar workouts com sucesso', () async {
      // Arrange
      final workouts = [
        MockData.createMockWorkout(id: '1', title: 'Treino 1'),
        MockData.createMockWorkout(id: '2', title: 'Treino 2'),
      ];
      
      when(mockRepository.getAllWorkouts())
        .thenAnswer((_) async => workouts);
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final provider = container.read(workoutsProvider.notifier);
      await provider.loadWorkouts();
      
      // Assert
      final state = container.read(workoutsProvider);
      expect(state, isA<AsyncData<List<Workout>>>());
      expect(state.value, hasLength(2));
      expect(state.value![0].title, 'Treino 1');
      
      container.dispose();
    });
    
    test('deve emitir erro quando falha ao carregar', () async {
      // Arrange
      when(mockRepository.getAllWorkouts())
        .thenThrow(Exception('Database error'));
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      
      // Act
      final provider = container.read(workoutsProvider.notifier);
      await provider.loadWorkouts();
      
      // Assert
      final state = container.read(workoutsProvider);
      expect(state, isA<AsyncError>());
      
      container.dispose();
    });
  });
}