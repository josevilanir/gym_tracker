import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums.dart';
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
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];

          if (all.isEmpty) {
            return const Center(child: Text('Nenhum exercício cadastrado.'));
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

  void _openCreateExerciseDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    MuscleGroup? selectedGroup;
    String? equipment;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo exercício'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do exercício',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MuscleGroup>(
                    value: selectedGroup,
                    decoration: const InputDecoration(labelText: 'Grupo muscular'),
                    items: MuscleGroup.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(_labelGroup(g.name)),
                            ))
                        .toList(),
                    onChanged: (g) => setState(() => selectedGroup = g),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Equipamento (opcional)',
                      hintText: 'Ex.: Barbell, Dumbbell, Máquina…',
                    ),
                    onChanged: (v) => equipment = v.trim().isEmpty ? null : v.trim(),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty || selectedGroup == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe nome e grupo muscular.')),
                );
                return;
              }
              final repo = ref.read(workoutRepoProvider);
              await repo.createCustomExercise(
                name: name,
                muscle: selectedGroup!,
                equipment: equipment,
              );
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exercício "$name" criado.')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
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
              child: Text(
                groupLabel,
                style: Theme.of(context).textTheme.titleMedium,
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
                    title: Text(exercise.name),
                    subtitle: Text(_buildSubtitle(exercise)),
                    onTap: () => _openHowToSheet(context, exercise),
                    trailing: IconButton(
                      tooltip: hasActive
                          ? 'Adicionar ao treino ativo'
                          : 'Nenhum treino ativo',
                      icon: const Icon(Icons.playlist_add),
                      onPressed: hasActive
                          ? () async {
                              final repo = ref.read(workoutRepoProvider);
                              await repo.addExerciseAtEnd(activeId!, exercise.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '"${exercise.name}" adicionado ao treino ativo.',
                                    ),
                                  ),
                                );
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

/// ---------- Helpers / How-to ----------

/// Constrói o subtítulo de cada exercício (grupo muscular + equipamento)
String _buildSubtitle(Exercise e) {
  final g = _labelGroup(e.muscleGroup);
  final eq = (e.equipment ?? '').trim();
  return eq.isEmpty ? g : '$g • $eq';
}

/// Mapeia o nome salvo no banco (string) para um rótulo amigável.
/// Cobre todos os valores conhecidos e ainda lida com futuros valores com `default`.
String _labelGroup(String g) {
  // Tenta casar com o enum (caso o nome salvo seja exatamente MuscleGroup.x.name)
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
      // fallback para valores não previstos
      return 'Geral';
  }
}

/// Agrupa lista de exercícios por `muscleGroup` (string salva no banco)
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
                const Icon(Icons.fitness_center),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text('Como executar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(t)),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Text(
              'Dica: priorize a técnica antes da carga. Ajuste o volume conforme o seu nível.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
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
      'Deite no banco com os pés firmes no chão e escápulas retraídas.',
      'Segure a barra/halteres com pegada confortável e desça controlando.',
      'Empurre de volta estendendo os cotovelos sem perder a estabilidade do tronco.',
    ];
  }
  if (name.contains('remada')) {
    return [
      'Mantenha a coluna neutra e o tronco estável.',
      'Puxe a barra/pegador em direção à linha do umbigo, levando os cotovelos para trás.',
      'Evite “roubar” com impulso. Controle a fase excêntrica.',
    ];
  }
  if (name.contains('agachamento')) {
    return [
      'Pés firmes, abdômen ativo e coluna neutra.',
      'Desça levando o quadril para trás e os joelhos para fora, respeitando sua mobilidade.',
      'Suba empurrando o chão e mantendo o tronco estável.',
    ];
  }
  if (name.contains('elevação lateral')) {
    return [
      'Leve os halteres na linha dos ombros com leve flexão de cotovelo.',
      'Evite encolher os ombros; foque nos deltoides.',
      'Controle a descida para maximizar o tempo sob tensão.',
    ];
  }

  // Fallback por grupo muscular
  switch (group) {
    case 'chest':
      return [
        'Mantenha escápulas fixas no banco.',
        'Controlar a descida melhora a ativação do peitoral.',
      ];
    case 'back':
      return [
        'Mantenha a coluna neutra e evite subir os ombros.',
        'Concentre-se em “puxar com as costas”, não apenas com os braços.',
      ];
    case 'legs':
      return [
        'Ative o core para estabilizar a pelve e coluna.',
        'Respeite sua amplitude e evite valgo dinâmico nos joelhos.',
      ];
    case 'shoulders':
      return [
        'Evite compensar com trapézio; foque no deltoide.',
        'Amplitude confortável, sem dor no ombro.',
      ];
    case 'biceps':
      return [
        'Mantenha os cotovelos estáveis ao lado do corpo.',
        'Evite balanço do tronco; controle a excêntrica.',
      ];
    case 'triceps':
      return [
        'Mantenha os cotovelos apontados para frente/baixo conforme o exercício.',
        'Evite abrir os cotovelos; busque o alongamento completo.',
      ];
    case 'core':
      return [
        'Mantenha alinhamento da coluna e respiração controlada.',
        'Priorize qualidade do movimento em vez de contar repetições.',
      ];
    case 'glutes':
      return [
        'Concentre-se na extensão do quadril, apertando os glúteos no final.',
        'Evite hiperextensão lombar; mantenha o core ativo.',
      ];
    case 'fullbody':
      return [
        'Movimento composto: coordene respiração e postura.',
        'Ajuste a carga para manter a técnica em todas as fases.',
      ];
    default:
      return [
        'Execute com técnica adequada e amplitude confortável.',
        'Aumente a carga apenas mantendo o controle do movimento.',
      ];
  }
}
