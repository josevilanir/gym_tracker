import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums.dart';
import '../../../core/validators.dart';
import '../../../core/constants.dart';
import '../../../data/db/app_database.dart';
import '../../workout/controllers/providers.dart';

/// Página de Catálogo de Exercícios
class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de exercícios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo exercício'),
        onPressed: () => _openCreateExerciseDialog(context, ref),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: repo.allExercises(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando exercícios...'),
                ],
              ),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar exercícios',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snap.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => (context as Element).markNeedsBuild(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final all = snap.data ?? [];

          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhum exercício cadastrado',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comece criando seu primeiro exercício',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _openCreateExerciseDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Criar primeiro exercício'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Agrupa por grupo muscular
          final groups = _groupByMuscle(all);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final entry = groups.entries.elementAt(index);
              final groupKey = entry.key;
              final items = entry.value;

              return _GroupSection(
                groupLabel: _labelGroup(groupKey),
                exercises: items..sort((a, b) => a.name.compareTo(b.name)),
              );
            },
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('Sobre o Catálogo'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Toque em um exercício para ver instruções'),
            SizedBox(height: 8),
            Text('• Use o botão + para adicionar ao treino ativo'),
            SizedBox(height: 8),
            Text('• Crie exercícios personalizados'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _openCreateExerciseDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final equipCtrl = TextEditingController();
    MuscleGroup? selectedGroup;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo exercício'),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo Nome
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome do exercício *',
                        hintText: 'Ex: Supino inclinado',
                        prefixIcon: const Icon(Icons.fitness_center),
                        counterText:
                            '${nameCtrl.text.length}/${AppConstants.maxExerciseNameLength}',
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: AppConstants.maxExerciseNameLength,
                      validator: Validators.exerciseName,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (_) => setState(() {}), // atualiza contador
                    ),
                    const SizedBox(height: 16),

                    // Campo Grupo Muscular
                    DropdownButtonFormField<MuscleGroup>(
                      value: selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Grupo muscular *',
                        prefixIcon: Icon(Icons.accessibility_new),
                      ),
                      items: MuscleGroup.values
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(_labelGroup(g.name)),
                              ))
                          .toList(),
                      onChanged: (g) => setState(() => selectedGroup = g),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione um grupo muscular';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Equipamento
                    TextFormField(
                      controller: equipCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Equipamento (opcional)',
                        hintText: 'Ex.: Barra, Halter, Máquina...',
                        prefixIcon: Icon(Icons.construction),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.equipment,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 8),

                    // Texto de ajuda
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '* Campos obrigatórios',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              // Valida o formulário completo
              if (!(formKey.currentState?.validate() ?? false)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Corrija os erros antes de criar'),
                      ],
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final name = nameCtrl.text.trim();

              // Validação extra de segurança
              if (name.isEmpty || selectedGroup == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.warning_amber_outlined, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Preencha todos os campos obrigatórios'),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              // Cria o exercício
              try {
                final repo = ref.read(workoutRepoProvider);
                final equipment = equipCtrl.text.trim();

                await repo.createCustomExercise(
                  name: name,
                  muscle: selectedGroup!,
                  equipment: equipment.isEmpty ? null : equipment,
                );

                if (context.mounted) {
                  Navigator.pop(ctx, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Exercício "$name" criado!')),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: AppConstants.snackBarSuccessDuration,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Erro ao criar exercício: $e')),
                        ],
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: AppConstants.snackBarErrorDuration,
                    ),
                  );
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    // Se criou com sucesso, força rebuild
    if (result == true && context.mounted) {
      // Força rebuild do FutureBuilder
      (context as Element).markNeedsBuild();
    }
  }
}

/// Seção por grupo muscular
class _GroupSection extends ConsumerWidget {
  final String groupLabel;
  final List<Exercise> exercises;

