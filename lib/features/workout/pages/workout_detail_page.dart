import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/rest_timer_controller.dart';
import '../../../core/enums.dart'; // MuscleGroup
import '../../../data/db/app_database.dart';
import '../../workout/controllers/providers.dart';

class WorkoutDetailPage extends ConsumerStatefulWidget {
  final String workoutId;
  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends ConsumerState<WorkoutDetailPage> {
  final GlobalKey<_DetailBodyState> _bodyKey = GlobalKey<_DetailBodyState>();

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<Workout?>(
      future: repo.getWorkout(widget.workoutId),
      builder: (context, snap) {
        final w = snap.data;
        final title = w?.title ?? 'Treino';
        final date = w == null
            ? ''
            : DateFormat('dd/MM/yyyy HH:mm')
                .format(DateTime.fromMillisecondsSinceEpoch(w.dateEpoch));

        return Scaffold(
          appBar: AppBar(
          title: Text('$title ($date)'),
          actions: [
            // Botão: salvar treino como rotina
            IconButton(
              tooltip: 'Salvar como rotina',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () async {
                final nameCtrl = TextEditingController(text: title);
                final name = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                  title: const Text('Salvar rotina'),
                  content: TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome da rotina'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () =>
                    Navigator.pop(ctx, nameCtrl.text.trim()),
                    child: const Text('Salvar'),
                    ),
                    ],
                  ),
                );

            if (name != null && name.isNotEmpty) {
              await repo.saveWorkoutAsTemplate(
                workoutId: widget.workoutId,
                name: name,
              );
            if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rotina salva!')),
              );
            }
          },
        ),

    // Botão: concluir treino
    IconButton(
      tooltip: 'Concluir treino',
      icon: const Icon(Icons.check),
      onPressed: () async {
        await repo.markDone(widget.workoutId, true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino concluído!')),
        );
        Navigator.pop(context); 
      },
    ),
  ],
),
          body: _DetailBody(key: _bodyKey, workoutId: widget.workoutId),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar exercício'),
            onPressed: () => _bodyKey.currentState?.openAddExerciseDialog(),
          ),
          bottomNavigationBar: const RestTimerBar(),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  final String workoutId;
  const _DetailBody({super.key, required this.workoutId});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  List<WorkoutExercise> _list = [];
  double _volume = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final repo = ref.read(workoutRepoProvider);
    final list = await repo.listWorkoutExercises(widget.workoutId);
    final vol = await repo.computeWorkoutVolume(widget.workoutId);
    if (!mounted) return;
    setState(() {
      _list = List.of(list);
      _volume = vol;
    });
  }

  Future<void> _persistOrder() async {
    final repo = ref.read(workoutRepoProvider);
    await repo.reorderExercises(_list);
  }

  // ====== adicionar exercício (com criação de custom) ======
  Future<void> openAddExerciseDialog() async {
    final repo = ref.read(workoutRepoProvider);
    List<Exercise> all = await repo.allExercises();
    final searchCtrl = TextEditingController();
    Exercise? selected;

    Future<void> refreshAll() async {
      all = await repo.allExercises();
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        var filtered = all;
        return StatefulBuilder(
          builder: (ctx, setState) {
            void applyFilter() {
              final q = searchCtrl.text.trim().toLowerCase();
              filtered = q.isEmpty
                  ? all
                  : all.where((e) => e.name.toLowerCase().contains(q)).toList();
              setState(() {});
            }

            Future<void> createCustomFlow() async {
              final nameCtrl = TextEditingController();
              MuscleGroup muscle = MuscleGroup.chest;
              final equipCtrl = TextEditingController();

              final createdId = await showDialog<String>(
                context: ctx,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Novo exercício'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<MuscleGroup>(
                        value: muscle,
                        decoration: const InputDecoration(labelText: 'Grupo muscular'),
                        items: MuscleGroup.values
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                            .toList(),
                        onChanged: (v) => muscle = v ?? MuscleGroup.chest,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: equipCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Equipamento (opcional)'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancelar')),
                    FilledButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final id = await repo.createCustomExercise(
                          name: name,
                          muscle: muscle,
                          equipment: equipCtrl.text.trim().isEmpty
                              ? null
                              : equipCtrl.text.trim(),
                        );
                        Navigator.pop(ctx2, id);
                      },
                      child: const Text('Criar'),
                    ),
                  ],
                ),
              );

              if (createdId != null) {
                await refreshAll();
                applyFilter();
                selected = all.firstWhere(
                  (e) => e.id == createdId,
                  orElse: () => filtered.first,
                );
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exercício criado!')),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Adicionar exercício'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Buscar',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => applyFilter(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Exercise>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Selecione'),
                    items: filtered
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Novo exercício'),
                      onPressed: createCustomFlow,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar')),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          await repo.addExerciseAtEnd(widget.workoutId, selected!.id);
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          await reload();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${selected!.name} adicionado!')),
                          );
                        },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    searchCtrl.dispose();
  }

