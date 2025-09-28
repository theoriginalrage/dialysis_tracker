import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Dark Mode'),
          value: settings.darkMode,
          onChanged: (value) => context.read<SettingsStore>().setDarkMode(value),
        ),
      ],
    );
  }
}
