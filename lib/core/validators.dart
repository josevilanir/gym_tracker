import 'constants.dart';

/// Sistema centralizado de validação para formulários
abstract class Validators {
  // ============================================
  // VALIDAÇÕES DE TEXTO
  // ============================================

  /// Valida título de treino
  static String? workoutTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // título é opcional
    }

    if (value.trim().length < 3) {
      return 'Título deve ter no mínimo 3 caracteres';
    }

    if (value.length > AppConstants.maxWorkoutTitleLength) {
      return 'Título muito longo (máx. ${AppConstants.maxWorkoutTitleLength} caracteres)';
    }

    return null;
  }

  /// Valida nome de exercício (obrigatório)
  static String? exerciseName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome do exercício é obrigatório';
    }

    if (value.trim().length < 2) {
      return 'Nome deve ter no mínimo 2 caracteres';
    }

    if (value.length > AppConstants.maxExerciseNameLength) {
      return 'Nome muito longo (máx. ${AppConstants.maxExerciseNameLength} caracteres)';
    }

    return null;
  }

  /// Valida nome de rotina/template
  static String? templateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome da rotina é obrigatório';
    }

    if (value.trim().length < 3) {
      return 'Nome deve ter no mínimo 3 caracteres';
    }

    if (value.length > AppConstants.maxWorkoutTitleLength) {
      return 'Nome muito longo (máx. ${AppConstants.maxWorkoutTitleLength} caracteres)';
    }

    return null;
  }

  /// Valida notas/observações
  static String? note(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // notas são opcionais
    }

    if (value.length > AppConstants.maxNoteLength) {
      return 'Nota muito longa (máx. ${AppConstants.maxNoteLength} caracteres)';
    }

    return null;
  }

  /// Valida equipamento (opcional)
  static String? equipment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // equipamento é opcional
    }

    if (value.length > 50) {
      return 'Nome do equipamento muito longo (máx. 50 caracteres)';
    }

    return null;
  }

  // ============================================
  // VALIDAÇÕES NUMÉRICAS
  // ============================================

  /// Valida número de repetições
  static String? reps(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Número de reps é obrigatório';
    }

    final reps = int.tryParse(value.trim());
    if (reps == null) {
      return 'Digite um número válido';
    }

    if (reps < AppConstants.minReps) {
      return 'Mínimo: ${AppConstants.minReps} reps';
    }

    if (reps > AppConstants.maxReps) {
      return 'Máximo: ${AppConstants.maxReps} reps';
    }

    return null;
  }

  /// Valida peso em kg
  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Peso é obrigatório';
    }

    // Aceita vírgula ou ponto como separador decimal
    final normalized = value.trim().replaceAll(',', '.');
    final weight = double.tryParse(normalized);

    if (weight == null) {
      return 'Digite um peso válido';
    }

    if (weight < AppConstants.minWeight) {
      return 'Mínimo: ${AppConstants.minWeight} kg';
    }

    if (weight > AppConstants.maxWeight) {
      return 'Máximo: ${AppConstants.maxWeight} kg';
    }

    return null;
  }

  /// Valida RPE (Rate of Perceived Exertion)
  static String? rpe(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // RPE é opcional
    }

    final rpe = int.tryParse(value.trim());
    if (rpe == null) {
      return 'Digite um número válido';
    }

    if (rpe < AppConstants.minRpe) {
      return 'Mínimo: ${AppConstants.minRpe}';
    }

    if (rpe > AppConstants.maxRpe) {
      return 'Máximo: ${AppConstants.maxRpe}';
    }

    return null;
  }

  // ============================================
  // VALIDAÇÕES COM TIPO DIRETO (para uso em código)
  // ============================================

  /// Valida reps com valor inteiro direto
  static String? repsInt(int? value) {
    if (value == null) {
      return 'Número de reps é obrigatório';
    }

    if (value < AppConstants.minReps) {
      return 'Mínimo: ${AppConstants.minReps} reps';
    }

    if (value > AppConstants.maxReps) {
      return 'Máximo: ${AppConstants.maxReps} reps';
    }

    return null;
  }

  /// Valida peso com valor double direto
  static String? weightDouble(double? value) {
    if (value == null) {
      return 'Peso é obrigatório';
    }

    if (value < AppConstants.minWeight) {
      return 'Mínimo: ${AppConstants.minWeight} kg';
    }

    if (value > AppConstants.maxWeight) {
      return 'Máximo: ${AppConstants.maxWeight} kg';
    }

    return null;
  }

  /// Valida RPE com valor inteiro direto
  static String? rpeInt(int? value) {
    if (value == null) {
      return null; // RPE é opcional
    }

    if (value < AppConstants.minRpe) {
      return 'Mínimo: ${AppConstants.minRpe}';
    }

    if (value > AppConstants.maxRpe) {
      return 'Máximo: ${AppConstants.maxRpe}';
    }

    return null;
  }

  // ============================================
  // VALIDAÇÕES COMPOSTAS
  // ============================================

  /// Valida se uma string não está vazia (genérico)
  static String? required(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  /// Valida comprimento mínimo
  static String? minLength(String? value, int min, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }

    if (value.trim().length < min) {
      return '$fieldName deve ter no mínimo $min caracteres';
    }

    return null;
  }

  /// Valida comprimento máximo
  static String? maxLength(String? value, int max, {String fieldName = 'Campo'}) {
    if (value == null) return null;

    if (value.length > max) {
      return '$fieldName deve ter no máximo $max caracteres';
    }

    return null;
  }

  /// Combina múltiplos validadores
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  // ============================================
  // HELPERS DE PARSING SEGURO
  // ============================================

  /// Parse seguro de reps (retorna null se inválido)
  static int? parseReps(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final reps = int.tryParse(value.trim());
    if (reps == null) return null;
    if (reps < AppConstants.minReps || reps > AppConstants.maxReps) return null;
    return reps;
  }

  /// Parse seguro de peso (retorna null se inválido)
  static double? parseWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    final weight = double.tryParse(normalized);
    if (weight == null) return null;
    if (weight < AppConstants.minWeight || weight > AppConstants.maxWeight) {
      return null;
    }
    return weight;
  }

  /// Parse seguro de RPE (retorna null se inválido)
  static int? parseRpe(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final rpe = int.tryParse(value.trim());
    if (rpe == null) return null;
    if (rpe < AppConstants.minRpe || rpe > AppConstants.maxRpe) return null;
    return rpe;
  }
}