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

  // =========================
  // 🔥 MAIN DATA FETCH (HA STYLE)
  // =========================
  Future<List<FlSpot>> fetchData(String entityId) async {
    final now = DateTime.now();
    final is24h = range == "24h";

    final start = is24h
        ? now.subtract(const Duration(hours: 24))
        : now.subtract(const Duration(days: 7));

    final uri = is24h
        ? Uri.parse(
            "${service.haUrl}/api/history/period/${start.toIso8601String()}"
            "?filter_entity_id=$entityId",
          )
        : Uri.parse(
            "${service.haUrl}/api/statistics/during_period"
            "?start_time=${start.toIso8601String()}"
            "&end_time=${now.toIso8601String()}"
            "&statistic_ids=$entityId",
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

    // =========================
    // 🔵 HISTORY (24h)
    // =========================
    if (is24h) {
      if (data.isEmpty || data[0].isEmpty) return [];

      final points = data[0] as List;

      final parsed = points.map((p) {
        final time = DateTime.tryParse(p["last_changed"] ?? "");
        final value = double.tryParse(p["state"].toString());

        if (time == null || value == null) return null;

        return FlSpot(
          time.millisecondsSinceEpoch.toDouble(),
          value,
        );
      }).whereType<FlSpot>().toList();

      return _normalize(parsed);
    }

    // =========================
    // 🟣 STATISTICS (7d)
    // =========================
    if (data.isEmpty || data[0]["data"] == null) return [];

    final points = data[0]["data"] as List;

    final parsed = points.map((p) {
      final time = DateTime.tryParse(p["start"]);
      final value = (p["mean"] ?? 0).toDouble();

      if (time == null) return null;

      return FlSpot(
        time.millisecondsSinceEpoch.toDouble(),
        value,
      );
    }).whereType<FlSpot>().toList();

    return _normalize(parsed);
  }

  // =========================
  // 🔧 HA NORMALIZATION (IMPORTANT)
  // =========================
  List<FlSpot> _normalize(List<FlSpot> data) {
    if (data.isEmpty) return [];

    data.sort((a, b) => a.x.compareTo(b.x));

    final base = data.first.x;

    return data.map((p) {
      return FlSpot(
        (p.x - base) / 60000, // minutes like HA UI
        p.y,
      );
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
        future: fetchData(entityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final spots = snapshot.data ?? [];

          if (spots.isEmpty) {
            return const Center(child: Text("Brak danych"));
          }

          final start = DateTime.now().subtract(
            Duration(minutes: spots.last.x.toInt()),
          );

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
                      final dt = start.add(
                        Duration(minutes: value.toInt()),
                      );

                      if (range == "24h") {
                        return Text(
                          "${dt.hour}:00",
                          style: const TextStyle(fontSize: 10),
                        );
                      }

                      const days = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"];

                      return Text(
                        days[dt.weekday - 1],
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text("${value.toStringAsFixed(1)} kg");
                    },
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
      appBar: AppBar(
        title: Text("🐝 $hiveName"),
      ),
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