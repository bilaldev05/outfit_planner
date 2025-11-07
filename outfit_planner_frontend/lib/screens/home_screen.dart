import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/screens/add_item_screen.dart';
import 'package:outfit_planner_frontend/screens/outfit_builder_screen.dart';
import 'package:outfit_planner_frontend/screens/planner_screen.dart';
import 'package:outfit_planner_frontend/screens/profile_screen.dart';
import 'package:outfit_planner_frontend/screens/wardrobe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _pages = const [
    WardrobeScreen(),
    OutfitBuilderScreen(),
    PlannerScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Planner'),
        backgroundColor: Colors.indigo,
        elevation: 4,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_index],
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              ),
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.checkroom), label: 'Wardrobe'),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Outfits'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
