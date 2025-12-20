import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:outfit_planner_frontend/screens/signup_screen.dart';
import 'package:provider/provider.dart';


import 'widgets/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBuSxOrchXf80Qpyukjo0c8ESMearV3YeM",
      authDomain: "outfit-planner-b849e.firebaseapp.com",
      projectId: "outfit-planner-b849e",
      storageBucket: "outfit-planner-b849e.firebasestorage.app",
      messagingSenderId: "619912118144",
      appId: "1:619912118144:web:4398f5675fdc57d4e28b65",
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignupScreen(),
    );
  }
}
