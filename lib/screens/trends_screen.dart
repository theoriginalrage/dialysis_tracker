import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../state/session_store.dart';
import 'widgets/calendar_header.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SessionStore>();
    final sessions = store.sessions;

    List<FlSpot> _spotsPreWeight() => List.generate(
          sessions.length,
          (i) => FlSpot((sessions.length - i).toDouble(), sessions[i].preWeight),
        );

    List<FlSpot> _spotsBP() => List.generate(
          sessions.length,
          (i) => FlSpot((sessions.length - i).toDouble(), sessions[i].preBP),
        );

    Widget _chart(String title, List<FlSpot> spots) {
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
                titlesData: const FlTitlesData(show: false),
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
              child: ListView(
                children: [
                  _chart('Pre-Weight Trend', _spotsPreWeight()),
                  const SizedBox(height: 16),
                  Text(
                      'Average Pre-Weight: ${store.avgPreWeight.toStringAsFixed(1)} kg'),
                  const SizedBox(height: 24),
                  _chart('BP Trend (systolic)', _spotsBP()),
                  const SizedBox(height: 8),
                  Text('Average BP: ${store.avgBP.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

