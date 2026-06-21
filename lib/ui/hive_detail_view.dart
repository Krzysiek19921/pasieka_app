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
  // FETCH DATA (FIXED HA API)
  // =========================
  Future<_ChartData> fetchData(String entityId) async {
    final now = DateTime.now().toUtc();

    final start = range == "24h"
        ? now.subtract(const Duration(hours: 24))
        : now.subtract(const Duration(days: 7));

    final end = now;

    final uri = Uri.parse(
      "${service.haUrl}/api/history/period/${start.toIso8601String()}"
      "?end_time=${end.toIso8601String()}"
      "&filter_entity_id=$entityId",
    );

    print("========== HA REQUEST ==========");
    print(uri.toString());

    final res = await http.get(
      uri,
      headers: {"Authorization": "Bearer ${service.token}"},
    );

    print("STATUS: ${res.statusCode}");

    if (res.statusCode != 200) {
      return _ChartData([], DateTime.now());
    }

    final data = jsonDecode(res.body);

    if (data is! List || data.isEmpty) {
      return _ChartData([], DateTime.now());
    }

    // =========================
    // SAFE PARSING (NO OVERFLATTEN BUG)
    // =========================
    final List<_Point> points = [];

    for (final entityBlock in data) {
      if (entityBlock is! List) continue;

      for (final item in entityBlock) {
        if (item is! Map) continue;

        final state = item["state"];
        final timeStr = item["last_changed"];

        final time = DateTime.tryParse(timeStr ?? "")?.toLocal();
        final value = double.tryParse(state.toString());

        if (time == null || value == null) continue;

        points.add(_Point(time, value));
      }
    }

    if (points.isEmpty) {
      return _ChartData([], DateTime.now());
    }

    points.sort((a, b) => a.time.compareTo(b.time));

    final base = points.first.time;

    final spots = points.map((p) {
      return FlSpot(
        p.time.millisecondsSinceEpoch.toDouble(),
        p.value,
      );
    }).toList();

    print("POINTS: ${points.length}");
    print("SPOTS: ${spots.length}");

    return _ChartData(spots, base);
  }

  // =========================
  // CHART
  // =========================
  Widget chart(String entityId) {
    return FutureBuilder<_ChartData>(
      future: fetchData(entityId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final spots = snapshot.data!.spots;

        if (spots.isEmpty) {
          return const Center(child: Text("Brak danych"));
        }

        final sorted = [...spots]..sort((a, b) => a.x.compareTo(b.x));

        return LineChart(
          LineChartData(
            minX: sorted.first.x,
            maxX: sorted.last.x,
            gridData: const FlGridData(show: true),

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
                  reservedSize: 28,
                  interval: (sorted.last.x - sorted.first.x) / 6,
                  getTitlesWidget: (value, meta) {
                    final dt =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());

                    if (range == "24h") {
                      return Text("${dt.hour}:00",
                          style: const TextStyle(fontSize: 10));
                    }

                    const days = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"];

                    return Text(
                      days[dt.weekday - 1],
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                spots: sorted,
                isCurved: true,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        );
      },
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
                ? const Center(child: Text("Brak konfiguracji"))
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

// =========================
// MODELS
// =========================
class _ChartData {
  final List<FlSpot> spots;
  final DateTime baseTime;

  _ChartData(this.spots, this.baseTime);
}

class _Point {
  final DateTime time;
  final double value;

  _Point(this.time, this.value);
}