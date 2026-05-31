import 'package:flutter/material.dart';
import '../models/hive_model.dart';
import '../services/ha_service.dart';

class HiveDashboard extends StatefulWidget {
  const HiveDashboard({super.key});

  @override
  State<HiveDashboard> createState() => _HiveDashboardState();
}

class _HiveDashboardState extends State<HiveDashboard> {
  final HaService service = HaService();

  late Future<List<HiveModel>> future;
  late Future<double> tempFuture;
  late Future<double> humidityFuture;

  @override
  void initState() {
    super.initState();
    future = service.fetchHives();
    tempFuture = service.fetchHiveTemp();
    humidityFuture = service.fetchHiveHumidity();
  }

  void _reload() {
    setState(() {
      future = service.fetchHives();
      tempFuture = service.fetchHiveTemp();
      humidityFuture = service.fetchHiveHumidity();
    });
  }

  Color _deltaColor(double v) {
    if (v < 0) return Colors.red;
    if (v > 0) return Colors.green;
    return Colors.grey;
  }

  Widget sensors(double temp, double hum) {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("🌡️ Temperatura"),
                  const SizedBox(height: 5),
                  Text("${temp.toStringAsFixed(1)} °C"),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("💧 Wilgotność"),
                  const SizedBox(height: 5),
                  Text("${hum.toStringAsFixed(1)} %"),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget hiveCard(HiveModel hive) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/hive',
          arguments: hive.name,
        );
      },
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hive.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text("⚖️ Waga: ${hive.weight} kg"),

              const SizedBox(height: 6),

              Text(
                "📉 8h: ${hive.delta8h} kg",
                style: TextStyle(color: _deltaColor(hive.delta8h)),
              ),

              Text(
                "📉 24h: ${hive.delta24h} kg",
                style: TextStyle(color: _deltaColor(hive.delta24h)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐝 Pasieka"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          )
        ],
      ),

      body: Column(
        children: [
          FutureBuilder<double>(
            future: tempFuture,
            builder: (context, t) {
              final temp = t.data ?? 0;

              return FutureBuilder<double>(
                future: humidityFuture,
                builder: (context, h) {
                  final hum = h.data ?? 0;
                  return sensors(temp, hum);
                },
              );
            },
          ),

          Expanded(
            child: FutureBuilder<List<HiveModel>>(
              future: future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.map(hiveCard).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}