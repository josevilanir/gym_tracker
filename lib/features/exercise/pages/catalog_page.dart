import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums.dart';
import '../../workout/controllers/providers.dart';
import '../../../data/db/app_database.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  String _query = '';
  MuscleGroup _muscle = MuscleGroup.chest;
  final _nameCtrl = TextEditingController();
  final _equipCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Exercícios'),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: repo.allExercises(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final filtered = all.where((e) {
            final q = _query.trim().toLowerCase();
            if (q.isEmpty) return true;
            return e.name.toLowerCase().contains(q);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Busca
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar por nome',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 16),

              // Lista
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: Text('Nenhum exercício encontrado.')),
                )
              else
                ...filtered.map((e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text('${e.muscleGroup} • ${e.equipment ?? '—'}${e.isCustom ? ' • custom' : ''}'),
                    )),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              Text('Adicionar exercício custom', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome do exercício'),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<MuscleGroup>(
                value: _muscle,
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
                items: MuscleGroup.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => setState(() => _muscle = v ?? MuscleGroup.chest),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _equipCtrl,
                decoration: const InputDecoration(labelText: 'Equipamento (opcional)'),
              ),
              const SizedBox(height: 12),

              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe um nome.')),
                    );
                    return;
                  }
                  await repo.createCustomExercise(
                    name: name,
                    muscle: _muscle,
                    equipment: _equipCtrl.text.trim().isEmpty ? null : _equipCtrl.text.trim(),
                  );
                  if (mounted) {
                    _nameCtrl.clear();
                    _equipCtrl.clear();
                    setState(() {}); // recarrega lista
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exercício criado!')),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
