import 'package:flutter/material.dart';

// ============================================
// CONSTANTES GLOBAIS DO GYM TRACKER
// ============================================

/// Constantes da aplicação Gym Tracker
/// 
/// Centraliza valores mágicos para facilitar manutenção e consistência.
/// Agrupe constantes relacionadas em classes estáticas.
abstract class AppConstants {
  // ============================================
  // DATABASE
  // ============================================
  
  /// Nome do arquivo SQLite local
  static const String dbFileName = 'gym_tracker.sqlite';
  
  /// Versão atual do schema do banco
  static const int dbSchemaVersion = 2;

  // ============================================
  // DATE & TIME
  // ============================================
  
  /// Intervalo padrão para gráficos e filtros (dias)
  static const int defaultRangeDays = 7;
  
  /// Intervalo de 30 dias
  static const int range30Days = 30;
  
  /// Quantos anos no passado permitir no histórico
  static const int maxHistoryYears = 2;
  
  /// Limite de dias para cálculo de streak
  static const int streakMaxDays = 30;
  
  /// Formato de data padrão para exibição
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  
  /// Formato de data e hora completo
  static const String dateTimeFormatFull = 'dd/MM/yyyy – HH:mm';
  
  /// Formato curto para gráficos
  static const String dateFormatShort = 'dd/MM';

  // ============================================
  // VALIDATION LIMITS
  // ============================================
  
  /// Número máximo de repetições permitido
  static const int maxReps = 999;
  
  /// Número mínimo de repetições
  static const int minReps = 1;
  
  /// Peso máximo permitido (kg)
  static const double maxWeight = 500.0;
  
  /// Peso mínimo permitido (kg)
  static const double minWeight = 0.1;
  
  /// RPE máximo (Rate of Perceived Exertion)
  static const double maxRpe = 10.0;
  
  /// RPE mínimo
  static const double minRpe = 1.0;
  
  /// Descanso máximo em segundos (99 minutos)
  static const int maxRestSeconds = 5940;
  
  /// Tamanho máximo de nota em caracteres
  static const int maxNoteLength = 500;
  
  /// Tamanho máximo do nome de exercício
  static const int maxExerciseNameLength = 100;
  
  /// Tamanho máximo do título de treino
  static const int maxWorkoutTitleLength = 100;

  // ============================================
  // UI TIMING & DEBOUNCE
  // ============================================
  
  /// Delay para debounce em buscas (ms)
  static const int searchDebounceMs = 300;
  
  /// Duração padrão de animações
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  /// Duração de SnackBars
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  /// Duração de SnackBars de erro
  static const Duration snackBarErrorDuration = Duration(seconds: 5);
  
  /// Duração de SnackBars de sucesso
  static const Duration snackBarSuccessDuration = Duration(seconds: 2);

  // ============================================
  // REST TIMER
  // ============================================
  
  /// Atalhos de tempo de descanso (segundos)
  static const List<int> restTimerQuickOptions = [45, 60, 90];
  
  /// Tempo padrão de descanso (segundos)
  static const int defaultRestSeconds = 60;
  
  /// Descanso mínimo (segundos)
  static const int minRestSeconds = 10;

  // ============================================
  // CHARTS & GRAPHS
  // ============================================
  
  /// Altura padrão de gráficos de barras (px)
  static const double chartBarHeight = 160.0;
  
  /// Altura mínima de barras vazias
  static const double chartMinBarHeight = 4.0;
  
  /// Número máximo de items no gráfico antes de comprimir labels
  static const int chartMaxItemsBeforeCompression = 12;
  
  /// Top N exercícios a exibir no ranking
  static const int topExercisesCount = 10;

  // ============================================
  // CALCULATIONS
  // ============================================
  
  /// Tolerância para comparação de 1RM (considerar "empate")
  static const double oneRmComparisonEpsilon = 0.05;
  
  /// Casas decimais para exibição de peso
  static const int weightDecimalPlaces = 1;
  
  /// Casas decimais para exibição de 1RM
  static const int oneRmDecimalPlaces = 1;

  // ============================================
  // PAGINATION & LIMITS
  // ============================================
  
  /// Limite de treinos a buscar por vez (lazy loading)
  static const int workoutsPageSize = 20;
  
  /// Limite de exercícios no catálogo antes de paginar
  static const int exercisesCatalogPageSize = 50;
  
  /// Máximo de séries recomendado por exercício
  static const int maxRecommendedSets = 10;

  // ============================================
  // ERROR MESSAGES
  // ============================================
  
