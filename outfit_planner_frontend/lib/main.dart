import 'package:flutter/material.dart';

import 'package:outfit_planner_frontend/screens/product_search_screen.dart';

void main() {
  runApp(const OutfitPlannerApp());
}

class OutfitPlannerApp extends StatelessWidget {
  const OutfitPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outfit Planner',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ProductSearchScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
