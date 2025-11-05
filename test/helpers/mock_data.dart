// test/helpers/mock_data.dart
import 'package:gym_tracker/data/db/app_database.dart';
import 'package:gym_tracker/core/enums.dart';

/// Helper para criar dados mock - VERSÃO FINAL CORRIGIDA
/// Baseado EXATAMENTE nas classes geradas pelo Drift
class MockData {
  
  // ============================================
  // EXERCISE
  // Campos: id, name, muscleGroup, equipment, isCustom
  // ============================================
  
  static Exercise createExercise({
    String? id,
    String? name,
    String? muscleGroup,
    String? equipment,
    bool? isCustom,
  }) {
    return Exercise(
      id: id ?? 'ex-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Supino Reto',
      muscleGroup: muscleGroup ?? MuscleGroup.chest.name,
      equipment: equipment,
      isCustom: isCustom ?? false,
    );
  }
  
  static List<Exercise> createExerciseList(int count) {
    return List.generate(count, (i) => createExercise(
      id: 'ex-$i',
      name: 'Exercise $i',
    ));
  }
  
  // ============================================
  // WORKOUT
  // Campos: id, dateEpoch, title, notes, done
  // NÃO TEM templateId!
  // ============================================
  
  static Workout createWorkout({
    String? id,
    String? title,
    int? dateEpoch,
    bool? done,
    String? notes,
  }) {
    return Workout(
      id: id ?? 'workout-${DateTime.now().millisecondsSinceEpoch}',
      dateEpoch: dateEpoch ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      notes: notes,
      done: done ?? false,
    );
  }
  
  static List<Workout> createWorkoutList(int count) {
    return List.generate(count, (i) {
      final date = DateTime.now().subtract(Duration(days: i));
      return createWorkout(
        id: 'workout-$i',
        title: 'Workout ${String.fromCharCode(65 + i)}',
        dateEpoch: date.millisecondsSinceEpoch,
        done: i > 0,
      );
    });
  }
  
  // ============================================
  // WORKOUT EXERCISE
  // Campos: id, workoutId, exerciseId, ord, done
  // ============================================
  
  static WorkoutExercise createWorkoutExercise({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? ord,
    bool? done,
  }) {
    return WorkoutExercise(
      id: id ?? 'we-${DateTime.now().millisecondsSinceEpoch}',
      workoutId: workoutId ?? 'workout-1',
      exerciseId: exerciseId ?? 'ex-1',
      ord: ord ?? 0,
      done: done ?? false,
    );
  }
  
  // ============================================
  // SET ENTRY
  // Campos: id, workoutExerciseId, setIndex, reps, weight, rpe, restSec, note
  // ============================================
  
  static SetEntry createSetEntry({
    String? id,
    String? workoutExerciseId,
    int? setIndex,
    int? reps,
    double? weight,
    double? rpe,
    int? restSec,
    String? note,
  }) {
    return SetEntry(
      id: id ?? 'set-${DateTime.now().millisecondsSinceEpoch}',
      workoutExerciseId: workoutExerciseId ?? 'we-1',
      setIndex: setIndex ?? 1,
      reps: reps ?? 12,
      weight: weight ?? 60.0,
      rpe: rpe,
      restSec: restSec,
      note: note,
    );
  }
  
  static List<SetEntry> createSetList(String workoutExerciseId, int count) {
    return List.generate(count, (i) => createSetEntry(
      id: 'set-$i',
      workoutExerciseId: workoutExerciseId,
      setIndex: i + 1,
      reps: 12 - i,
      weight: 60.0,
    ));
  }
  
  // ============================================
  // TEMPLATE (Rotinas salvas)
  // Campos: id, name, createdAt
  // ============================================
  
  static Template createTemplate({
    String? id,
    String? name,
    int? createdAt,
  }) {
    return Template(
      id: id ?? 'tpl-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Rotina Push',
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  static List<Template> createTemplateList(int count) {
    return List.generate(count, (i) => createTemplate(
      id: 'tpl-$i',
      name: 'Template $i',
    ));
  }
  
  // ============================================
  // TEMPLATE EXERCISE
  // Campos: id, templateId, exerciseId, ord
  // ============================================
  
  static TemplateExercise createTemplateExercise({
    String? id,
    String? templateId,
    String? exerciseId,
    int? ord,
  }) {
    return TemplateExercise(
      id: id ?? 'te-${DateTime.now().millisecondsSinceEpoch}',
      templateId: templateId ?? 'tpl-1',
      exerciseId: exerciseId ?? 'ex-1',
      ord: ord ?? 0,
    );
  }
}