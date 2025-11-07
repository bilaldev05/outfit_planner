import 'package:flutter/material.dart';

import 'package:outfit_planner_frontend/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OutfitPlannerApp());
}

class OutfitPlannerApp extends StatelessWidget {
  const OutfitPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outfit Planner',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
