// test/widget/features/workout_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/features/workout/pages/workout_detail_page.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/mock_data.dart';
import '../../../mocks/mocks.mocks.dart';

void main() {
  late MockWorkoutRepository mockRepository;
  
  setUp(() {
    mockRepository = MockWorkoutRepository();
  });
  
  group('WorkoutDetailScreen -', () {
    testWidgets('deve carregar e exibir detalhes do workout', (tester) async {
      // Arrange
      final workout = MockData.createMockWorkout(title: 'Treino Push');
      when(mockRepository.getWorkoutById(any))
        .thenAnswer((_) async => workout);
      
      // Act
      await tester.pumpWidget(
        createTestWidget(
          WorkoutDetailScreen(workoutId: workout.id),
          overrides: [
            workoutRepositoryProvider.overrideWithValue(mockRepository),
          ],
        )
      );
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Treino Push'), findsOneWidget);
    });
    
    testWidgets('deve mostrar loading enquanto carrega dados', (tester) async {
      // Arrange
      when(mockRepository.getWorkoutById(any))
        .thenAnswer((_) async {
          await Future.delayed(Duration(seconds: 1));
          return MockData.createMockWorkout();
        });
      
      // Act
      await tester.pumpWidget(
        createTestWidget(
          WorkoutDetailScreen(workoutId: '123'),
          overrides: [
            workoutRepositoryProvider.overrideWithValue(mockRepository),
          ],
        )
      );
      
      // Assert - Deve mostrar loading inicialmente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('deve mostrar erro quando falha ao carregar', (tester) async {
      // Arrange
      when(mockRepository.getWorkoutById(any))
        .thenThrow(Exception('Database error'));
      
      // Act
      await tester.pumpWidget(
        createTestWidget(
          WorkoutDetailScreen(workoutId: '123'),
          overrides: [
            workoutRepositoryProvider.overrideWithValue(mockRepository),
          ],
        )
      );
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.textContaining('Erro'), findsOneWidget);
    });
    
    testWidgets('botão Finalizar deve marcar treino como concluído', (tester) async {
      // Arrange
      final workout = MockData.createMockWorkout(done: false);
      when(mockRepository.getWorkoutById(any))
        .thenAnswer((_) async => workout);
      when(mockRepository.finishWorkout(any))
        .thenAnswer((_) async => {});
      
      // Act
      await tester.pumpWidget(
        createTestWidget(
          WorkoutDetailScreen(workoutId: workout.id),
          overrides: [
            workoutRepositoryProvider.overrideWithValue(mockRepository),
          ],
        )
      );
      await tester.pumpAndSettle();
      
      // Encontrar e clicar no botão Finalizar
      final finishButton = find.text('Finalizar Treino');
      expect(finishButton, findsOneWidget);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();
      
      // Assert
      verify(mockRepository.finishWorkout(workout.id)).called(1);
    });
  });
}