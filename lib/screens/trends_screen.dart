import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/unit_service.dart';
import '../state/session_store.dart';
import '../utils/weight_utils.dart';
import 'widgets/calendar_header.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final sessions = store.sessions;

    List<FlSpot> _spotsPreWeight(WeightUnit unit) {
      final data = sessions.where((s) => s.preWeight != null).toList();
      return List.generate(
        data.length,
        (i) {
          final weightKg = data[i].preWeight!;
          final display = toDisplayFromKg(weightKg, unit);
          return FlSpot((data.length - i).toDouble(), display);
        },
      );
    }

    List<FlSpot> _spotsBP() {
      final data = sessions.where((s) => s.preBP != null).toList();
      return List.generate(
        data.length,
        (i) => FlSpot((data.length - i).toDouble(), data[i].preBP!),
      );
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
      appBar: AppBar(title: const Text('Trends')),
      body: Column(
        children: [
          const CalendarHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<WeightUnit>(
                valueListenable: UnitService.instance.unit,
                builder: (_, unit, __) {
                  final preWeightSpots = _spotsPreWeight(unit);
                  final avgPreWeight =
                      formatWeight(store.avgPreWeight, unit, decimals: 1);
                  return ListView(
                    children: [
                      _chart('Pre-Weight Trend', preWeightSpots,
                          axisLabel: unit == WeightUnit.kg ? 'kg' : 'lbs'),
                      const SizedBox(height: 16),
                      Text('Average Pre-Weight: $avgPreWeight'),
                      const SizedBox(height: 24),
                      _chart('BP Trend (systolic)', _spotsBP(),
                          axisLabel: 'mmHg'),
                      const SizedBox(height: 8),
                      Text('Average BP: ${store.avgBP.toStringAsFixed(0)}'),
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

