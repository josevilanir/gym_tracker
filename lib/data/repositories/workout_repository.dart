import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../core/enums.dart';
import '../db/app_database.dart';

class WorkoutRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  WorkoutRepository(this.db);

  // ---------- Seed ----------
  Future<void> ensureSeed() async {
    final existing = await db.getAllExercises();
    if (existing.isNotEmpty) return;

    await db.insertExercise(ExercisesCompanion.insert(
      id: _uuid.v4(), name: 'Supino reto',
      muscleGroup: MuscleGroup.chest.name,
      equipment: const Value('Barbell'),
      isCustom: const Value(false),
    ));
    await db.insertExercise(ExercisesCompanion.insert(
      id: _uuid.v4(), name: 'Remada curvada',
      muscleGroup: MuscleGroup.back.name,
      equipment: const Value('Barbell'),
      isCustom: const Value(false),
    ));
    await db.insertExercise(ExercisesCompanion.insert(
      id: _uuid.v4(), name: 'Agachamento livre',
      muscleGroup: MuscleGroup.legs.name,
      equipment: const Value('Barbell'),
      isCustom: const Value(false),
    ));
  }

  // ---------- Exercises ----------
  Future<List<Exercise>> allExercises() => db.getAllExercises();
  Future<Exercise?> getExercise(String id) => db.getExerciseById(id);

  Future<String> createCustomExercise({
    required String name,
    required MuscleGroup muscle,
    String? equipment,
  }) async {
    final id = _uuid.v4();
    await db.insertExercise(ExercisesCompanion.insert(
      id: id, name: name, muscleGroup: muscle.name,
      equipment: Value(equipment), isCustom: const Value(true),
    ));
    return id;
  }

  // ---------- Workouts ----------
  Future<String> createWorkout({String? title}) async {
    final id = const Uuid().v4();
    await db.into(db.workouts).insert(WorkoutsCompanion.insert(
      id: id,
      title: Value(title),
      dateEpoch: DateTime.now().millisecondsSinceEpoch,
      done: const Value(false),
    ));
    return id;
  }

  // --- remoções ---
  Future<void> deleteSet(String setId) => db.deleteSet(setId);
  Future<void> deleteWorkoutExercise(String workoutExerciseId) =>
      db.deleteWorkoutExercise(workoutExerciseId);

  // --- catálogo: criar exercício ---
  Future<String> createExercise({required String name, required String muscleGroup}) =>
      db.createExercise(name: name, muscleGroup: muscleGroup);

  Future<Workout?> getWorkout(String id) => db.getWorkoutById(id);
  Future<void> markDone(String workoutId, bool done) => db.setWorkoutDone(workoutId, done);

  Future<List<Workout>> listWorkouts() => db.listWorkoutsDesc();
  Future<List<Workout>> listActiveWorkouts() => db.listActiveWorkoutsDesc(); // NOVO

  // ---------- WorkoutExercises ----------
  Future<String> addExerciseToWorkout({
    required String workoutId, required String exerciseId, required int ord,
  }) async {
    final id = _uuid.v4();
    return db.addExerciseToWorkout(id: id, workoutId: workoutId, exerciseId: exerciseId, ord: ord);
  }

  Future<void> addExerciseAtEnd(String workoutId, String exerciseId) async {
    final current = await listWorkoutExercises(workoutId);
    final ord = current.isEmpty ? 0 : (current.last.ord + 1);
    await addExerciseToWorkout(workoutId: workoutId, exerciseId: exerciseId, ord: ord);
  }

  Future<List<WorkoutExercise>> listWorkoutExercises(String workoutId) =>
      db.listWorkoutExercises(workoutId);

  Future<void> setExerciseDone(String workoutExerciseId, bool done) async {
    await db.setWorkoutExerciseDone(workoutExerciseId: workoutExerciseId, done: done);
    final we = await db.getWorkoutExerciseById(workoutExerciseId);
    if (we == null) return;
    final all = await db.listWorkoutExercises(we.workoutId);
    final allDone = all.isNotEmpty && all.every((x) => x.done);
    if (allDone) {
      await db.setWorkoutDone(we.workoutId, true);
    }
  }

  Future<void> reorderExercises(List<WorkoutExercise> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      final item = ordered[i];
      if (item.ord != i) {
        await db.updateWorkoutExerciseOrder(workoutExerciseId: item.id, ord: i);
      }
    }
  }

  // ---------- Sets ----------
  Future<List<SetEntry>> listSets(String workoutExerciseId) => db.listSets(workoutExerciseId);

  Future<void> addSetQuick({
    required String workoutExerciseId,
    required int reps,
    required double weight,
    double? rpe,
    int? restSec,
    String? note,
  }) async {
    final currentSets = await db.listSets(workoutExerciseId);
    final nextIndex = (currentSets.isEmpty ? 0 : currentSets.last.setIndex) + 1;
    await db.addSet(
      id: _uuid.v4(),
      workoutExerciseId: workoutExerciseId,
      setIndex: nextIndex,
      reps: reps,
      weight: weight,
      rpe: rpe,
      restSec: restSec,
      note: note,
    );
  }

  // ---------- Métricas ----------
  Future<double> computeWorkoutVolume(String workoutId) async {
    final wes = await listWorkoutExercises(workoutId);
    double total = 0;
    for (final we in wes) {
      final sets = await listSets(we.id);
      for (final s in sets) {
        total += s.reps * s.weight;
      }
    }
    return total;
  }

  Future<int> countWorkoutsThisMonth() => db.countWorkoutsThisMonth();
  Future<int> getTrainingStreak() => db.getTrainingStreak();
  Future<int> countExercisesThisMonth() => db.countExercisesThisMonth();

  // ---------- Templates ----------
  Future<List<Template>> listTemplates() => db.listTemplates();

  Future<String> saveWorkoutAsTemplate({required String workoutId, required String name}) async {
    final id = _uuid.v4();
    await db.createTemplate(id: id, name: name);
    final wes = await listWorkoutExercises(workoutId);
    for (var i = 0; i < wes.length; i++) {
      await db.addTemplateExercise(
        id: _uuid.v4(),
        templateId: id,
        exerciseId: wes[i].exerciseId,
        ord: i,
      );
    }
    return id;
  }

  Future<String> createWorkoutFromTemplate({required String templateId, String? title}) async {
    final workoutId = _uuid.v4();
    await db.createWorkout(id: workoutId, date: DateTime.now(), title: title, notes: null);

    final items = await db.listTemplateExercises(templateId);
    for (var i = 0; i < items.length; i++) {
      await addExerciseToWorkout(
        workoutId: workoutId,
        exerciseId: items[i].exerciseId,
        ord: i,
      );
    }
    return workoutId;
  }

    /// Stream: treinos ativos (done = false)
  Stream<List<Workout>> watchActiveWorkouts() => db.watchActiveWorkoutsDesc();

  // ---------- Histórico / Filtros ----------
  Future<List<Workout>> listFinishedWorkoutsBetween({
    required DateTime start,
    required DateTime end,
  }) {
    final startEpoch =
        DateTime(start.year, start.month, start.day, 0, 0, 0).millisecondsSinceEpoch;
    final endEpoch =
        DateTime(end.year, end.month, end.day, 23, 59, 59).millisecondsSinceEpoch;
    return db.listFinishedWorkoutsBetweenDesc(startEpoch: startEpoch, endEpoch: endEpoch);
  }

  Future<int> countExercisesInWorkout(String workoutId) =>
      db.countExercisesInWorkout(workoutId);

  Future<int> countSetsInWorkout(String workoutId) =>
      db.countSetsInWorkout(workoutId);

  ({int startEpoch, int endEpoch}) monthBounds(DateTime now) => db.monthBounds(now);

    // ---------- Métricas agregadas para gráficos ----------
  /// Retorna o volume diário (nº de séries) por dia no intervalo [start, end] (inclusive).
  Future<List<({DateTime day, int volume})>> dailyVolume({
    required DateTime start,
    required DateTime end,
  }) async {
    // normaliza para começo/fim do dia
    DateTime startDay = DateTime(start.year, start.month, start.day);
    DateTime endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final workouts = await listFinishedWorkoutsBetween(start: startDay, end: endDay);

    // agrega volume por dia (volume = nº de séries dos treinos concluídos daquele dia)
    final Map<DateTime, int> perDay = {};

    for (final w in workouts) {
      final wDate = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
      final dayKey = DateTime(wDate.year, wDate.month, wDate.day); // início do dia
      final sets = await countSetsInWorkout(w.id);
      perDay.update(dayKey, (old) => old + sets, ifAbsent: () => sets);
    }

    // garante dias “zerados” no intervalo (para o gráfico ficar contínuo)
    final days = <({DateTime day, int volume})>[];
    for (DateTime d = startDay;
        !d.isAfter(endDay);
        d = d.add(const Duration(days: 1))) {
      final key = DateTime(d.year, d.month, d.day);
      days.add((day: key, volume: perDay[key] ?? 0));
    }

    return days;
  }

}
