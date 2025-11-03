// test/widget/workout_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/widgets/workout_card.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

void main() {
  group('WorkoutCard Widget -', () {
    testWidgets('deve exibir título do workout', (tester) async {
      // Arrange
      final workout = MockData.createMockWorkout(title: 'Treino A');
      
      // Act
      await tester.pumpWidget(
        createTestWidget(WorkoutCard(workout: workout))
      );
      
      // Assert
      expect(find.text('Treino A'), findsOneWidget);
    });
    
    testWidgets('deve exibir data formatada', (tester) async {
      // Arrange
      final workout = MockData.createMockWorkout();
      
      // Act
      await tester.pumpWidget(
        createTestWidget(WorkoutCard(workout: workout))
      );
      
      // Assert
      expect(find.textContaining('/'), findsOneWidget); // Data no formato DD/MM
    });
    
    testWidgets('deve mostrar ícone de check quando done=true', (tester) async {
      // Arrange
      final workout = MockData.createMockWorkout(done: true);
      
      // Act
      await tester.pumpWidget(
        createTestWidget(WorkoutCard(workout: workout))
      );
      
      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
    
    testWidgets('não deve mostrar ícone de check quando done=false', (tester) async {
      // Arrange
      final workout = MockData.createMockWorkout(done: false);
      
      // Act
      await tester.pumpWidget(
        createTestWidget(WorkoutCard(workout: workout))
      );
      
      // Assert
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
    
    testWidgets('deve chamar onTap quando card é clicado', (tester) async {
      // Arrange
      final workout = MockData.createMockWorkout();
      bool wasTapped = false;
      
      // Act
      await tester.pumpWidget(
        createTestWidget(
          WorkoutCard(
            workout: workout,
            onTap: () => wasTapped = true,
          )
        )
      );
      
      await tester.tap(find.byType(WorkoutCard));
      await tester.pumpAndSettle();
      
      // Assert
      expect(wasTapped, true);
    });
  });
}