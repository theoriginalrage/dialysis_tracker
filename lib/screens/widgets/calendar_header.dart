import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../state/session_store.dart';
import '../../state/settings_store.dart';

class CalendarHeader extends StatefulWidget {
  const CalendarHeader({super.key});

  @override
  State<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<CalendarHeader> {
  DateTime _focused = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionStore>().sessions;
    final profile = context.watch<SettingsStore>().profile;

    // Sessions per day
    final Map<DateTime, int> sessionCount = {};
    for (final s in sessions) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      sessionCount[d] = (sessionCount[d] ?? 0) + 1;
    }

    bool isDialysisWeekday(DateTime d) =>
        profile?.dialysisWeekdays.contains(d.weekday) ?? false;

    return TableCalendar(
      firstDay: DateTime.utc(2022, 1, 1),
      lastDay: DateTime.utc(2032, 12, 31),
      focusedDay: _focused,
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final dd = DateTime(day.year, day.month, day.day);
          final hasSession = sessionCount.containsKey(dd);
          final isDialysisDay = isDialysisWeekday(day);
          if (!hasSession && !isDialysisDay) return null;

          // session dot = filled; dialysis day (no session) = hollow
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(
                Icons.circle,
                size: 6,
                color: hasSession ? Colors.teal : Colors.teal.withOpacity(0.35),
              ),
            ),
          );
        },
      ),
      onPageChanged: (f) => setState(() => _focused = f),
    );
  }
}