  const _GroupSection({
    required this.groupLabel,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da seção
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _getGroupIcon(groupLabel),
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    groupLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('${exercises.length}'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 8),

            // Lista de exercícios do grupo
            ...exercises.map((exercise) {
              return FutureBuilder<List<Workout>>(
                future: repo.listActiveWorkouts(),
                builder: (ctx, activeSnap) {
                  final actives = activeSnap.data ?? [];
                  final hasActive = actives.isNotEmpty;
                  final activeId = hasActive ? actives.first.id : null;

                  return ListTile(
                    dense: false,
                    leading: exercise.isCustom
                        ? CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondaryContainer,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSecondaryContainer,
                            child: const Icon(Icons.star, size: 20),
                          )
                        : CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.fitness_center, size: 20),
                          ),
                    title: Text(exercise.name),
                    subtitle: Text(_buildSubtitle(exercise)),
                    onTap: () => _openHowToSheet(context, exercise),
                    trailing: IconButton(
                      tooltip: hasActive
                          ? 'Adicionar ao treino ativo'
                          : 'Nenhum treino ativo',
                      icon: Icon(
                        hasActive ? Icons.playlist_add : Icons.playlist_add_outlined,
                      ),
                      onPressed: hasActive
                          ? () async {
                              try {
                                final repo = ref.read(workoutRepoProvider);
                                await repo.addExerciseAtEnd(
                                    activeId!, exercise.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline,
                                              color: Colors.white),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '"${exercise.name}" adicionado ao treino ativo',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline,
                                              color: Colors.white),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Erro ao adicionar exercício: $e',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ========== HELPERS ==========

IconData _getGroupIcon(String groupLabel) {
  switch (groupLabel) {
    case 'Peito':
      return Icons.favorite;
    case 'Costas':
      return Icons.view_agenda;
    case 'Pernas':
      return Icons.directions_walk;
    case 'Ombros':
      return Icons.pan_tool;
    case 'Bíceps':
      return Icons.sports_martial_arts;
    case 'Tríceps':
      return Icons.sports_kabaddi;
    case 'Core':
      return Icons.center_focus_strong;
    case 'Glúteos':
      return Icons.chair;
    case 'Corpo inteiro':
      return Icons.accessibility_new;
    default:
      return Icons.fitness_center;
  }
}

/// Constrói o subtítulo de cada exercício (grupo muscular + equipamento)
String _buildSubtitle(Exercise e) {
  final g = _labelGroup(e.muscleGroup);
  final eq = (e.equipment ?? '').trim();
  if (eq.isEmpty) return g;
  
  return '$g • $eq${e.isCustom ? ' • Personalizado' : ''}';
}

/// Mapeia o nome salvo no banco (string) para um rótulo amigável
String _labelGroup(String g) {
  switch (g) {
    case 'chest':
      return 'Peito';
    case 'back':
      return 'Costas';
    case 'legs':
      return 'Pernas';
    case 'shoulders':
      return 'Ombros';
    case 'biceps':
      return 'Bíceps';
    case 'triceps':
      return 'Tríceps';
    case 'core':
      return 'Core';
    case 'glutes':
      return 'Glúteos';
    case 'fullbody':
      return 'Corpo inteiro';
    default:
      return 'Geral';
  }
}

/// Agrupa lista de exercícios por `muscleGroup`
Map<String, List<Exercise>> _groupByMuscle(List<Exercise> all) {
  final map = <String, List<Exercise>>{};
  for (final e in all) {
    (map[e.muscleGroup] ??= []).add(e);
  }
  return map;
}

/// Abre o bottom sheet com orientações de execução
void _openHowToSheet(BuildContext context, Exercise e) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _HowToSheet(exercise: e),
  );
}

/// Bottom sheet de "Como executar"
class _HowToSheet extends StatelessWidget {
  final Exercise exercise;

  const _HowToSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final title = exercise.name;
    final subtitle = _buildSubtitle(exercise);
    final tips = _buildHowTo(exercise);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.fitness_center),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Como executar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          t,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dica: priorize a técnica antes da carga. Ajuste o volume conforme o seu nível.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gera instruções básicas a partir do nome, grupo e equipamento
List<String> _buildHowTo(Exercise e) {
  final name = e.name.toLowerCase();
  final group = e.muscleGroup;

  // Regras simples por palavras-chave
  if (name.contains('supino')) {
    return [
      'Deite no banco com os pés firmes no chão e escápulas retraídas',
      'Segure a barra/halteres com pegada confortável e desça controlando',
      'Empurre de volta estendendo os cotovelos sem perder a estabilidade do tronco',
    ];
  }
  if (name.contains('remada')) {
    return [
      'Mantenha a coluna neutra e o tronco estável',
      'Puxe a barra/pegador em direção à linha do umbigo, levando os cotovelos para trás',
      'Evite "roubar" com impulso. Controle a fase excêntrica',
    ];
  }
  if (name.contains('agachamento')) {
    return [
      'Pés firmes, abdômen ativo e coluna neutra',
      'Desça levando o quadril para trás e os joelhos para fora, respeitando sua mobilidade',
      'Suba empurrando o chão e mantendo o tronco estável',
    ];
  }
  if (name.contains('elevação lateral')) {
    return [
      'Leve os halteres na linha dos ombros com leve flexão de cotovelo',
      'Evite encolher os ombros; foque nos deltoides',
      'Controle a descida para maximizar o tempo sob tensão',
    ];
  }

  // Fallback por grupo muscular
  switch (group) {
    case 'chest':
      return [
        'Mantenha escápulas fixas no banco',
        'Controlar a descida melhora a ativação do peitoral',
        'Evite hiperextensão dos ombros',
      ];
    case 'back':
      return [
        'Mantenha a coluna neutra e evite subir os ombros',
        'Concentre-se em "puxar com as costas", não apenas com os braços',
        'Controle a fase excêntrica',
      ];
    case 'legs':
      return [
        'Ative o core para estabilizar a pelve e coluna',
        'Respeite sua amplitude e evite valgo dinâmico nos joelhos',
        'Mantenha os pés firmes no chão',
      ];
    case 'shoulders':
      return [
        'Evite compensar com trapézio; foque no deltoide',
        'Amplitude confortável, sem dor no ombro',
        'Mantenha o core ativo durante o movimento',
      ];
    case 'biceps':
      return [
        'Mantenha os cotovelos estáveis ao lado do corpo',
        'Evite balanço do tronco; controle a excêntrica',
        'Foque na contração muscular',
      ];
    case 'triceps':
      return [
        'Mantenha os cotovelos apontados para frente/baixo conforme o exercício',
        'Evite abrir os cotovelos; busque o alongamento completo',
        'Controle o movimento em ambas as fases',
      ];
    case 'core':
      return [
        'Mantenha alinhamento da coluna e respiração controlada',
        'Priorize qualidade do movimento em vez de contar repetições',
        'Evite compensações com outros grupos musculares',
      ];
    case 'glutes':
      return [
        'Concentre-se na extensão do quadril, apertando os glúteos no final',
        'Evite hiperextensão lombar; mantenha o core ativo',
        'Controle o movimento completo',
      ];
    case 'fullbody':
      return [
        'Movimento composto: coordene respiração e postura',
        'Ajuste a carga para manter a técnica em todas as fases',
        'Mantenha o core sempre ativo',
      ];
    default:
      return [
        'Execute com técnica adequada e amplitude confortável',
        'Aumente a carga apenas mantendo o controle do movimento',
        'Respeite seus limites e progressão gradual',
      ];
  }
}