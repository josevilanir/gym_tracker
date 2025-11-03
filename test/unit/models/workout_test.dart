// test/unit/models/workout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/exercise.dart';

void main() {
  group('Workout Model -', () {
    test('deve criar workout com valores corretos', () {
      // Arrange & Act
      final workout = (
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
      );
      
      // Assert
      expect(workout.id, '123');
      expect(workout.title, 'Treino A');
      expect(workout.dateEpoch, 1699564800000);
      expect(workout.done, false);
    });
    
    test('copyWith deve criar nova instância com valores atualizados', () {
      // Arrange
      final original = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
      );
      
      // Act
      final updated = original.copyWith(done: true);
      
      // Assert
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.done, true);
      expect(original.done, false); // Original não mudou
    });
    
    test('toJson deve serializar corretamente', () {
      // Arrange
      final workout = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
      );
      
      // Act
      final json = workout.toJson();
      
      // Assert
      expect(json['id'], '123');
      expect(json['title'], 'Treino A');
      expect(json['dateEpoch'], 1699564800000);
      expect(json['done'], false);
    });
    
    test('fromJson deve deserializar corretamente', () {
      // Arrange
      final json = {
        'id': '123',
        'title': 'Treino A',
        'dateEpoch': 1699564800000,
        'done': false,
      };
      
      // Act
      final workout = Workout.fromJson(json);
      
      // Assert
      expect(workout.id, '123');
      expect(workout.title, 'Treino A');
      expect(workout.dateEpoch, 1699564800000);
      expect(workout.done, false);
    });
  });
}