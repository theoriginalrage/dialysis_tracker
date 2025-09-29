import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/session.dart';
import '../../state/session_store.dart';
import '../../state/settings_store.dart';

class CalendarTray extends StatefulWidget {
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool rangeMode;
  final DateTime? rangeStart, rangeEnd;
  final ValueChanged<DateTimeRange?>? onRangeSelected;
  final String titleWhenCollapsed;
  final String prefsKey;

  const CalendarTray({
    super.key,
    required this.focusedDate,
    required this.onDateSelected,
    this.rangeMode = false,
    this.rangeStart,
    this.rangeEnd,
    this.onRangeSelected,
    required this.titleWhenCollapsed,
    required this.prefsKey,
  });

  @override
  CalendarTrayState createState() => CalendarTrayState();
}

class CalendarTrayState extends State<CalendarTray> with TickerProviderStateMixin {
  bool _open = false;
  late DateTime _currentFocused;
  SharedPreferences? _prefs;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _currentFocused = _normalize(widget.focusedDate);
    _loadOpenState();
  }

  @override
  void didUpdateWidget(covariant CalendarTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.focusedDate, widget.focusedDate)) {
      _currentFocused = _normalize(widget.focusedDate);
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOpenState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _prefs = prefs;
    final stored = prefs.getBool(widget.prefsKey);
    setState(() {
      _open = stored ?? false;
    });
  }

  Future<void> _setOpen(bool value) async {
    _collapseTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _open = value;
    });
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(widget.prefsKey, value);
  }

  void toggle() => _setOpen(!_open);

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _setOpen(false);
      }
    });
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  Iterable<DateTime> _sessionDays(List<Session> sessions) sync* {
    for (final s in sessions) {
      yield _normalize(s.date);
    }
  }

  bool _isRangeSelected(Duration duration) {
    if (widget.rangeStart == null || widget.rangeEnd == null) return false;
    final start = _normalize(widget.rangeStart!);
    final end = _normalize(widget.rangeEnd!);
    final diff = end.difference(start).inDays;
    return diff == duration.inDays - 1;
  }

  Future<void> _handleQuickRange(Duration? duration) async {
    if (widget.onRangeSelected == null) return;
    if (duration == null) {
      widget.onRangeSelected!(null);
      _scheduleCollapse();
      return;
    }
    final anchor = _normalize(widget.rangeEnd ?? DateTime.now());
    final end = anchor;
    final start = _normalize(anchor.subtract(Duration(days: duration.inDays - 1)));
    widget.onRangeSelected!(DateTimeRange(start: start, end: end));
    _scheduleCollapse();
  }

  Future<void> _showCustomRangePicker(BuildContext context) async {
    if (widget.onRangeSelected == null) return;
    final initialRange = widget.rangeStart != null && widget.rangeEnd != null
        ? DateTimeRange(start: widget.rangeStart!, end: widget.rangeEnd!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      final normalized = DateTimeRange(
        start: _normalize(picked.start),
        end: _normalize(picked.end),
      );
      widget.onRangeSelected!(normalized);
      _scheduleCollapse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionStore>().sessions;
    final dialysisDays = context.watch<SettingsStore>().dialysisWeekdays;

    final sessionCount = <DateTime, int>{};
    for (final day in _sessionDays(sessions)) {
      sessionCount[day] = (sessionCount[day] ?? 0) + 1;
    }

    bool isDialysisWeekday(DateTime d) => dialysisDays.contains(d.weekday);

    final quickChips = widget.rangeMode && !_open
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickChip(
                  label: '7d',
                  selected: _isRangeSelected(const Duration(days: 7)),
                  onPressed: () => _handleQuickRange(const Duration(days: 7)),
                ),
                _QuickChip(
                  label: '30d',
                  selected: _isRangeSelected(const Duration(days: 30)),
                  onPressed: () => _handleQuickRange(const Duration(days: 30)),
                ),
                _QuickChip(
                  label: '90d',
                  selected: _isRangeSelected(const Duration(days: 90)),
                  onPressed: () => _handleQuickRange(const Duration(days: 90)),
                ),
                _QuickChip(
                  label: 'All',
                  selected: widget.rangeStart == null && widget.rangeEnd == null,
                  onPressed: () => _handleQuickRange(null),
                ),
                _QuickChip(
                  label: 'Custom…',
                  selected: false,
                  onPressed: () => _showCustomRangePicker(context),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _setOpen(!_open),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.titleWhenCollapsed,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            vsync: this,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2022, 1, 1),
                      lastDay: DateTime.utc(2032, 12, 31),
                      focusedDay: _currentFocused,
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      availableGestures: AvailableGestures.horizontalSwipe,
                      selectedDayPredicate: widget.rangeMode
                          ? null
                          : (day) => isSameDay(_normalize(widget.focusedDate), day),
                      rangeSelectionMode: widget.rangeMode
                          ? RangeSelectionMode.toggledOn
                          : RangeSelectionMode.toggledOff,
                      rangeStartDay: widget.rangeStart != null ? _normalize(widget.rangeStart!) : null,
                      rangeEndDay: widget.rangeEnd != null ? _normalize(widget.rangeEnd!) : null,
                      onDaySelected: widget.rangeMode
                          ? null
                          : (selectedDay, focusedDay) {
                              final normalized = _normalize(selectedDay);
                              widget.onDateSelected(normalized);
                              _currentFocused = _normalize(focusedDay);
                              _scheduleCollapse();
                            },
                      onRangeSelected: widget.rangeMode
                          ? (start, end, focusedDay) {
                              if (start != null && end != null) {
                                widget.onRangeSelected?.call(
                                  DateTimeRange(start: _normalize(start), end: _normalize(end)),
                                );
                                _scheduleCollapse();
                              }
                              _currentFocused = _normalize(focusedDay);
                            }
                          : null,
                      onPageChanged: (focused) {
                        _currentFocused = _normalize(focused);
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          final normalized = _normalize(day);
                          final hasSession = sessionCount.containsKey(normalized);
                          final dialysis = isDialysisWeekday(day);
                          if (!hasSession && !dialysis) return null;
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Icon(
                                Icons.circle,
                                size: 6,
                                color: hasSession
                                    ? Colors.teal
                                    : Colors.teal.withOpacity(0.35),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        quickChips,
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onPressed(),
    );
  }
}
