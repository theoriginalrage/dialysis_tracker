import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../services/unit_service.dart';
import '../state/session_store.dart';
import '../utils/weight_utils.dart';
import 'widgets/calendar_tray.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _trayKey = GlobalKey<CalendarTrayState>();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalize(DateTime.now());
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionStore>().sessions;
    final filtered = sessions
        .where((s) => _sameDay(s.date, _selectedDate))
        .toList();
    final selectionLabel = DateFormat('EEE, MMM d, y').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
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
            prefsKey: 'ui.tray.history',
          ),
          Expanded(
            child: filtered.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No sessions recorded for this day'),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) =>
                        _SessionTile(s: filtered[i], colorOf: _dot),
                  ),
          ),
        ],
      ),
    );
  }

  Color _dot(String? status) => switch (status) {
        'green' => Colors.green,
        'yellow' => Colors.amber,
        'red' => Colors.red,
        _ => Colors.grey,
      };
}

class _SessionTile extends StatefulWidget {
  final Session s;
  final Color Function(String?) colorOf;
  const _SessionTile({required this.s, required this.colorOf});

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final d = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-'
        '${s.date.day.toString().padLeft(2, '0')}';

    return ValueListenableBuilder<WeightUnit>(
      valueListenable: UnitService.instance.unit,
      builder: (_, unit, __) {
        final fluid = s.fluidRemoved;
        final fluidText =
            fluid != null ? formatWeight(fluid, unit) : '—';
        final preText =
            s.preWeight != null ? formatWeight(s.preWeight!, unit) : '—';
        final postText =
            s.postWeight != null ? formatWeight(s.postWeight!, unit) : '—';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle,
                          size: 12, color: widget.colorOf(s.status)),
                      const SizedBox(width: 8),
                      Text(d,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(fluidText == '—' ? '∆Wt: —' : '∆Wt: $fluidText'),
                    ],
                  ),
                  if (_open) const SizedBox(height: 8),
                  if (_open)
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyMedium!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pre-Weight: $preText'),
                          Text('Post-Weight: $postText'),
                          Text('Pre BP: ${s.preBP ?? '—'}'),
                          Text('Post BP: ${s.postBP ?? '—'}'),
                          if (s.notes != null && s.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Notes: ${s.notes}'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
