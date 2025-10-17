// lib/features/workout/pages/workout_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/rest_timer_controller.dart';
import '../../../core/enums.dart';
import '../../../core/constants.dart';
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
            : DateFormat(AppConstants.dateTimeFormatFull)
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
                        maxLength: AppConstants.maxWorkoutTitleLength,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
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
                      SnackBar(
                        content: Text(AppConstants.successTemplateCreated),
                        duration: AppConstants.snackBarSuccessDuration,
                      ),
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
                    SnackBar(
                      content: Text(AppConstants.successWorkoutCompleted),
                      duration: AppConstants.snackBarSuccessDuration,
                    ),
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
                        maxLength: AppConstants.maxExerciseNameLength,
                      ),
                      SizedBox(height: UIConstants.paddingS),
                      DropdownButtonFormField<MuscleGroup>(
                        value: muscle,
                        decoration: const InputDecoration(labelText: 'Grupo muscular'),
                        items: MuscleGroup.values
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                            .toList(),
                        onChanged: (v) => muscle = v ?? MuscleGroup.chest,
                      ),
                      SizedBox(height: UIConstants.paddingS),
                      TextField(
                        controller: equipCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Equipamento (opcional)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: const Text('Cancelar'),
                    ),
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
                    SnackBar(
                      content: Text(AppConstants.successExerciseCreated),
                      duration: AppConstants.snackBarSuccessDuration,
                    ),
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
                  SizedBox(height: UIConstants.paddingM),
                  DropdownButtonFormField<Exercise>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Selecione'),
                    items: filtered
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  SizedBox(height: UIConstants.paddingS),
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
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          await repo.addExerciseAtEnd(widget.workoutId, selected!.id);
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          await reload();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppConstants.successExerciseAdded),
                              duration: AppConstants.snackBarSuccessDuration,
                            ),
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
    final repo = ref.read(workoutRepoProvider);

    if (_list.isEmpty) {
      return const Center(child: Text('Sem exercícios neste treino.'));
    }

    return ListView(
      padding: PaddingConstants.allL,
      children: [
        Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: PaddingConstants.allL,
            child: Text(
              'Volume total: ${_volume.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SizedBox(height: UIConstants.paddingL),

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
              key: ValueKey(we.id),
              padding: EdgeInsets.only(bottom: UIConstants.paddingM),
              child: Dismissible(
                key: ValueKey('dismiss-${we.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: Colors.red.withOpacity(0.12),
                  padding: PaddingConstants.horizontalL,
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remover exercício'),
                          content: const Text(
                            'Tem certeza que deseja remover este exercício da rotina?',
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
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  await repo.deleteWorkoutExercise(we.id);

                  setState(() {
                    _list.removeWhere((e) => e.id == we.id);
                  });

                  await reload();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exercício removido da rotina.'),
                      ),
                    );
                  }
                },
                child: _ExerciseTile(
                  we: we,
                  onChanged: reload,
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

    final visible = st.running || st.remaining > 0;

    if (!visible) {
      return SafeArea(
        child: Padding(
          padding: PaddingConstants.horizontalM.copyWith(
            bottom: UIConstants.paddingS,
          ),
          child: Row(
            children: [
              const Text('Descanso rápido:'),
              SizedBox(width: UIConstants.paddingS),
              for (final sec in AppConstants.restTimerQuickOptions)
                Padding(
                  padding: EdgeInsets.only(right: UIConstants.paddingS),
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
        margin: PaddingConstants.horizontalM.copyWith(
          bottom: UIConstants.paddingS,
        ),
        padding: PaddingConstants.horizontalM.copyWith(
          top: UIConstants.paddingS,
          bottom: UIConstants.paddingS,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                st.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: PaddingConstants.horizontalM,
                child: LinearProgressIndicator(
                  value: st.progress,
                  minHeight: 4,
                ),
              ),
            ),
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
        ),
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

  /// Validação de reps
  String? _validateReps(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o número de reps';
    }

    final reps = int.tryParse(value.trim());
    if (reps == null) {
      return 'Valor inválido';
    }

    if (reps < AppConstants.minReps) {
      return 'Mínimo: ${AppConstants.minReps}';
    }

    if (reps > AppConstants.maxReps) {
      return 'Máximo: ${AppConstants.maxReps}';
    }

    return null;
  }

  /// Validação de peso
  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o peso';
    }

    final weight = double.tryParse(value.trim().replaceAll(',', '.'));
    if (weight == null) {
      return 'Valor inválido';
    }

    if (weight < AppConstants.minWeight) {
      return 'Mínimo: ${AppConstants.minWeight} kg';
    }

    if (weight > AppConstants.maxWeight) {
      return 'Máximo: ${AppConstants.maxWeight} kg';
    }

    return null;
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
            padding: PaddingConstants.allM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do exercício
                Row(
                  children: [
                    const Icon(Icons.drag_handle),
                    SizedBox(width: UIConstants.paddingS),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: UIConstants.paddingS,
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
                            duration: AppConstants.snackBarSuccessDuration,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: UIConstants.paddingS),

                // Lista de séries (com excluir e nota)
                FutureBuilder<List<SetEntry>>(
                  future: repo.listSets(widget.we.id),
                  builder: (context, setsSnap) {
                    final sets = setsSnap.data ?? [];

                    return Column(
                      children: [
                        if (sets.isNotEmpty)
                          Column(
                            children: sets.map((s) {
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  child: Text('${s.setIndex}'),
                                ),
                                title: Text('Reps: ${s.reps}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Peso: ${s.weight.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg',
                                    ),
                                    if ((s.note ?? '').trim().isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: UIConstants.paddingXS,
                                        ),
                                        child: Text(
                                          'Nota: ${s.note!.trim()}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Adicionar nota',
                                      icon: const Icon(Icons.edit_note_outlined),
                                      onPressed: () async {
                                        final controller = TextEditingController(
                                          text: s.note ?? '',
                                        );
                                        final newNote = await showDialog<String?>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Nota da série'),
                                            content: TextField(
                                              controller: controller,
                                              maxLines: 3,
                                              maxLength: AppConstants.maxNoteLength,
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Ex.: pegada aberta, falha na 9ª rep, dor leve...',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, null),
                                                child: const Text('Cancelar'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.pop(
                                                  ctx,
                                                  controller.text.trim(),
                                                ),
                                                child: const Text('Salvar'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (newNote != null) {
                                          await repo.updateSetNote(
                                            s.id,
                                            newNote.isEmpty ? null : newNote,
                                          );
                                          if (!mounted) return;
                                          await widget.onChanged();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Nota salva.'),
                                              duration: AppConstants.snackBarSuccessDuration,
                                            ),
                                          );
                                        }
                                      },
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Remover série',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Remover série'),
                                            content: Text(
                                              'Remover a série ${s.setIndex} (${s.reps} reps, ${s.weight.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg)?',
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
                                        await widget.onChanged();

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Série removida.'),
                                            duration: AppConstants.snackBarSuccessDuration,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                        SizedBox(height: UIConstants.paddingS),

                        // Adicionar nova série COM VALIDAÇÃO
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _repsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Reps',
                                  helperText:
                                      '${AppConstants.minReps}-${AppConstants.maxReps}',
                                  errorMaxLines: 2,
                                ),
                                validator: _validateReps,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                            ),
                            SizedBox(width: UIConstants.paddingM),
                            Expanded(
                              child: TextFormField(
                                controller: _weightCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Peso (kg)',
                                  helperText:
                                      '${AppConstants.minWeight}-${AppConstants.maxWeight}',
                                  errorMaxLines: 2,
                                ),
                                validator: _validateWeight,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                            ),
                            SizedBox(width: UIConstants.paddingM),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text(''),
                              onPressed: () async {
                                // Valida antes de salvar
                                final repsError = _validateReps(_repsCtrl.text);
                                final weightError = _validateWeight(_weightCtrl.text);

                                if (repsError != null || weightError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        repsError ??
                                            weightError ??
                                            AppConstants.errorInvalidReps,
                                      ),
                                      duration: AppConstants.snackBarErrorDuration,
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                  return;
                                }

                                final reps = int.parse(_repsCtrl.text.trim());
                                final weight = double.parse(
                                  _weightCtrl.text.trim().replaceAll(',', '.'),
                                );

                                await repo.addSetQuick(
                                  workoutExerciseId: widget.we.id,
                                  reps: reps,
                                  weight: weight,
                                );

                                if (!mounted) return;

                                _repsCtrl.clear();
                                _weightCtrl.clear();

                                await widget.onChanged();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppConstants.successSetAdded),
                                    duration: AppConstants.snackBarSuccessDuration,
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: UIConstants.paddingS),
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