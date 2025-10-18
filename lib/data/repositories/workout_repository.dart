// lib/data/repositories/workout_repository.dart
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../core/enums.dart';
import '../../core/calculations.dart'; 
import '../db/app_database.dart';

class WorkoutExerciseWithDetails {
  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final List<SetEntry> sets;

  const WorkoutExerciseWithDetails({
    required this.workoutExercise,
    required this.exercise,
    required this.sets,
  });

  /// ID do WorkoutExercise (útil para keys em widgets)
  String get id => workoutExercise.id;

  /// Se o exercício está concluído
  bool get isDone => workoutExercise.done;

  /// Ordem do exercício no treino
  int get order => workoutExercise.ord;
}

class WorkoutWithDetails {
  final Workout workout;
  final List<WorkoutExerciseWithDetails> exercises;

  const WorkoutWithDetails({
    required this.workout,
    required this.exercises,
  });

  /// Número total de exercícios
  int get exerciseCount => exercises.length;

  /// Número total de séries
  int get totalSets => exercises.fold(0, (sum, ex) => sum + ex.sets.length);

  /// Volume total (kg)
  double get totalVolume {
    double total = 0;
    for (final ex in exercises) {
      for (final set in ex.sets) {
        total += set.reps * set.weight;
      }
    }
    return total;
  }
}

class WorkoutRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  WorkoutRepository(this.db);

  // ============================================
  // SEED
  // ============================================
  
  Future<void> ensureSeed() async {
    final existing = await db.getAllExercises();
    if (existing.isNotEmpty) return;

    const uuid = Uuid();
    final Map<String, List<Map<String, String>>> seeds = {
      MuscleGroup.chest.name: [
        {'name': 'Supino reto', 'equipment': 'Barbell'},
        {'name': 'Supino inclinado com halteres', 'equipment': 'Dumbbell'},
        {'name': 'Crucifixo no banco', 'equipment': 'Dumbbell'},
        {'name': 'Crossover na polia', 'equipment': 'Cable'},
        {'name': 'Flexão de braços', 'equipment': 'Bodyweight'},
      ],
      MuscleGroup.back.name: [
        {'name': 'Remada curvada', 'equipment': 'Barbell'},
        {'name': 'Puxada frente (barra)', 'equipment': 'Machine'},
        {'name': 'Remada baixa (cabo)', 'equipment': 'Cable'},
        {'name': 'Barra fixa', 'equipment': 'Bodyweight'},
        {'name': 'Pullover com halter', 'equipment': 'Dumbbell'},
      ],
      MuscleGroup.legs.name: [
        {'name': 'Agachamento livre', 'equipment': 'Barbell'},
        {'name': 'Leg press', 'equipment': 'Machine'},
        {'name': 'Cadeira extensora', 'equipment': 'Machine'},
        {'name': 'Mesa flexora', 'equipment': 'Machine'},
        {'name': 'Panturrilha em pé', 'equipment': 'Machine'},
      ],
      MuscleGroup.shoulders.name: [
        {'name': 'Desenvolvimento com halteres', 'equipment': 'Dumbbell'},
        {'name': 'Elevação lateral', 'equipment': 'Dumbbell'},
        {'name': 'Elevação frontal', 'equipment': 'Dumbbell'},
        {'name': 'Remada alta', 'equipment': 'Barbell'},
        {'name': 'Desenvolvimento Arnold', 'equipment': 'Dumbbell'},
      ],
      MuscleGroup.biceps.name: [
        {'name': 'Rosca direta', 'equipment': 'Barbell'},
        {'name': 'Rosca alternada', 'equipment': 'Dumbbell'},
        {'name': 'Rosca martelo', 'equipment': 'Dumbbell'},
        {'name': 'Rosca Scott', 'equipment': 'Machine'},
        {'name': 'Rosca concentrada', 'equipment': 'Dumbbell'},
      ],
      MuscleGroup.triceps.name: [
        {'name': 'Tríceps testa', 'equipment': 'Barbell'},
        {'name': 'Tríceps corda (polia)', 'equipment': 'Cable'},
        {'name': 'Mergulho em banco', 'equipment': 'Bodyweight'},
        {'name': 'Tríceps francês', 'equipment': 'Dumbbell'},
        {'name': 'Tríceps coice', 'equipment': 'Dumbbell'},
      ],
      MuscleGroup.core.name: [
        {'name': 'Prancha', 'equipment': 'Bodyweight'},
        {'name': 'Abdominal crunch', 'equipment': 'Bodyweight'},
        {'name': 'Elevação de pernas', 'equipment': 'Bodyweight'},
        {'name': 'Abdominal bicicleta', 'equipment': 'Bodyweight'},
        {'name': 'Abdominal oblíquo', 'equipment': 'Bodyweight'},
      ],
    };

    await db.batch((b) {
      for (final entry in seeds.entries) {
        final group = entry.key;
        for (final ex in entry.value) {
          b.insert(
            db.exercises,
            ExercisesCompanion.insert(
              id: uuid.v4(),
              name: ex['name']!,
              muscleGroup: group,
              equipment: Value(ex['equipment']!),
              isCustom: const Value(false),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  // ============================================
  // EXERCISES
  // ============================================
  
  Future<List<Exercise>> allExercises() => db.getAllExercises();
  Future<Exercise?> getExercise(String id) => db.getExerciseById(id);

  Future<String> createCustomExercise({
    required String name,
    required MuscleGroup muscle,
    String? equipment,
  }) async {
    final id = _uuid.v4();
    await db.insertExercise(ExercisesCompanion.insert(
      id: id,
      name: name,
      muscleGroup: muscle.name,
      equipment: Value(equipment),
      isCustom: const Value(true),
    ));
    return id;
  }

  Future<String> createExercise({
    required String name,
    required String muscleGroup,
  }) => db.createExercise(name: name, muscleGroup: muscleGroup);

  // ============================================
  // WORKOUTS
  // ============================================
  
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

  Future<String> createEmptyWorkoutNow({String? title}) async {
    return createWorkoutAt(
      date: DateTime.now(),
      title: (title?.trim().isEmpty ?? true) ? null : title!.trim(),
      done: false,
    );
  }

  Future<String> createWorkoutAt({
    required DateTime date,
    String? title,
    bool done = false,
  }) async {
    final id = const Uuid().v4();
    await db.into(db.workouts).insert(
      WorkoutsCompanion.insert(
        id: id,
        title: Value(title),
        dateEpoch: DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
        ).millisecondsSinceEpoch,
        done: Value(done),
      ),
    );
    return id;
  }

  Future<Workout?> getWorkout(String id) => db.getWorkoutById(id);
  
  Future<void> markDone(String workoutId, bool done) => 
      db.setWorkoutDone(workoutId, done);

  Future<List<Workout>> listWorkouts() => db.listWorkoutsDesc();
  
  Future<List<Workout>> listActiveWorkouts() => db.listActiveWorkoutsDesc();
  
  Stream<List<Workout>> watchActiveWorkouts() => db.watchActiveWorkoutsDesc();

  Future<void> updateWorkoutDate(String workoutId, DateTime date) async {
    await (db.update(db.workouts)..where((w) => w.id.equals(workoutId))).write(
      WorkoutsCompanion(
        dateEpoch: Value(DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
        ).millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateWorkoutMeta(
    String workoutId, {
    bool? done,
    String? title,
  }) async {
    await (db.update(db.workouts)..where((w) => w.id.equals(workoutId))).write(
      WorkoutsCompanion(
        done: done == null ? const Value.absent() : Value(done),
        title: title == null ? const Value.absent() : Value(title),
      ),
    );
  }

  // ============================================
  // WORKOUT EXERCISES
  // ============================================
  
  Future<String> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    required int ord,
  }) async {
    final id = _uuid.v4();
    return db.addExerciseToWorkout(
      id: id,
      workoutId: workoutId,
      exerciseId: exerciseId,
      ord: ord,
    );
  }

  Future<void> addExerciseAtEnd(String workoutId, String exerciseId) async {
    final current = await listWorkoutExercises(workoutId);
    final ord = current.isEmpty ? 0 : (current.last.ord + 1);
    await addExerciseToWorkout(
      workoutId: workoutId,
      exerciseId: exerciseId,
      ord: ord,
    );
  }

  Future<List<WorkoutExercise>> listWorkoutExercises(String workoutId) =>
      db.listWorkoutExercises(workoutId);

  Future<void> setExerciseDone(String workoutExerciseId, bool done) async {
    await db.setWorkoutExerciseDone(
      workoutExerciseId: workoutExerciseId,
      done: done,
    );
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
        await db.updateWorkoutExerciseOrder(
          workoutExerciseId: item.id,
          ord: i,
        );
      }
    }
  }

  Future<void> deleteWorkoutExercise(String workoutExerciseId) =>
      db.deleteWorkoutExercise(workoutExerciseId);

  // ============================================
  // SETS
  // ============================================
  
  Future<List<SetEntry>> listSets(String workoutExerciseId) =>
      db.listSets(workoutExerciseId);

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

  Future<void> deleteSet(String setId) => db.deleteSet(setId);

  Future<void> updateSetNote(String setId, String? note) =>
      db.updateSetNote(setId: setId, note: note);

  // ============================================
  // MÉTRICAS
  // ============================================
  
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

  Future<int> countExercisesInWorkout(String workoutId) =>
      db.countExercisesInWorkout(workoutId);

  Future<int> countSetsInWorkout(String workoutId) =>
      db.countSetsInWorkout(workoutId);

  ({int startEpoch, int endEpoch}) monthBounds(DateTime now) => 
      db.monthBounds(now);

  // ============================================
  // HISTÓRICO
  // ============================================
  
  Future<List<Workout>> listFinishedWorkoutsBetween({
    required DateTime start,
    required DateTime end,
  }) {
    final startEpoch = DateTime(start.year, start.month, start.day, 0, 0, 0)
        .millisecondsSinceEpoch;
    final endEpoch = DateTime(end.year, end.month, end.day, 23, 59, 59)
        .millisecondsSinceEpoch;
    return db.listFinishedWorkoutsBetweenDesc(
      startEpoch: startEpoch,
      endEpoch: endEpoch,
    );
  }

  Future<List<({DateTime day, int volume})>> dailyVolume({
    required DateTime start,
    required DateTime end,
  }) async {
    DateTime startDay = DateTime(start.year, start.month, start.day);
    DateTime endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final workouts = await listFinishedWorkoutsBetween(
      start: startDay,
      end: endDay,
    );

    final Map<DateTime, int> perDay = {};

    for (final w in workouts) {
      final wDate = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
      final dayKey = DateTime(wDate.year, wDate.month, wDate.day);
      final sets = await countSetsInWorkout(w.id);
      perDay.update(dayKey, (old) => old + sets, ifAbsent: () => sets);
    }

    final days = <({DateTime day, int volume})>[];
    for (DateTime d = startDay;
        !d.isAfter(endDay);
        d = d.add(const Duration(days: 1))) {
      final key = DateTime(d.year, d.month, d.day);
      days.add((day: key, volume: perDay[key] ?? 0));
    }

    return days;
  }

  // ============================================
  // TEMPLATES (ROTINAS)
  // ============================================
  
  Future<List<Template>> listTemplates() => db.listTemplates();

  Future<String> saveWorkoutAsTemplate({
    required String workoutId,
    required String name,
  }) async {
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

  Future<String> createWorkoutFromTemplate({
    required String templateId,
    String? title,
  }) async {
    final workoutId = _uuid.v4();
    await db.createWorkout(
      id: workoutId,
      date: DateTime.now(),
      title: title,
      notes: null,
    );

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

  Future<String> createWorkoutFromTemplateAt({
    required String templateId,
    required DateTime date,
    String? title,
    bool done = false,
  }) async {
    final wid = await createWorkoutFromTemplate(
      templateId: templateId,
      title: title,
    );

    await updateWorkoutDate(wid, date);

    if (done) {
      await updateWorkoutMeta(wid, done: true);
    }

    return wid;
  }

  Future<String> createTemplate({required String name}) async {
    final id = _uuid.v4();
    await db.createTemplate(id: id, name: name);
    return id;
  }

  Future<void> setTemplateExercises({
    required String templateId,
    required List<String> exerciseIdsInOrder,
  }) async {
    await (db.delete(db.templateExercises)
          ..where((te) => te.templateId.equals(templateId)))
        .go();

    for (var i = 0; i < exerciseIdsInOrder.length; i++) {
      await db.addTemplateExercise(
        id: _uuid.v4(),
        templateId: templateId,
        exerciseId: exerciseIdsInOrder[i],
        ord: i,
      );
    }
  }

  Future<String> saveTemplateFromExercises({
    required String name,
    required List<String> exerciseIdsInOrder,
  }) async {
    final tid = await createTemplate(name: name);
    await setTemplateExercises(
      templateId: tid,
      exerciseIdsInOrder: exerciseIdsInOrder,
    );
    return tid;
  }

  // ============================================
  //               PRs & RECORDES
  // ============================================
  
  /// Melhor e1RM histórico para um exercício
  Future<double?> bestE1RMForExercise(String exerciseId) async {
    final wes = await (db.select(db.workoutExercises)
          ..where((we) => we.exerciseId.equals(exerciseId)))
        .get();

    if (wes.isEmpty) return null;

    double? best;
    for (final we in wes) {
      final sets = await db.listSets(we.id);
      for (final s in sets) {
        // << USA A FUNÇÃO CENTRAL
        final e1 = estimateOneRm(
          reps: s.reps,
          weight: s.weight,
          formula: OneRmFormula.epley,
        );
        if (best == null || e1 > best) best = e1;
      }
    }
    return best;
  }

  /// Retorna a melhor entrada (série) de e1RM desse exercício, com data e set
  Future<({double e1rm, DateTime date, SetEntry set, String workoutId})?>
      bestE1RMEntry(String exerciseId) async {
    final wes = await (db.select(db.workoutExercises)
          ..where((we) => we.exerciseId.equals(exerciseId)))
        .get();

    double? best;
    SetEntry? bestSet;
    String? bestWorkoutId;
    DateTime? bestDate;

    for (final we in wes) {
      final sets = await db.listSets(we.id);
      if (sets.isEmpty) continue;

      final w = await db.getWorkoutById(we.workoutId);
      if (w == null) continue;
      final wDate = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);

      for (final s in sets) {
        // << USA A FUNÇÃO CENTRAL
        final e1 = estimateOneRm(
          reps: s.reps,
          weight: s.weight,
          formula: OneRmFormula.epley,
        );
        if (best == null || e1 > best) {
          best = e1;
          bestSet = s;
          bestWorkoutId = we.workoutId;
          bestDate = wDate;
        }
      }
    }

    if (best == null || bestSet == null || bestDate == null || bestWorkoutId == null) {
      return null;
    }
    return (e1rm: best, date: bestDate, set: bestSet, workoutId: bestWorkoutId);
  }

  /// Série temporal de VOLUME (soma reps*peso) por dia para um exercício
  Future<List<({DateTime day, double volume})>> exerciseVolumeSeries({
    required String exerciseId,
    required DateTime start,
    required DateTime end,
  }) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final wes = await (db.select(db.workoutExercises)
          ..where((we) => we.exerciseId.equals(exerciseId)))
        .get();

    if (wes.isEmpty) {
      final days = <({DateTime day, double volume})>[];
      for (DateTime d = startDay;
          !d.isAfter(endDay);
          d = d.add(const Duration(days: 1))) {
        days.add((day: DateTime(d.year, d.month, d.day), volume: 0));
      }
      return days;
    }

    final Map<DateTime, double> perDay = {};
    for (final we in wes) {
      final w = await db.getWorkoutById(we.workoutId);
      if (w == null) continue;
      final wDate = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
      if (wDate.isBefore(startDay) || wDate.isAfter(endDay)) continue;
      final dayKey = DateTime(wDate.year, wDate.month, wDate.day);

      final sets = await db.listSets(we.id);
      if (sets.isEmpty) continue;

      double vol = 0;
      for (final s in sets) {
        final weight = s.weight;
        vol += (s.reps * weight);
      }
      perDay.update(dayKey, (old) => old + vol, ifAbsent: () => vol);
    }

    final out = <({DateTime day, double volume})>[];
    for (DateTime d = startDay;
        !d.isAfter(endDay);
        d = d.add(const Duration(days: 1))) {
      final key = DateTime(d.year, d.month, d.day);
      out.add((day: key, volume: perDay[key] ?? 0));
    }
    return out;
  }

  /// Verifica se uma série (ainda não salva) seria PR
  Future<({bool isPr, double e1rm})> checkIfNewPR({
    required String exerciseId,
    required int reps,
    required double weight,
  }) async {
    final currentBest = await bestE1RMForExercise(exerciseId) ?? 0.0;
    // << USA A FUNÇÃO CENTRAL
    final newE1 = estimateOneRm(
      reps: reps,
      weight: weight,
      formula: OneRmFormula.epley,
    );
    return (isPr: newE1 > currentBest, e1rm: newE1);
  }

  /// Indica se um treino contém algum PR para qualquer exercício
  Future<bool> hasAnyPRInWorkout(String workoutId) async {
    final wes = await db.listWorkoutExercises(workoutId);
    for (final we in wes) {
      final bestBeforeGlobal = await bestE1RMForExercise(we.exerciseId) ?? 0.0;
      final sets = await db.listSets(we.id);
      for (final s in sets) {
        // << USA A FUNÇÃO CENTRAL
        final e1 = estimateOneRm(
          reps: s.reps,
          weight: s.weight,
          formula: OneRmFormula.epley,
        );
        if (e1 >= bestBeforeGlobal && bestBeforeGlobal > 0) return true;
      }
    }
    return false;
  }

  /// Melhor e1RM do exercício ANTES de um determinado treino
  Future<double?> bestE1rmForExerciseBefore({
    required String exerciseId,
    required int beforeEpoch,
  }) async {
    final prevWorkouts = await (db.select(db.workouts)
          ..where((w) => w.done.equals(true) & 
                w.dateEpoch.isSmallerThanValue(beforeEpoch)))
        .get();

    if (prevWorkouts.isEmpty) return null;

    final ids = prevWorkouts.map((w) => w.id).toList();
    final wes = await (db.select(db.workoutExercises)
          ..where((we) => 
                we.exerciseId.equals(exerciseId) & we.workoutId.isIn(ids)))
        .get();

    if (wes.isEmpty) return null;

    double? best;
    for (final we in wes) {
      final sets = await db.listSets(we.id);
      for (final s in sets) {
        // << USA A FUNÇÃO CENTRAL
        final e = estimateOneRm(
          reps: s.reps,
          weight: s.weight,
          formula: OneRmFormula.epley,
        );
        if (best == null || e > best) best = e;
      }
    }
    return best;
  }
// ============================================
// ADICIONAR ESTE MÉTODO NA CLASSE WorkoutRepository
// ============================================

/// Busca um treino completo com TODOS os dados de uma vez
/// 
/// **Performance:** 3 queries em vez de N+M queries
/// - 1 query para buscar workout_exercises
/// - 1 query para buscar todos os exercises
/// - 1 query para buscar todos os sets
/// 
/// **Antes (N+1):** 
/// - 10 exercícios = 1 + (10 × 1) + (10 × 1) = 21 queries
/// 
/// **Depois (otimizado):**
/// - 10 exercícios = 1 + 1 + 1 = 3 queries (7x mais rápido!)
Future<WorkoutWithDetails> getWorkoutWithDetails(String workoutId) async {
  // 1. Buscar o treino
  final workout = await db.getWorkoutById(workoutId);
  if (workout == null) {
    throw Exception('Treino não encontrado: $workoutId');
  }

  // 2. Buscar TODOS os workout_exercises do treino (1 query)
  final workoutExercises = await db.listWorkoutExercises(workoutId);

  if (workoutExercises.isEmpty) {
    return WorkoutWithDetails(workout: workout, exercises: const []);
  }

  // 3. Buscar TODOS os exercises de uma vez (1 query)
  final exerciseIds = workoutExercises.map((we) => we.exerciseId).toSet().toList();
  final exercises = await (db.select(db.exercises)
        ..where((e) => e.id.isIn(exerciseIds)))
      .get();

  // Criar mapa para lookup O(1)
  final exerciseMap = {for (var e in exercises) e.id: e};

  // 4. Buscar TODOS os sets de uma vez (1 query)
  final workoutExerciseIds = workoutExercises.map((we) => we.id).toList();
  final allSets = await (db.select(db.setEntries)
        ..where((s) => s.workoutExerciseId.isIn(workoutExerciseIds))
        ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
      .get();

  // Criar mapa de sets por workoutExerciseId
  final setsMap = <String, List<SetEntry>>{};
  for (final set in allSets) {
    (setsMap[set.workoutExerciseId] ??= []).add(set);
  }

  // 5. Montar resultado final
  final exercisesWithDetails = workoutExercises.map((we) {
    final exercise = exerciseMap[we.exerciseId];
    if (exercise == null) {
      throw Exception('Exercício não encontrado: ${we.exerciseId}');
    }

    return WorkoutExerciseWithDetails(
      workoutExercise: we,
      exercise: exercise,
      sets: setsMap[we.id] ?? [],
    );
  }).toList();

  return WorkoutWithDetails(
    workout: workout,
    exercises: exercisesWithDetails,
  );
}

/// Busca múltiplos treinos completos de uma vez (para lista de histórico)
/// 
/// **Performance:** Ainda mais otimizado para listas
/// - Busca TODOS os workouts
/// - Busca TODOS os workout_exercises
/// - Busca TODOS os exercises
/// - Busca TODOS os sets
/// 
/// **Antes:** N treinos × M exercícios = centenas de queries
/// **Depois:** 4 queries no total!
Future<List<WorkoutWithDetails>> getMultipleWorkoutsWithDetails(
  List<String> workoutIds,
) async {
  if (workoutIds.isEmpty) return const [];

  // 1. Buscar TODOS os workouts (1 query)
  final workouts = await (db.select(db.workouts)
        ..where((w) => w.id.isIn(workoutIds)))
      .get();

  final workoutMap = {for (var w in workouts) w.id: w};

  // 2. Buscar TODOS os workout_exercises (1 query)
  final allWorkoutExercises = await (db.select(db.workoutExercises)
        ..where((we) => we.workoutId.isIn(workoutIds))
        ..orderBy([(we) => OrderingTerm.asc(we.ord)]))
      .get();

  if (allWorkoutExercises.isEmpty) {
    return workouts
        .map((w) => WorkoutWithDetails(workout: w, exercises: const []))
        .toList();
  }

  // 3. Buscar TODOS os exercises (1 query)
  final exerciseIds =
      allWorkoutExercises.map((we) => we.exerciseId).toSet().toList();
  final exercises = await (db.select(db.exercises)
        ..where((e) => e.id.isIn(exerciseIds)))
      .get();

  final exerciseMap = {for (var e in exercises) e.id: e};

  // 4. Buscar TODOS os sets (1 query)
  final workoutExerciseIds = allWorkoutExercises.map((we) => we.id).toList();
  final allSets = await (db.select(db.setEntries)
        ..where((s) => s.workoutExerciseId.isIn(workoutExerciseIds))
        ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
      .get();

  // Mapear sets por workoutExerciseId
  final setsMap = <String, List<SetEntry>>{};
  for (final set in allSets) {
    (setsMap[set.workoutExerciseId] ??= []).add(set);
  }

  // Mapear workout_exercises por workoutId
  final workoutExercisesMap = <String, List<WorkoutExercise>>{};
  for (final we in allWorkoutExercises) {
    (workoutExercisesMap[we.workoutId] ??= []).add(we);
  }

  // 5. Montar resultado final
  return workouts.map((workout) {
    final wes = workoutExercisesMap[workout.id] ?? [];

    final exercisesWithDetails = wes.map((we) {
      final exercise = exerciseMap[we.exerciseId];
      if (exercise == null) {
        // Se exercício foi deletado, criar placeholder
        return WorkoutExerciseWithDetails(
          workoutExercise: we,
          exercise: Exercise(
            id: we.exerciseId,
            name: 'Exercício removido',
            muscleGroup: 'other',
            equipment: null,
            isCustom: false,
          ),
          sets: setsMap[we.id] ?? [],
        );
      }

      return WorkoutExerciseWithDetails(
        workoutExercise: we,
        exercise: exercise,
        sets: setsMap[we.id] ?? [],
      );
    }).toList();

    return WorkoutWithDetails(
      workout: workout,
      exercises: exercisesWithDetails,
    );
  }).toList();
}

}

// ============================================
// HELPERS PÚBLICOS (para uso em pages)
// ============================================

/// Retorna o melhor 1RM no treino e o PR histórico juntos
Future<({double? bestInWorkout, double? bestAllTime})> bestsForExercise({
  required AppDatabase db,
  required String workoutId,
  required String exerciseId,
  OneRmFormula formula = OneRmFormula.epley,
}) async {
  final bestIn = await bestOneRmInWorkoutForExercise(
    db: db,
    workoutId: workoutId,
    exerciseId: exerciseId,
    formula: formula,
  );
  final bestAll = await bestOneRmAllTimeForExercise(
    db: db,
    exerciseId: exerciseId,
    formula: formula,
  );
  return (bestInWorkout: bestIn, bestAllTime: bestAll);
}

/// Retorna o melhor 1RM no treino para um exercício específico
Future<double?> bestOneRmInWorkoutForExercise({
  required AppDatabase db,
  required String workoutId,
  required String exerciseId,
  OneRmFormula formula = OneRmFormula.epley,
}) async {
  final wes = await (db.select(db.workoutExercises)
        ..where((we) => 
              we.workoutId.equals(workoutId) & we.exerciseId.equals(exerciseId)))
      .get();
  if (wes.isEmpty) return null;

  double? best;
  for (final we in wes) {
    final sets = await db.listSets(we.id);
    for (final s in sets) {
      final w = s.weight;
      if (w <= 0) continue;
      // << USA A FUNÇÃO CENTRAL
      final oneRm = estimateOneRm(reps: s.reps, weight: w, formula: formula);
      if (best == null || oneRm > best) best = oneRm;
    }
  }
  return best;
}

/// Retorna o melhor 1RM em todo o histórico para um exercício específico
Future<double?> bestOneRmAllTimeForExercise({
  required AppDatabase db,
  required String exerciseId,
  OneRmFormula formula = OneRmFormula.epley,
}) async {
  final wes = await (db.select(db.workoutExercises)
        ..where((we) => we.exerciseId.equals(exerciseId)))
      .get();
  if (wes.isEmpty) return null;

  double? best;
  for (final we in wes) {
    final sets = await db.listSets(we.id);
    for (final s in sets) {
      final w = s.weight;
      if (w <= 0) continue;
      // << USA A FUNÇÃO CENTRAL
      final oneRm = estimateOneRm(reps: s.reps, weight: w, formula: formula);
      if (best == null || oneRm > best) best = oneRm;
    }
  }
  return best;
}