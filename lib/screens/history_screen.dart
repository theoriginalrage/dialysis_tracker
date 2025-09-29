import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../services/unit_service.dart';
import '../state/session_store.dart';
import '../utils/weight_utils.dart';
import 'widgets/calendar_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color _dot(String? status) => switch (status) {
        'green' => Colors.green,
        'yellow' => Colors.amber,
        'red' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionStore>().sessions;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          const CalendarHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (_, i) =>
                  _SessionTile(s: sessions[i], colorOf: _dot),
            ),
          ),
        ],
      ),
    );
  }
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

