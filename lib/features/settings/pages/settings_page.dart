// lib/features/settings/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Tema'),
              subtitle: const Text('Alternar entre claro/escuro'),
              trailing: const Icon(Icons.brightness_6),
              onTap: () => toggleTheme(ref),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Sobre'),
              subtitle: const Text('Gym Tracker • Versão 1.0 (preview)'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Gym Tracker',
                  applicationVersion: '1.0 (preview)',
                  children: const [
                    Text('Aplicativo para organizar e acompanhar treinos.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
