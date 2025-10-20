// lib/features/workout/pages/history/dialogs/register_past_workout_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/validators.dart';
import '../../../../../core/constants.dart';
import '../../../controllers/providers.dart';
import '../../../../../data/db/app_database.dart';

Future<void> showRegisterPastWorkoutDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final repo = ref.read(workoutRepoProvider);
  final now = DateTime.now();
  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();

  DateTime selected = DateTime(now.year, now.month, now.day, now.hour, now.minute);

  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: FutureBuilder<List<Template>>(
            future: repo.listTemplates(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snap.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar rotinas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final templates = snap.data ?? [];

              return StatefulBuilder(
                builder: (context, setLocal) {
                  return SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Registrar treino em outra data',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Título (opcional)',
                              hintText: 'Ex: Treino de pernas intenso',
                              prefixIcon: const Icon(Icons.title),
                              helperText: 'Deixe vazio para título automático',
                              counterText:
                                  '${titleCtrl.text.length}/${AppConstants.maxWorkoutTitleLength}',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: AppConstants.maxWorkoutTitleLength,
                            validator: Validators.workoutTitle,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onChanged: (_) => setLocal(() {}),
                          ),
                          const SizedBox(height: 12),

                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.event),
                              title: Text(
                                DateFormat('dd/MM/yyyy – HH:mm').format(selected),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Toque para alterar data e hora'),
                              trailing: const Icon(Icons.edit),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(now.year - 2),
                                  lastDate: DateTime(now.year + 1),
                                  initialDate: selected,
                                );
                                if (d == null) return;

                                if (!context.mounted) return;
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(selected),
                                );

                                setLocal(() {
                                  selected = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    t?.hour ?? selected.hour,
                                    t?.minute ?? selected.minute,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Começar usando uma rotina?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),

                          if (templates.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.bookmark_add_outlined,
                                      size: 48,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Nenhuma rotina salva',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Você pode registrar um treino vazio',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...templates.map((t) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.bookmark_outlined),
                                    title: Text(t.name),
                                    trailing: TextButton(
                                      child: const Text('Usar'),
                                      onPressed: () async {
                                        try {
                                          final titleValue = titleCtrl.text.trim();
                                          if (titleValue.isNotEmpty) {
                                            final error = Validators.workoutTitle(titleValue);
                                            if (error != null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(error),
                                                  backgroundColor:
                                                      Theme.of(context).colorScheme.error,
                                                ),
                                              );
                                              return;
                                            }
                                          }

                                          final wid = await repo.createWorkoutFromTemplateAt(
                                            templateId: t.id,
                                            date: selected,
                                            title: titleValue.isEmpty ? t.name : titleValue,
                                            done: false,
                                          );

                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                          context.pushNamed(
                                            'workout_detail',
                                            pathParameters: {'id': wid},
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text('Erro ao criar treino: $e'),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  Theme.of(context).colorScheme.error,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                )),

                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          FilledButton.icon(
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Registrar treino nessa data'),
                            onPressed: () async {
                              try {
                                final titleValue = titleCtrl.text.trim();
                                if (titleValue.isNotEmpty) {
                                  final error = Validators.workoutTitle(titleValue);
                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor:
                                            Theme.of(context).colorScheme.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                final wid = await repo.createWorkoutAt(
                                  date: selected,
                                  title: titleValue.isEmpty ? null : titleValue,
                                  done: false,
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                context.pushNamed(
                                  'workout_detail',
                                  pathParameters: {'id': wid},
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text('Erro ao criar treino: $e'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                    duration: AppConstants.snackBarErrorDuration,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Erro ao abrir formulário: $e')),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}