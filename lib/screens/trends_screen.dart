import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../services/unit_service.dart';
import '../state/session_store.dart';
import '../utils/weight_utils.dart';
import 'widgets/calendar_tray.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final _trayKey = GlobalKey<CalendarTrayState>();
  late DateTime _focusedDate;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _focusedDate = _normalize(DateTime.now());
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  List<Session> _filteredSessions(List<Session> sessions) {
    if (_range == null) return sessions;
    final start = _normalize(_range!.start);
    final end = _normalize(_range!.end);
    return sessions
        .where((s) {
          final day = _normalize(s.date);
          return !day.isBefore(start) && !day.isAfter(end);
        })
        .toList();
  }

  double? _avgPreWeightKg(List<Session> sessions) {
    final values = sessions.map((s) => s.preWeight).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? _avgPreBP(List<Session> sessions) {
    final values = sessions.map((s) => s.preBP).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _rangeLabel() {
    if (_range == null) {
      return 'All time';
    }
    final start = _range!.start;
    final end = _range!.end;
    if (start.year == end.year) {
      if (start.month == end.month) {
        final month = DateFormat('MMM').format(start);
        final startDay = DateFormat('d').format(start);
        final endDay = DateFormat('d, y').format(end);
        return '$month $startDay–$endDay';
      }
      final startText = DateFormat('MMM d').format(start);
      final endText = DateFormat('MMM d, y').format(end);
      return '$startText – $endText';
    }
    final startText = DateFormat('MMM d, y').format(start);
    final endText = DateFormat('MMM d, y').format(end);
    return '$startText – $endText';
  }

  void _applyRange(DateTimeRange range) {
    setState(() {
      _range = DateTimeRange(
        start: _normalize(range.start),
        end: _normalize(range.end),
      );
      _focusedDate = _normalize(range.end);
    });
  }

  void _clearRange() {
    setState(() {
      _range = null;
      _focusedDate = _normalize(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final filteredSessions = _filteredSessions(store.sessions);
    final selectionLabel = _rangeLabel();
    final avgPreWeightKg = _avgPreWeightKg(filteredSessions);
    final avgBp = _avgPreBP(filteredSessions);

    List<FlSpot> _spotsPreWeight(List<Session> data, WeightUnit unit) {
      final filtered = data.where((s) => s.preWeight != null).toList();
      return List.generate(filtered.length, (i) {
        final weightKg = filtered[i].preWeight!;
        final display = toDisplayFromKg(weightKg, unit);
        return FlSpot((filtered.length - i).toDouble(), display);
      });
    }

    List<FlSpot> _spotsBP(List<Session> data) {
      final filtered = data.where((s) => s.preBP != null).toList();
      return List.generate(filtered.length, (i) {
        return FlSpot((filtered.length - i).toDouble(), filtered[i].preBP!);
      });
    }

    Widget _chart(String title, List<FlSpot> spots, {String? axisLabel}) {
      if (spots.isEmpty) {
        return Container(
          height: 220,
          alignment: Alignment.center,
          child: const Text('No data yet'),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget:
                        axisLabel != null ? Text(axisLabel) : const SizedBox(),
                    axisNameSize: axisLabel != null ? 24 : 0,
                    sideTitles: const SideTitles(showTitles: false),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
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
            focusedDate: _focusedDate,
            onDateSelected: (date) {
              setState(() {
                _focusedDate = _normalize(date);
              });
            },
            rangeMode: true,
            rangeStart: _range?.start,
            rangeEnd: _range?.end,
            onRangeSelected: (range) {
              if (range == null) {
                _clearRange();
              } else {
                _applyRange(range);
              }
            },
            titleWhenCollapsed: selectionLabel,
            prefsKey: 'ui.tray.trends',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<WeightUnit>(
                valueListenable: UnitService.instance.unit,
                builder: (_, unit, __) {
                  final preWeightSpots = _spotsPreWeight(filteredSessions, unit);
                  final avgPreWeightText = avgPreWeightKg == null
                      ? '—'
                      : formatWeight(avgPreWeightKg, unit, decimals: 1);
                  final bpText = avgBp == null
                      ? '—'
                      : avgBp.toStringAsFixed(0);
                  return ListView(
                    children: [
                      _chart(
                        'Pre-Weight Trend',
                        preWeightSpots,
                        axisLabel: unit == WeightUnit.kg ? 'kg' : 'lbs',
                      ),
                      const SizedBox(height: 16),
                      Text('Average Pre-Weight: $avgPreWeightText'),
                      const SizedBox(height: 24),
                      _chart('BP Trend (systolic)', _spotsBP(filteredSessions),
                          axisLabel: 'mmHg'),
                      const SizedBox(height: 8),
                      Text('Average BP: $bpText'),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