@override
Widget build(BuildContext context) {
    // pegue o repositório via Riverpod
    final repo = ref.read(workoutRepoProvider);

    if (_list.isEmpty) {
      return const Center(child: Text('Sem exercícios neste treino.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Volume total: ${_volume.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // lista reordenável de exercícios
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _list.length,
          onReorder: (oldIndex, newIndex) async {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _list.removeAt(oldIndex);
              _list.insert(newIndex, item);
            });
            await _persistOrder();
          },
          itemBuilder: (context, i) {
            final we = _list[i];

            return Padding(
              key: ValueKey(we.id), // chave usada pelo Reorderable
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey('dismiss-${we.id}'), // chave do swipe
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: Colors.red.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                confirmDismiss: (_) async {
                  // diálogo rápido de confirmação (opcional)
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remover exercício'),
                          content: const Text('Tem certeza que deseja remover este exercício da rotina?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remover'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  // remove no banco
                  await repo.deleteWorkoutExercise(we.id);

                  // atualiza a UI localmente para dar sensação de velocidade
                  setState(() {
                    _list.removeWhere((e) => e.id == we.id);
                  });

                  // recarrega dos dados e re-calcula volume, se seu reload fizer isso
                  await reload();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exercício removido da rotina.')),
                    );
                  }
                },
                child: _ExerciseTile(
                  we: we,
                  onChanged: reload, // mantém seu fluxo atual de atualização
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Barra fixa com controles do Timer de descanso
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(restTimerProvider);
    final ctrl = ref.read(restTimerProvider.notifier);

    // Mostrar a barra apenas quando houver algo a exibir (rodando ou pausado)
    final visible = st.running || st.remaining > 0;

    if (!visible) {
      // Dica rápida para iniciar: atalhos 45/60/90
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: 
            Row(
              children: [
                const Text('Descanso rápido:'),
                const SizedBox(width: 8),
                for (final sec in const [45, 60, 90])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: () => ctrl.start(sec),
                      child: Text('${sec}s'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              // Tempo (ex: 00:45)
                  SizedBox(
                    width: 60,
                    child: Text(
                      st.label, // ← usa o label do estado atual do timer
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),

                // Barra de progresso
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LinearProgressIndicator(
                      value: st.progress,
                      minHeight: 4,
                    ),
                  ),
                ),

              // Botões de controle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (st.running)
                      IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: ctrl.pause,
                      )
                    else if (st.remaining > 0)
                      IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: ctrl.resume,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: ctrl.stop,
                      ),
                    ],
                  ),
                ],
              )
            ),
          );
        }
      }

class _ExerciseTile extends ConsumerStatefulWidget {
  final WorkoutExercise we;
  final Future<void> Function() onChanged;
  const _ExerciseTile({required this.we, required this.onChanged});

  @override
  ConsumerState<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends ConsumerState<_ExerciseTile> {
  final _repsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<Exercise?>(
      future: repo.getExercise(widget.we.exerciseId),
      builder: (context, snapEx) {
        final ex = snapEx.data;
        final isDone = widget.we.done;
        final isCustom = ex?.isCustom ?? false;

        return Card(
          color: isDone ? Colors.green.shade50 : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do exercício
                Row(
                  children: [
                    const Icon(Icons.drag_handle),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            ex?.name ?? 'Exercício',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isCustom)
                            const Chip(
                              label: Text('custom'),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: isDone,
                      onChanged: (v) async {
                        await repo.setExerciseDone(widget.we.id, v ?? false);
                        if (!mounted) return;
                        await widget.onChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${ex?.name ?? "Exercício"} ${v == true ? "concluído" : "reaberto"}',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Lista de séries (com excluir)
                FutureBuilder<List<SetEntry>>(
                  future: repo.listSets(widget.we.id),
                  builder: (context, snapSets) {
                    final sets = snapSets.data ?? [];

                    return Column(
                      children: [
                        if (sets.isNotEmpty)
                          Column(
                            children: sets.map((s) {
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(child: Text('${s.setIndex}')),
                                title: Text('Reps: ${s.reps}'),
                                subtitle: Text('Peso: ${s.weight.toStringAsFixed(1)} kg'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Remover série',
                                  onPressed: () async {
                                    // confirmação rápida (opcional)
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remover série'),
                                        content: Text(
                                          'Remover a série ${s.setIndex} (${s.reps} reps, ${s.weight.toStringAsFixed(1)} kg)?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Remover'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;

                                    await repo.deleteSet(s.id);
                                    if (!mounted) return;
                                    await widget.onChanged(); // recarrega lista e volume

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Série removida.')),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 8),

                        // Adicionar nova série
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _repsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Reps'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: TextField(
                                controller: _weightCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                                ),
                            ),
                            const SizedBox(width: 12),
                      // Botão Adicionar (SEM iniciar o timer automaticamente)
                            FilledButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text(''),
                                onPressed: () async {
                              final reps = int.tryParse(_repsCtrl.text.trim());
                              final weight = double.tryParse(
                                _weightCtrl.text.trim().replaceAll(',', '.'),
                              );

                              if (reps == null || weight == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Informe reps e peso válidos.')),
                              );
                            return;
                            }

                            await repo.addSetQuick(
                              workoutExerciseId: widget.we.id,
                              reps: reps,
                              weight: weight,
                            );

                            if (!mounted) return;

                            _repsCtrl.clear();
                            _weightCtrl.clear();

                            await widget.onChanged();
                            },
                            ),
                              const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
