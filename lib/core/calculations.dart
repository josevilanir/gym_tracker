// CÁLCULOS DE 1RM (One Rep Max)
// ============================================

/// Fórmulas suportadas para estimativa de 1RM
enum OneRmFormula {
  /// Fórmula de Epley: 1RM = peso × (1 + reps/30)
  /// Mais precisa para 1-10 reps
  epley,
  
  /// Fórmula de Brzycki: 1RM = peso × 36 / (37 - reps)
  /// Boa para 2-10 reps
  brzycki,
  
  /// Fórmula de Wathan: 1RM = peso × 100 / (48.8 + 53.8 × e^(-0.075×reps))
  /// Considera curva exponencial de fadiga
  wathan,
}

/// Calcula o 1RM estimado com base em repetições e peso
/// 
/// **Uso:**
/// ```dart
/// final oneRm = estimateOneRm(
///   reps: 8, 
///   weight: 100.0, 
///   formula: OneRmFormula.epley,
/// );
/// print('1RM estimado: $oneRm kg');
/// ```
/// 
/// **Parâmetros:**
/// - [reps]: Número de repetições realizadas (deve ser > 0)
/// - [weight]: Peso utilizado em kg (deve ser > 0)
/// - [formula]: Fórmula de cálculo (padrão: Epley)
/// 
/// **Retorna:** 
/// - O 1RM estimado em kg
/// - Se reps <= 1, retorna o próprio peso (1 rep já é o 1RM)
/// - Se valores inválidos, retorna 0.0
double estimateOneRm({
  required int reps,
  required double weight,
  OneRmFormula formula = OneRmFormula.epley,
}) {
  // Validações
  if (reps <= 0 || weight <= 0) return 0.0;
  if (reps == 1) return weight; // 1 rep já é o 1RM
  
  switch (formula) {
    case OneRmFormula.epley:
      return _epley(reps, weight);
      
    case OneRmFormula.brzycki:
      return _brzycki(reps, weight);
      
    case OneRmFormula.wathan:
      return _wathan(reps, weight);
  }
}

// ============================================
// FÓRMULAS PRIVADAS
// ============================================

/// Fórmula de Epley: 1RM = peso × (1 + reps/30)
double _epley(int reps, double weight) {
  return weight * (1.0 + reps / 30.0);
}

/// Fórmula de Brzycki: 1RM = peso × 36 / (37 - reps)
double _brzycki(int reps, double weight) {
  final denominator = 37.0 - reps;
  
  // Proteção: se reps >= 37, fórmula fica inválida
  if (denominator <= 0) {
    // Fallback para Epley em casos extremos
    return _epley(reps, weight);
  }
  
  return weight * 36.0 / denominator;
}

/// Fórmula de Wathan: 1RM = peso × 100 / (48.8 + 53.8 × e^(-0.075×reps))
double _wathan(int reps, double weight) {
  final expPart = 48.8 + 53.8 * _exp(-0.075 * reps);
  return weight * (100.0 / expPart);
}

/// Helper para exponencial (dart:math)
double _exp(double x) {
  const e = 2.718281828459045;
  double result = 1.0;
  double term = 1.0;
  
  for (int i = 1; i < 20; i++) {
    term *= x / i;
    result += term;
  }
  
  return result;
}

// ============================================
// HELPERS EXTRAS
// ============================================

/// Calcula a % do 1RM que está sendo usado
/// 
/// Exemplo: se 1RM = 100kg e você fez 80kg, retorna 0.8 (80%)
double percentageOf1RM({
  required double weight,
  required double oneRM,
}) {
  if (oneRM <= 0) return 0.0;
  return (weight / oneRM).clamp(0.0, 1.0);
}

/// Calcula o peso recomendado para uma % do 1RM
/// 
/// Exemplo: se 1RM = 100kg e você quer 80%, retorna 80kg
double weightForPercentage({
  required double oneRM,
  required double percentage,
}) {
  return oneRM * percentage.clamp(0.0, 1.0);
}

/// Retorna uma descrição legível da fórmula
String getFormulaDescription(OneRmFormula formula) {
  switch (formula) {
    case OneRmFormula.epley:
      return 'Epley (ideal para 1-10 reps)';
    case OneRmFormula.brzycki:
      return 'Brzycki (boa para 2-10 reps)';
    case OneRmFormula.wathan:
      return 'Wathan (curva exponencial)';
  }
}

// ============================================
// EXTENSÕES ÚTEIS
// ============================================

/// Extensão para facilitar o uso em SetEntry
extension SetEntryOneRm on ({int reps, double weight}) {
  /// Calcula o 1RM desta série
  double get oneRm => estimateOneRm(
    reps: reps, 
    weight: weight,
    formula: OneRmFormula.epley,
  );
  
  /// Calcula o 1RM com fórmula específica
  double oneRmWith(OneRmFormula formula) => estimateOneRm(
    reps: reps,
    weight: weight,
    formula: formula,
  );
}