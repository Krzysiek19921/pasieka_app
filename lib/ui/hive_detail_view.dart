import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

import '../services/ha_service.dart';

class HiveDetailView extends StatefulWidget {
  const HiveDetailView({super.key});

  @override
  State<HiveDetailView> createState() => _HiveDetailViewState();
}

class _HiveDetailViewState extends State<HiveDetailView> {
  final HaService service = HaService();

  late String hiveName;
  String range = "24h";

  final Map<String, String> weightMap = {
    "UL1": "sensor.waga_ula_buckfast_1_waga",
    "UL2": "sensor.waga_dwie_belki_waga",
    "UL3": "sensor.waga_z_czujnikiem_waga_ula",
    "UL4": "sensor.waga_ul_4_waga",
    "UL5": "sensor.waga_ul_5_waga_ula",
    "UL6": "sensor.waga_ul_6_waga_ula",
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hiveName = ModalRoute.of(context)!.settings.arguments as String;
  }

  Future<List<FlSpot>> fetchHistory(String entityId) async {
    final uri = Uri.parse(
      "${service.haUrl}/api/history/period?filter_entity_id=$entityId",
    );

    final res = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer ${service.token}",
      },
    );

    if (res.statusCode != 200) {
      debugPrint("HA ERROR: ${res.body}");
      return [];
    }

    final List data = jsonDecode(res.body);
    if (data.isEmpty || data[0].isEmpty) return [];

    final List points = data[0];

    final now = DateTime.now();

    final cutoff = range == "24h"
        ? now.subtract(const Duration(hours: 24))
        : now.subtract(const Duration(days: 7));

    final parsed = points
        .map((p) {
          final time = DateTime.tryParse(p["last_changed"] ?? "");
          final value = double.tryParse(p["state"].toString());

          if (time == null || value == null) return null;

          return {
            "time": time,
            "value": value,
          };
        })
        .whereType<Map>()
        .where((p) => (p["time"] as DateTime).isAfter(cutoff))
        .toList();

    if (parsed.isEmpty) return [];

    parsed.sort((a, b) =>
        (a["time"] as DateTime).compareTo(b["time"] as DateTime));

    final base = parsed.first["time"] as DateTime;

    return parsed.map<FlSpot>((p) {
      final time = p["time"] as DateTime;
      final value = p["value"] as double;

      final x = time.difference(base).inMinutes.toDouble();

      return FlSpot(x, value);
    }).toList();
  }

  double _minY(List<FlSpot> spots) {
    final min = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    return min - 0.5;
  }

  double _maxY(List<FlSpot> spots) {
    final max = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return max + 0.5;
  }

  Widget chart(String entityId) {
    return SizedBox(
      height: 280,
      child: FutureBuilder<List<FlSpot>>(
        future: fetchHistory(entityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final spots = snapshot.data ?? [];

          if (spots.isEmpty) {
            return const Center(child: Text("Brak danych"));
          }

          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              minX: 0,
              maxX: spots.last.x,
              minY: _minY(spots),
              maxY: _maxY(spots),

              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: range == "24h" ? 180 : 1440,
                    getTitlesWidget: (value, meta) {
                      final dt = DateTime.now().subtract(
                        Duration(minutes: (spots.last.x - value).toInt()),
                      );

                      if (range == "24h") {
                        return Text(
                          "${dt.hour}:00",
                          style: const TextStyle(fontSize: 10),
                        );
                      } else {
                        const days = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"];
                        return Text(
                          days[dt.weekday - 1],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                    },
                  ),
                ),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        Text("${value.toStringAsFixed(1)} kg"),
                  ),
                ),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entity = weightMap[hiveName];

    return Scaffold(
      appBar: AppBar(title: Text("🐝 $hiveName")),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => range = "24h"),
                child: const Text("24h"),
              ),
              TextButton(
                onPressed: () => setState(() => range = "7d"),
                child: const Text("7d"),
              ),
            ],
          ),

          Expanded(
            child: entity == null
                ? const Center(child: Text("Brak konfiguracji ula"))
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: chart(entity),
                  ),
          ),
        ],
      ),
    );
  }
}