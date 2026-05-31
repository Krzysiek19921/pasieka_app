import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hive_model.dart';

class HaService {
  final String haUrl = "https://ulekrzyska.duckdns.org:8123";

  // ⚠️ zostawiam Twój token (nie zmieniam)
  final String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIxNTY3OTQxMjVlM2I0MDI4YmE4ZGJjMGMwZjQwMjgzNiIsImlhdCI6MTc3OTU2MTA4MywiZXhwIjoyMDk0OTIxMDgzfQ.QOhWE99RyOsWTyAlJ_5cmVPzJVXiOycFy9zBE_XBx8c";

  // --------------------------
  // 🔧 SAFE GET
  // --------------------------
  double _get(List data, String id) {
    final item = data.firstWhere(
      (e) => e["entity_id"] == id,
      orElse: () => null,
    );

    if (item == null) return 0;

    return double.tryParse(item["state"].toString()) ?? 0;
  }

  // --------------------------
  // 🐝 ULE (waga + delty)
  // --------------------------
  Future<List<HiveModel>> fetchHives() async {
    final response = await http.get(
      Uri.parse("$haUrl/api/states"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("HA error: ${response.statusCode}");
    }

    final List data = jsonDecode(response.body);

    return [
      HiveModel(
        name: "UL1",
        weightEntity: "sensor.waga_ula_buckfast_1_waga",
        delta8hEntity: "sensor.ul1_8h_delta",
        delta24hEntity: "sensor.ul1_24h_delta",
        weight: _get(data, "sensor.waga_ula_buckfast_1_waga"),
        delta8h: _get(data, "sensor.ul1_8h_delta"),
        delta24h: _get(data, "sensor.ul1_24h_delta"),
      ),
      HiveModel(
        name: "UL2",
        weightEntity: "sensor.waga_dwie_belki_waga",
        delta8hEntity: "sensor.ul2_8h_delta",
        delta24hEntity: "sensor.ul2_24h_delta",
        weight: _get(data, "sensor.waga_dwie_belki_waga"),
        delta8h: _get(data, "sensor.ul2_8h_delta"),
        delta24h: _get(data, "sensor.ul2_24h_delta"),
      ),
      HiveModel(
        name: "UL3",
        weightEntity: "sensor.waga_z_czujnikiem_waga_ula",
        delta8hEntity: "sensor.ul3_8h_delta",
        delta24hEntity: "sensor.ul3_24h_delta",
        weight: _get(data, "sensor.waga_z_czujnikiem_waga_ula"),
        delta8h: _get(data, "sensor.ul3_8h_delta"),
        delta24h: _get(data, "sensor.ul3_24h_delta"),
      ),
    ];
  }

  // --------------------------
  // 🌡️ TEMPERATURA
  // --------------------------
  Future<double> fetchHiveTemp() async {
    final response = await http.get(
      Uri.parse(
        "$haUrl/api/states/sensor.waga_z_czujnikiem_temperatura_ula",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) return 0;

    final data = jsonDecode(response.body);
    return double.tryParse(data["state"].toString()) ?? 0;
  }

  // --------------------------
  // 💧 WILGOTNOŚĆ
  // --------------------------
  Future<double> fetchHiveHumidity() async {
    final response = await http.get(
      Uri.parse(
        "$haUrl/api/states/sensor.waga_z_czujnikiem_wilgotnosc_ula",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) return 0;

    final data = jsonDecode(response.body);
    return double.tryParse(data["state"].toString()) ?? 0;
  }
}