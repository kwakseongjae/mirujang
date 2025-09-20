import 'package:flutter/material.dart';

void main() {
  runApp(const MirugangApp());
}

class MirugangApp extends StatelessWidget {
  const MirugangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '미루장',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('미루장'),
      ),
      body: const Center(child: Text('홈화면', style: TextStyle(fontSize: 24))),
    );
  }
}
