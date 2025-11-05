// test/unit/models/workout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/db/app_database.dart';
import 'package:drift/drift.dart';

void main() {
  group('Workout Model (Drift) -', () {
    test('deve criar workout com valores corretos', () {
      // Arrange & Act
      const workout = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Assert
      expect(workout.id, '123');
      expect(workout.title, 'Treino A');
      expect(workout.dateEpoch, 1699564800000);
      expect(workout.done, false);
      expect(workout.notes, null);
    });
    
    test('deve criar workout sem título e notas', () {
      // Arrange & Act
      const workout = Workout(
        id: 'abc',
        dateEpoch: 1699564800000,
        done: true,
        title: null,
        notes: null,
      );
      
      // Assert
      expect(workout.id, 'abc');
      expect(workout.title, null);
      expect(workout.notes, null);
      expect(workout.done, true);
    });
    
    test('copyWith deve criar nova instância com valores atualizados', () {
      // Arrange
      const original = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Act
      final updated = original.copyWith(done: true);
      
      // Assert
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.dateEpoch, original.dateEpoch);
      expect(updated.done, true); // Mudou
      expect(original.done, false); // Original não mudou
    });
    
    test('copyWith deve atualizar title usando Value', () {
      // Arrange
      const original = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Act - title e notes usam Value<T?> para nullable
      final updated = original.copyWith(
        title: const Value('Treino B'),
      );
      
      // Assert
      expect(updated.title, 'Treino B');
      expect(original.title, 'Treino A');
    });
    
    test('copyWith deve permitir setar title como null', () {
      // Arrange
      const original = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Act
      final updated = original.copyWith(
        title: const Value(null),
      );
      
      // Assert
      expect(updated.title, null);
    });
    
    test('toJson deve serializar corretamente', () {
      // Arrange
      const workout = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: 'Notas do treino',
      );
      
      // Act
      final json = workout.toJson();
      
      // Assert
      expect(json['id'], '123');
      expect(json['title'], 'Treino A');
      expect(json['dateEpoch'], 1699564800000);
      expect(json['done'], false);
      expect(json['notes'], 'Notas do treino');
    });
    
    test('toJson deve serializar title null corretamente', () {
      // Arrange
      const workout = Workout(
        id: '123',
        title: null,
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Act
      final json = workout.toJson();
      
      // Assert
      expect(json['id'], '123');
      expect(json['title'], null);
      expect(json['notes'], null);
    });
    
    test('fromJson deve deserializar corretamente', () {
      // Arrange
      final json = {
        'id': '123',
        'title': 'Treino A',
        'dateEpoch': 1699564800000,
        'done': false,
        'notes': 'Teste',
      };
      
      // Act
      final workout = Workout.fromJson(json);
      
      // Assert
      expect(workout.id, '123');
      expect(workout.title, 'Treino A');
      expect(workout.dateEpoch, 1699564800000);
      expect(workout.done, false);
      expect(workout.notes, 'Teste');
    });
    
    test('fromJson deve lidar com valores null', () {
      // Arrange
      final json = {
        'id': '456',
        'title': null,
        'dateEpoch': 1699564800000,
        'done': true,
        'notes': null,
      };
      
      // Act
      final workout = Workout.fromJson(json);
      
      // Assert
      expect(workout.id, '456');
      expect(workout.title, null);
      expect(workout.notes, null);
      expect(workout.done, true);
    });
    
    test('equality deve comparar workouts corretamente', () {
      // Arrange
      const workout1 = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      const workout2 = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      const workout3 = Workout(
        id: '456',
        title: 'Treino B',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Assert
      expect(workout1 == workout2, true); // Iguais
      expect(workout1 == workout3, false); // Diferentes
    });
    
    test('hashCode deve ser igual para workouts iguais', () {
      // Arrange
      const workout1 = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      const workout2 = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Assert
      expect(workout1.hashCode, workout2.hashCode);
    });
    
    test('toString deve retornar representação legível', () {
      // Arrange
      const workout = Workout(
        id: '123',
        title: 'Treino A',
        dateEpoch: 1699564800000,
        done: false,
        notes: null,
      );
      
      // Act
      final str = workout.toString();
      
      // Assert
      expect(str, contains('Workout('));
      expect(str, contains('id: 123'));
      expect(str, contains('title: Treino A'));
      expect(str, contains('done: false'));
    });
  });
}