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

  bool loading = true;
  String? error;

  List<HiveModel> hives = [];

  double temp = 0;
  double humidity = 0;

  double ul4Temp = 0;
  double ul4Humidity = 0;
  double ul4Pressure = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        service.fetchHives(),
        service.fetchGlobalTemp(),
        service.fetchGlobalHumidity(),
        service.fetchHiveTemp(),
        service.fetchHiveHumidity(),
        service.fetchHivePressure(),
      ]);

      setState(() {
        hives = results[0] as List<HiveModel>;

        temp = results[1] as double;
        humidity = results[2] as double;

        ul4Temp = results[3] as double;
        ul4Humidity = results[4] as double;
        ul4Pressure = results[5] as double;

        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Color _deltaColor(double v) {
    if (v < 0) return Colors.red;
    if (v > 0) return Colors.green;
    return Colors.grey;
  }

  Widget sensors() {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("🌡️ Temperatura (ULA)"),
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
                  const Text("💧 Wilgotność (ULA)"),
                  const SizedBox(height: 5),
                  Text("${humidity.toStringAsFixed(1)} %"),
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

  Widget ul4Card() {
    final ul4 = hives.where((h) => h.name == "UL4");

    if (ul4.isEmpty) {
      return const SizedBox(); // 🔥 brak crasha
    }

    final hive = ul4.first;

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "UL4",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("⚖️ Waga: ${hive.weight} kg"),
            Text(
              "📉 8h: ${hive.delta8h} kg",
              style: TextStyle(color: _deltaColor(hive.delta8h)),
            ),
            Text(
              "📉 24h: ${hive.delta24h} kg",
              style: TextStyle(color: _deltaColor(hive.delta24h)),
            ),
            const Divider(),
            Text("🌡️ Temp: ${ul4Temp.toStringAsFixed(1)} °C"),
            Text("💧 Wilg: ${ul4Humidity.toStringAsFixed(1)} %"),
            Text("🌬️ Cisn: ${ul4Pressure.toStringAsFixed(1)} hPa"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Błąd ❌\n$error",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🐝 Pasieka"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          )
        ],
      ),
      body: Column(
        children: [
          sensors(),
          Expanded(
            child: ListView(
              children: [
                ...hives.map(hiveCard),
                ul4Card(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}