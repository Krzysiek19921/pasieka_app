import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hive_model.dart';

class HaService {
  final String haUrl = "https://ulekrzyska.duckdns.org:8123";

  final String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIxNTY3OTQxMjVlM2I0MDI4YmE4ZGJjMGMwZjQwMjgzNiIsImlhdCI6MTc3OTU2MTA4MywiZXhwIjoyMDk0OTIxMDgzfQ.QOhWE99RyOsWTyAlJ_5cmVPzJVXiOycFy9zBE_XBx8c"; // ⚠️ docelowo przenieś do env

   // =========================
  // FETCH STATES
  // =========================
  Future<List<dynamic>> _fetchStates() async {
    final response = await http.get(
      Uri.parse("$haUrl/api/states"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return [];
    }

    return jsonDecode(response.body);
  }

  // =========================
  // SAFE PARSE
  // =========================
  double _get(List<dynamic> data, String id) {
    try {
      final item = data.cast<Map<String, dynamic>>().firstWhere(
            (e) => e["entity_id"] == id,
            orElse: () => {},
          );

      if (item.isEmpty) return 0;

      return double.tryParse(item["state"].toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // =========================
  // HIVES
  // =========================
  Future<List<HiveModel>> fetchHives() async {
    final data = await _fetchStates();

    return [
      // =========================
      // UL1
      // =========================
      HiveModel(
        name: "UL1",
        weightEntity: "sensor.waga_ula_buckfast_1_waga",
        delta8hEntity: "sensor.ul1_8h_delta",
        delta24hEntity: "sensor.ul1_24h_delta",

        weight: _get(data, "sensor.waga_ula_buckfast_1_waga"),
        delta8h: _get(data, "sensor.ul1_8h_delta"),
        delta24h: _get(data, "sensor.ul1_24h_delta"),
      ),

      // =========================
      // UL2
      // =========================
      HiveModel(
        name: "UL2",
        weightEntity: "sensor.waga_dwie_belki_waga",
        delta8hEntity: "sensor.ul2_8h_delta",
        delta24hEntity: "sensor.ul2_24h_delta",

        weight: _get(data, "sensor.waga_dwie_belki_waga"),
        delta8h: _get(data, "sensor.ul2_8h_delta"),
        delta24h: _get(data, "sensor.ul2_24h_delta"),
      ),

      // =========================
      // UL3
      // =========================
      HiveModel(
        name: "UL3",

        weightEntity: "sensor.waga_z_czujnikiem_waga_ula",
        delta8hEntity: "sensor.ul3_8h_delta",
        delta24hEntity: "sensor.ul3_24h_delta",

        tempEntity: "sensor.waga_z_czujnikiem_temperatura_ula",
        humidityEntity: "sensor.waga_z_czujnikiem_wilgotnosc_ula",

        weight: _get(data, "sensor.waga_z_czujnikiem_waga_ula"),
        delta8h: _get(data, "sensor.ul3_8h_delta"),
        delta24h: _get(data, "sensor.ul3_24h_delta"),

        temp: _get(data, "sensor.waga_z_czujnikiem_temperatura_ula"),
        humidity: _get(data, "sensor.waga_z_czujnikiem_wilgotnosc_ula"),
      ),

      // =========================
      // UL4
      // =========================
      HiveModel(
        name: "UL4",

        weightEntity: "sensor.waga_ul_4_waga",
        delta8hEntity: "sensor.ul4_8h_delta",
        delta24hEntity: "sensor.ul4_24h_delta",

        tempEntity: "sensor.waga_ul_4_temperatura_ula_4",
        humidityEntity: "sensor.waga_ul_4_wilgotnosc_ula_4",
        pressureEntity: "sensor.waga_ul_4_cisnienie_ula_4",

        weight: _get(data, "sensor.waga_ul_4_waga"),
        delta8h: _get(data, "sensor.ul4_8h_delta"),
        delta24h: _get(data, "sensor.ul4_24h_delta"),

        temp: _get(data, "sensor.waga_ul_4_temperatura_ula_4"),
        humidity: _get(data, "sensor.waga_ul_4_wilgotnosc_ula_4"),
        pressure: _get(data, "sensor.waga_ul_4_cisnienie_ula_4"),
      ),

      // =========================
      // UL5
      // =========================
      HiveModel(
        name: "UL5",

        weightEntity: "sensor.waga_ul_5_waga_ula",
        delta8hEntity: "sensor.ul5_8h_delta",
        delta24hEntity: "sensor.ul5_24h_delta",

        tempEntity: "sensor.waga_ul_5_temperatura_ula_2",
        humidityEntity: "sensor.waga_ul_5_wilgotnosc_ula_2",
        pressureEntity: "sensor.waga_ul_5_cisnienie_ula_5",

        weight: _get(data, "sensor.waga_ul_5_waga_ula"),
        delta8h: _get(data, "sensor.ul5_8h_delta"),
        delta24h: _get(data, "sensor.ul5_24h_delta"),

        temp: _get(data, "sensor.waga_ul_5_temperatura_ula_2"),
        humidity: _get(data, "sensor.waga_ul_5_wilgotnosc_ula_2"),
        pressure: _get(data, "sensor.waga_ul_5_cisnienie_ula_5"),
      ),

      // =========================
      // UL6
      // =========================
      HiveModel(
        name: "UL6",

        weightEntity: "sensor.waga_ul_6_waga_ula",
        delta8hEntity: "sensor.ul6_8h_delta",
        delta24hEntity: "sensor.ul6_24h_delta",

        tempEntity: "sensor.waga_ul_6_temperatura_ula",
        humidityEntity: "sensor.waga_ul_6_wilgotnosc_ula",
        pressureEntity: "sensor.waga_ul_6_cisnienie_ula_6",

        weight: _get(data, "sensor.waga_ul_6_waga_ula"),
        delta8h: _get(data, "sensor.ul6_8h_delta"),
        delta24h: _get(data, "sensor.ul6_24h_delta"),

        temp: _get(data, "sensor.waga_ul_6_temperatura_ula"),
        humidity: _get(data, "sensor.waga_ul_6_wilgotnosc_ula"),
        pressure: _get(data, "sensor.waga_ul_6_cisnienie_ula_6"),
      ),
    ];
  }
}