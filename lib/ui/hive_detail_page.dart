import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../models/hive_model.dart';
import '../services/ha_service.dart';

class HiveDetailPage extends StatefulWidget {
  const HiveDetailPage({super.key});

  @override
  State<HiveDetailPage> createState() => _HiveDetailPageState();
}

class _HiveDetailPageState extends State<HiveDetailPage> {
  final HaService service = HaService();

  late HiveModel hive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    hive = ModalRoute.of(context)!.settings.arguments as HiveModel;
  }

  Future<List<FlSpot>> fetchHistory(String entityId) async {
    final response = await http.get(
      Uri.parse(
        "${service.haUrl}/api/history/period?filter_entity_id=$entityId",
      ),
      headers: {
        "Authorization": "Bearer ${service.token}",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) return [];

    final List data = jsonDecode(response.body);
    if (data.isEmpty) return [];

    final List points = data[0];

    return List.generate(points.length, (i) {
      final state = double.tryParse(points[i]["state"].toString()) ?? 0;
      return FlSpot(i.toDouble(), state);
    });
  }

  Widget chart(String entityId, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<FlSpot>>(
            future: fetchHistory(entityId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final spots = snapshot.data!;

              return LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🐝 ${hive.name}"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "⚖️ Waga: ${hive.weight} kg",
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      Text("📉 8h: ${hive.delta8h} kg"),
                      Text("📉 24h: ${hive.delta24h} kg"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              chart(hive.weightEntity, "📊 Waga (live)"),

              const SizedBox(height: 20),

              chart(hive.weightEntity, "📈 Trend 24h / 7d"),
            ],
          ),
        ),
      ),
    );
  }
}