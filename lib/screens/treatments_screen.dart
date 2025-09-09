import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

/// Show a calendar with dots on treatment days.
/// When [refreshToken] changes, this widget re-loads preferences.
class TreatmentsPage extends StatefulWidget {
  final int refreshToken; // passed from HomeShell
  const TreatmentsPage({super.key, this.refreshToken = 0});

  @override
  State<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends State<TreatmentsPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  late Future<_Schedule> _futureSchedule;

  @override
  void initState() {
    super.initState();
    _futureSchedule = _loadSchedule();
  }

  @override
  void didUpdateWidget(covariant TreatmentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the token from HomeShell changed, reload prefs.
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(() {
        _futureSchedule = _loadSchedule();
      });
    }
  }

  Future<_Schedule> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to read a canonical list of weekdays 1..7 (Mon..Sun)
    List<int>? days = prefs.getStringList('dialysis_days')?.map(int.parse).toList();

    // Back-compat: if not stored as list, reconstruct from individual booleans
    days ??= [
      if (prefs.getBool('dialysis_mon') ?? false) 1,
      if (prefs.getBool('dialysis_tue') ?? false) 2,
      if (prefs.getBool('dialysis_wed') ?? false) 3,
      if (prefs.getBool('dialysis_thu') ?? false) 4,
      if (prefs.getBool('dialysis_fri') ?? false) 5,
      if (prefs.getBool('dialysis_sat') ?? false) 6,
      if (prefs.getBool('dialysis_sun') ?? false) 7,
    ];

    // Default to Mon/Wed/Fri if nothing set yet
    if (days.isEmpty) {
      days = [1, 3, 5];
    }

    // Build marker dates for the visible month
    final firstOfMonth = DateTime(_focused.year, _focused.month, 1);
    final lastOfMonth = DateTime(_focused.year, _focused.month + 1, 0);

    final markers = <DateTime>{};
    DateTime d = firstOfMonth;
    while (!d.isAfter(lastOfMonth)) {
      if (days.contains(d.weekday)) {
        markers.add(DateTime(d.year, d.month, d.day));
      }
      d = d.add(const Duration(days: 1));
    }

    return _Schedule(days, markers);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Schedule>(
      future: _futureSchedule,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sched = snap.data!;
        return ListView(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focused,
              locale: 'en_US',
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: false),
              selectedDayPredicate: (day) => isSameDay(_selected, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selected = selectedDay;
                  _focused = focusedDay;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Selected ${DateFormat.yMMMMd().format(selectedDay)}'
                      ' – pre/post entry coming soon',
                    ),
                  ),
                );
              },
              onPageChanged: (focusedDay) {
                _focused = focusedDay;
                // When the month changes, recompute markers for that month
                setState(() {
                  _futureSchedule = _loadSchedule();
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final hasMarker = sched.markers.contains(DateTime(date.year, date.month, date.day));
                  if (!hasMarker) return const SizedBox.shrink();
                  return const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: _Dot(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const _Legend(),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Tap a date to add pre/post info (coming soon).'),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6, height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: const [
          _Dot(),
          SizedBox(width: 8),
          Text('Treatment day'),
        ],
      ),
    );
  }
}

class _Schedule {
  final List<int> weekdays;      // 1..7 (Mon..Sun)
  final Set<DateTime> markers;   // dates in current month
  _Schedule(this.weekdays, this.markers);
}

