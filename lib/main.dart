import 'package:flutter/material.dart';
import 'ui/hive_dashboard_view.dart';
import 'ui/hive_detail_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pasieka App',

      initialRoute: '/',

      routes: {
        '/': (context) => const HiveDashboard(),

        // 🐝 DODANE: wejście w ul
        '/hive': (context) => const HiveDetailView(),
      },
    );
  }
}