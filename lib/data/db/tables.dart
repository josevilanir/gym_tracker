import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()(); // enum como string
  TextColumn get equipment => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class Workouts extends Table {
  TextColumn get id => text()();
  IntColumn get dateEpoch => integer()(); // millisecondsSinceEpoch
  TextColumn get title => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get ord => integer().withDefault(const Constant(0))();
  BoolColumn get done => boolean().withDefault(const Constant(false))(); // NOVO

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class SetEntries extends Table {
  TextColumn get id => text()();
  TextColumn get workoutExerciseId => text().references(WorkoutExercises, #id)();
  IntColumn get setIndex => integer()(); // 1,2,3...
  IntColumn get reps => integer()();
  RealColumn get weight => real().withDefault(const Constant(0))();
  RealColumn get rpe => real().nullable()();
  IntColumn get restSec => integer().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

// ---------- Rotinas salvas (templates) ----------
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class TemplateExercises extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().references(Templates, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get ord => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
