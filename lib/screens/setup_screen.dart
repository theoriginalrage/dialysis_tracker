import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../state/settings_store.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final Set<int> _days = {}; // DateTime.monday..sunday

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggle(int weekday) {
    setState(() {
      if (_days.contains(weekday)) {
        _days.remove(weekday);
      } else {
        _days.add(weekday);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const wdays = <int, String>{
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Let's set up your profile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Your name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Which days are your dialysis days?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: wdays.entries.map((e) {
                final selected = _days.contains(e.key);
                return FilterChip(
                  selected: selected,
                  label: Text(e.value),
                  onSelected: (_) => _toggle(e.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (_days.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Pick at least one dialysis day')));
                  return;
                }
                final profile = Profile(
                  name: _name.text.trim(),
                  dialysisWeekdays: _days.toList()..sort(),
                );
                await context.read<SettingsStore>().saveProfile(profile);
              },
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