  static const String errorInvalidReps = 'Reps deve estar entre $minReps e $maxReps';
  static const String errorInvalidWeight = 'Peso deve estar entre $minWeight kg e $maxWeight kg';
  static const String errorInvalidRpe = 'RPE deve estar entre $minRpe e $maxRpe';
  static const String errorEmptyName = 'Nome não pode estar vazio';
  static const String errorDatabaseGeneric = 'Erro ao acessar o banco de dados';
  static const String errorNetworkGeneric = 'Erro de conexão. Tente novamente.';

  // ============================================
  // SUCCESS MESSAGES
  // ============================================
  
  static const String successWorkoutCreated = 'Treino criado com sucesso!';
  static const String successWorkoutCompleted = 'Treino concluído!';
  static const String successExerciseAdded = 'Exercício adicionado!';
  static const String successSetAdded = 'Série registrada!';
  static const String successTemplateCreated = 'Rotina salva!';
  static const String successExerciseCreated = 'Exercício criado!';

  // ============================================
  // FEATURE FLAGS (para desenvolvimento)
  // ============================================
  
  /// Ativar logs de debug
  static const bool enableDebugLogs = false;
  
  /// Ativar modo de performance profiling
  static const bool enablePerformanceProfiling = false;
  
  /// Ativar exportação de dados (futuro)
  static const bool enableDataExport = false;
  
  /// Ativar sincronização em nuvem (futuro)
  static const bool enableCloudSync = false;

  // ============================================
  // SEMANTIC VERSIONS (para migrations futuras)
  // ============================================
  
  static const String appVersion = '1.0.0';
  static const int appVersionMajor = 1;
  static const int appVersionMinor = 0;
  static const int appVersionPatch = 0;
}

// ============================================
// CONSTANTES DE LAYOUT/UI
// ============================================

/// Constantes específicas de UI/Layout
abstract class UIConstants {
  // Padding & Margins
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 24.0;
  
  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  // Icon Sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  
  // Avatar Sizes
  static const double avatarSizeS = 32.0;
  static const double avatarSizeM = 40.0;
  static const double avatarSizeL = 56.0;
  
  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationS = 1.0;
  static const double elevationM = 2.0;
  static const double elevationL = 4.0;
  static const double elevationXL = 8.0;
  
  // FAB Padding (para não sobrepor conteúdo)
  static const double fabBottomPadding = 80.0;
  static const double fabRightPadding = 8.0;
}

// ============================================
// ASSETS PATHS (para quando adicionar imagens)
// ============================================

/// Caminhos de assets (imagens, ícones, etc)
abstract class AssetPaths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
  static const String animations = 'assets/animations/';
  
  // Exemplo de uso futuro:
  // static const String logoPath = '${images}logo.png';
  // static const String emptyStatePlaceholder = '${images}empty_state.svg';
}

// ============================================
// ROUTES (backup caso queira centralizar)
// ============================================

/// Rotas nomeadas (já estão em app_router.dart, mas pode duplicar aqui)
abstract class RouteConstants {
  static const String today = '/today';
  static const String progress = '/progress';
  static const String history = '/history';
  static const String catalog = '/catalog';
  static const String settings = '/settings';
  static const String workoutDetail = '/workout/:id';
  static const String workoutNew = '/workout/new';
  
  // Helper para construir rotas com parâmetros
  static String workoutDetailWithId(String id) => '/workout/$id';
}

// ============================================
// EXTENSÕES ÚTEIS
// ============================================

/// Extensão para Duration com constantes comuns
extension DurationConstants on Duration {
  /// Atalhos prontos para usar
  static const Duration quickAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  static const Duration shortSnackBar = Duration(seconds: 2);
  static const Duration normalSnackBar = Duration(seconds: 3);
  static const Duration longSnackBar = Duration(seconds: 5);
}

/// Extensão para EdgeInsets com valores padrão
extension PaddingConstants on EdgeInsets {
  /// Atalhos prontos para usar
  static const EdgeInsets allS = EdgeInsets.all(UIConstants.paddingS);
  static const EdgeInsets allM = EdgeInsets.all(UIConstants.paddingM);
  static const EdgeInsets allL = EdgeInsets.all(UIConstants.paddingL);
  static const EdgeInsets allXL = EdgeInsets.all(UIConstants.paddingXL);
  
  static const EdgeInsets horizontalM = EdgeInsets.symmetric(horizontal: UIConstants.paddingM);
  static const EdgeInsets horizontalL = EdgeInsets.symmetric(horizontal: UIConstants.paddingL);
  
  static const EdgeInsets verticalM = EdgeInsets.symmetric(vertical: UIConstants.paddingM);
  static const EdgeInsets verticalL = EdgeInsets.symmetric(vertical: UIConstants.paddingL);
  
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: UIConstants.paddingL,
    vertical: UIConstants.paddingM,
  );
}