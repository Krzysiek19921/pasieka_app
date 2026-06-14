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
      final data = await service.fetchHives();

      setState(() {
        hives = data;
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

              Text(
                "⚖️ Waga: ${hive.weight.toStringAsFixed(2)} kg",
              ),

              Text(
                "📉 8h: ${hive.delta8h.toStringAsFixed(2)} kg",
                style: TextStyle(
                  color: _deltaColor(hive.delta8h),
                ),
              ),

              Text(
                "📉 24h: ${hive.delta24h.toStringAsFixed(2)} kg",
                style: TextStyle(
                  color: _deltaColor(hive.delta24h),
                ),
              ),

              if (hive.tempEntity != null) ...[
                const Divider(),
                Text(
                  "🌡️ Temperatura: ${hive.temp.toStringAsFixed(1)} °C",
                ),
              ],

              if (hive.humidityEntity != null)
                Text(
                  "💧 Wilgotność: ${hive.humidity.toStringAsFixed(1)} %",
                ),

              if (hive.pressureEntity != null)
                Text(
                  "🌬️ Ciśnienie: ${hive.pressure.toStringAsFixed(1)} hPa",
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Błąd:\n$error",
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
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: hives.map(hiveCard).toList(),
        ),
      ),
    );
  }
}