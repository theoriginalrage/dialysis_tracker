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

  Widget _row(
      {required String label,
      required TextEditingController ctrl,
      TextInputType? kb,
      required VoidCallback onSave,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: kb,
              decoration: _dec(label),
              maxLines: maxLines,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              onSave();
              ctrl.clear();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Saved')));
            },
          )
        ],
      ),
    );
  }

  DateTime get _today => DateTime.now();

  void _savePreWeight() {
    final v = double.tryParse(_preWeight.text);
    if (v == null) return;
    context.read<SessionStore>().upsertPartial(Session(
          date: _today,
          preWeight: v,
          preWeightAt: DateTime.now(),
        ));
  }

  void _savePreBP() {
    final v = double.tryParse(_preBP.text);
    if (v == null) return;
    context.read<SessionStore>().upsertPartial(Session(
          date: _today,
          preBP: v,
          preBPAt: DateTime.now(),
        ));
  }

  void _savePostBP() {
    final v = double.tryParse(_postBP.text);
    if (v == null) return;
    context.read<SessionStore>().upsertPartial(Session(
          date: _today,
          postBP: v,
          postBPAt: DateTime.now(),
        ));
  }

  void _savePostWeight() {
    final v = double.tryParse(_postWeight.text);
    if (v == null) return;
    context.read<SessionStore>().upsertPartial(Session(
          date: _today,
          postWeight: v,
          postWeightAt: DateTime.now(),
        ));
  }

  void _saveNotes() {
    final text = _notes.text.trim();
    context.read<SessionStore>().upsertPartial(Session(
          date: _today,
          notes: text.isEmpty ? null : text,
          notesAt: DateTime.now(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final kb = const TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Session")),
      body: Column(
        children: [
          const CalendarHeader(),
          Expanded(
            child: ListView(
              children: [
                _row(label: 'Pre-Weight (kg)', ctrl: _preWeight, kb: kb, onSave: _savePreWeight),
                _row(label: 'Pre BP (systolic)', ctrl: _preBP, kb: kb, onSave: _savePreBP),
                _row(label: 'Post BP (systolic)', ctrl: _postBP, kb: kb, onSave: _savePostBP),
                _row(label: 'Post-Weight (kg)', ctrl: _postWeight, kb: kb, onSave: _savePostWeight),
                _row(label: 'Notes (optional)', ctrl: _notes, onSave: _saveNotes, maxLines: 3),
              ],
            ),
          )
        ],
      ),
    );
  }
}
