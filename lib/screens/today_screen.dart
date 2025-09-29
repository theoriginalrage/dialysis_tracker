import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../services/unit_service.dart';
import '../state/session_store.dart';
import '../utils/weight_utils.dart';
import 'widgets/calendar_tray.dart';

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
  final _trayKey = GlobalKey<CalendarTrayState>();

  WeightUnit _unit = UnitService.instance.unit.value;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    UnitService.instance.unit.addListener(_handleUnitChange);
    _selectedDate = _normalize(DateTime.now());
  }

  @override
  void dispose() {
    UnitService.instance.unit.removeListener(_handleUnitChange);
    _preWeight.dispose();
    _preBP.dispose();
    _postBP.dispose();
    _postWeight.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  InputDecoration _dec(String label) => const InputDecoration(
        border: OutlineInputBorder(),
      ).copyWith(labelText: label);

  void _handleUnitChange() {
    if (!mounted) return;
    final nextUnit = UnitService.instance.unit.value;
    if (_unit == nextUnit) return;

    double? convertController(TextEditingController controller) {
      final raw = controller.text.trim();
      if (raw.isEmpty) return null;
      final parsed = double.tryParse(raw);
      if (parsed == null) return null;
      final kg = toKgFromInput(parsed, _unit);
      return toDisplayFromKg(kg, nextUnit);
    }

    setState(() {
      final pre = convertController(_preWeight);
      if (pre != null) {
        final formatted = pre.toStringAsFixed(1);
        _preWeight.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      final post = convertController(_postWeight);
      if (post != null) {
        final formatted = post.toStringAsFixed(1);
        _postWeight.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      _unit = nextUnit;
    });
  }

  Widget _row({
    required String label,
    required TextEditingController ctrl,
    TextInputType? kb,
    required VoidCallback onSave,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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

  void _savePreWeight() {
    final v = double.tryParse(_preWeight.text);
    if (v == null) return;
    final unit = UnitService.instance.unit.value;
    final kg = toKgFromInput(v, unit);
    context.read<SessionStore>().upsertPartial(Session(
          date: _selectedDate,
          preWeight: kg,
          preWeightAt: DateTime.now(),
        ));
  }

  void _savePreBP() {
    final v = double.tryParse(_preBP.text);
    if (v == null) return;
    context.read<SessionStore>().upsertPartial(Session(
          date: _selectedDate,
          preBP: v,
          preBPAt: DateTime.now(),
        ));
  }

  void _savePostBP() {
    final v = double.tryParse(_postBP.text);
    if (v == null) return;
    context.read<SessionStore>().upsertPartial(Session(
          date: _selectedDate,
          postBP: v,
          postBPAt: DateTime.now(),
        ));
  }

  void _savePostWeight() {
    final v = double.tryParse(_postWeight.text);
    if (v == null) return;
    final unit = UnitService.instance.unit.value;
    final kg = toKgFromInput(v, unit);
    context.read<SessionStore>().upsertPartial(Session(
          date: _selectedDate,
          postWeight: kg,
          postWeightAt: DateTime.now(),
        ));
  }

  void _saveNotes() {
    final text = _notes.text.trim();
    context.read<SessionStore>().upsertPartial(Session(
          date: _selectedDate,
          notes: text.isEmpty ? null : text,
          notesAt: DateTime.now(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final kb = const TextInputType.numberWithOptions(decimal: true);
    final unitLabel = _unit == WeightUnit.kg ? 'KG' : 'LBS';
    final selectionLabel = DateFormat('EEE, MMM d, y').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Session"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Toggle calendar',
            onPressed: () => _trayKey.currentState?.toggle(),
          ),
        ],
      ),
      body: Column(
        children: [
          CalendarTray(
            key: _trayKey,
            focusedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = _normalize(date);
              });
            },
            rangeMode: false,
            titleWhenCollapsed: selectionLabel,
            prefsKey: 'ui.tray.today',
          ),
          Expanded(
            child: ListView(
              children: [
                _row(
                  label: 'Pre-Weight ($unitLabel)',
                  ctrl: _preWeight,
                  kb: kb,
                  onSave: _savePreWeight,
                ),
                _row(
                  label: 'Pre BP (systolic)',
                  ctrl: _preBP,
                  kb: kb,
                  onSave: _savePreBP,
                ),
                _row(
                  label: 'Post BP (systolic)',
                  ctrl: _postBP,
                  kb: kb,
                  onSave: _savePostBP,
                ),
                _row(
                  label: 'Post-Weight ($unitLabel)',
                  ctrl: _postWeight,
                  kb: kb,
                  onSave: _savePostWeight,
                ),
                _row(
                  label: 'Notes (optional)',
                  ctrl: _notes,
                  onSave: _saveNotes,
                  maxLines: 3,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
