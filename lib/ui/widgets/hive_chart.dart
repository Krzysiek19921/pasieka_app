import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HiveChart extends StatelessWidget {
  final List<double> data;
  final String title;

  const HiveChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            )
          ],
        ),
      ),
    );
  }
}