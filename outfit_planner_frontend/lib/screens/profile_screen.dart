import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/screens/home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 72),
            const SizedBox(height: 8),
            const Text('User Profile'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _goHome(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
