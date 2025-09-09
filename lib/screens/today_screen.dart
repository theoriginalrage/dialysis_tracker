import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../state/session_store.dart';
import 'widgets/calendar_header.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _form = GlobalKey<FormState>();
  final _preWeight = TextEditingController();
  final _preBP = TextEditingController();
  final _postBP = TextEditingController();
  final _postWeight = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _preWeight.dispose();
    _preBP.dispose();
    _postBP.dispose();
    _postWeight.dispose();
    _notes.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => const InputDecoration(
        border: OutlineInputBorder(),
      ).copyWith(labelText: label);

  String? _num(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null) return 'Enter a number';
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;

    final s = Session(
      date: DateTime.now(),
      preWeight: double.parse(_preWeight.text),
      preBP: double.parse(_preBP.text),
      postBP: double.parse(_postBP.text),
      postWeight: double.parse(_postWeight.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    context.read<SessionStore>().add(s);

    final fluid = s.fluidRemoved.toStringAsFixed(2);
    final color = switch (s.status) {
      'green' => Colors.green,
      'yellow' => Colors.amber,
      _ => Colors.red,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.circle, color: color, size: 14),
            const SizedBox(width: 8),
            Text('Saved. Fluid removed: $fluid kg'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    _form.currentState!.reset();
    _preWeight.clear();
    _preBP.clear();
    _postBP.clear();
    _postWeight.clear();
    _notes.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pad = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final kb = const TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Session")),
      body: Column(
        children: [
          const CalendarHeader(),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: pad,
                    child: TextFormField(
                      controller: _preWeight,
                      keyboardType: kb,
                      decoration: _dec('Pre-Weight (kg)'),
                      validator: _num,
                    ),
                  ),
                  Padding(
                    padding: pad,
                    child: TextFormField(
                      controller: _preBP,
                      keyboardType: kb,
                      decoration: _dec('Pre BP (sitting, systolic)'),
                      validator: _num,
                    ),
                  ),
                  Padding(
                    padding: pad,
                    child: TextFormField(
                      controller: _postBP,
                      keyboardType: kb,
                      decoration: _dec('Post BP (sitting, systolic)'),
                      validator: _num,
                    ),
                  ),
                  Padding(
                    padding: pad,
                    child: TextFormField(
                      controller: _postWeight,
                      keyboardType: kb,
                      decoration: _dec('Post-Weight (kg)'),
                      validator: _num,
                    ),
                  ),
                  Padding(
                    padding: pad,
                    child: TextFormField(
                      controller: _notes,
                      decoration: _dec('Notes (optional)'),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: pad,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Padding(
                        padding: EdgeInsets.all(14.0),
                        child:
                            Text('Save Session', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

